import 'dart:math' as math;

import '../../../core/db/tables.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';

/// Skor satu aspek (P3d). Urutan nilai: 4 = tertinggi.
enum RaporGrade {
  juara(4, 'Juara', '🏆', '●●●●'),
  aman(3, 'Aman', '👌', '●●●○'),
  nanggung(2, 'Nanggung', '😅', '●●○○'),
  waduh(1, 'Waduh', '🚨', '●○○○');

  const RaporGrade(this.points, this.label, this.emoji, this.dots);
  final int points;
  final String label;
  final String emoji;
  final String dots;

  /// Rata-rata poin → label (≥3,5 Juara, ≥2,5 Aman, ≥1,5 Nanggung).
  static RaporGrade fromAverage(double avg) => avg >= 3.5
      ? juara
      : avg >= 2.5
          ? aman
          : avg >= 1.5
              ? nanggung
              : waduh;
}

/// Label "belum dinilai".
const String raporUngradedLabel = 'Belum dinilai';
const String raporUngradedDots = '○○○○';

enum RaporAspect {
  menabung('Menabung', '(pemasukan − pengeluaran) ÷ pemasukan',
      'Aturan 50/30/20 (20% untuk tabungan/investasi) dan anjuran umum menyisihkan 10–20% pemasukan.',
      ['≥ 20%', '10–19%', '0–9%', 'minus']),
  cicilan('Beban cicilan', '(cicilan + paylater + utang jatuh tempo) ÷ pemasukan',
      'Bank umumnya membatasi rasio cicilan terhadap pendapatan (DSR) sekitar 30–40%; perencana keuangan menyarankan maksimal 30%.',
      ['≤ 20%', '21–30%', '31–40%', '> 40%']),
  tagihan('Tagihan tepat waktu', 'tagihan & cicilan dibayar paling lambat di hari jatuh tempo',
      'Mengikuti kolektibilitas di SLIK OJK: telat bayar menurunkan status dari Lancar ke Dalam Perhatian Khusus (1–90 hari) dan seterusnya.',
      ['semua tepat', '1 telat ≤ 7 hr', 'beberapa telat', '> 30 hr belum']),
  budget('Disiplin budget', 'kategori ber-budget yang tidak melewati batas', 'Target yang kamu tetapkan sendiri di Budget.',
      ['semua aman', '1 jebol ≤ 10%', 'beberapa jebol', 'total > 120%']),
  ketahanan('Ketahanan', 'saldo semua dompet ÷ rata-rata pengeluaran 3 bulan',
      'Anjuran umum dana darurat 3–6× pengeluaran bulanan untuk lajang (6–12× bila berkeluarga).',
      ['≥ 6 bln', '3–6 bln', '1–3 bln', '< 1 bln']),
  mencatat('Rajin mencatat', 'hari yang tercatat ÷ jumlah hari dalam bulan',
      'Kebiasaan, bukan standar keuangan. Juga menentukan seberapa akurat nilai lain.', ['≥ 80%', '50–79%', '25–49%', '< 25%']);

  const RaporAspect(this.label, this.formula, this.basis, this.bands);
  final String label;

  /// Nama pendek untuk kartu bagikan.
  String get short => switch (this) {
        RaporAspect.cicilan => 'Cicilan',
        RaporAspect.tagihan => 'Tagihan',
        RaporAspect.budget => 'Budget',
        RaporAspect.mencatat => 'Mencatat',
        _ => label,
      };
  final String formula;
  final String basis;

  /// Batas untuk Juara, Aman, Nanggung, Waduh.
  final List<String> bands;
}

/// Hasil satu aspek. [grade] null = belum dinilai.
class AspectScore {
  const AspectScore(this.aspect, this.grade, {required this.reason, required this.mine, this.tip, this.value});

  final RaporAspect aspect;
  final RaporGrade? grade;
  final String reason;

  /// Hitungan dengan angka pengguna, untuk "Dari mana nilai ini?".
  final String mine;
  final String? tip;

  /// Angka mentah (persen/bulan) untuk tren & catatan.
  final double? value;
}

// ---------------------------------------------------------------- masukan

typedef RaporTx = ({
  TxKind kind,
  int amount,
  int? categoryId,
  DateTime at,
  int? billId,
  DateTime? billDue,
  bool auto,
  String note,
});

typedef RaporBill = ({int id, String name, int amount, bool installment, DateTime nextDue, bool active});

typedef RaporBudget = ({int? categoryId, int limit});

typedef RaporGoalMove = ({String name, int amount, DateTime at, int percentNow});

/// Semua data yang dibutuhkan untuk menyusun rapor bulan mana pun.
class RaporInput {
  const RaporInput({
    required this.txs,
    required this.categoryNames,
    required this.bills,
    required this.budgets,
    required this.balanceNow,
    required this.now,
    this.utangDue = const [],
    this.recurringMonthly = const [],
    this.goalMoves = const [],
    this.piutangLeft = 0,
    this.piutangPeople = 0,
  });

  final List<RaporTx> txs;
  final Map<int, String> categoryNames;
  final List<RaporBill> bills;

  /// Budget yang berlaku per bulan (kunci = tanggal 1).
  final Map<DateTime, List<RaporBudget>> budgets;

  /// Total saldo semua dompet sekarang.
  final int balanceNow;
  final DateTime now;

  /// Utangku yang punya jatuh tempo: (nominal, jatuh tempo).
  final List<({int amount, DateTime due})> utangDue;

  /// Pengeluaran berulang aktif, disetarakan per bulan.
  final List<int> recurringMonthly;
  final List<RaporGoalMove> goalMoves;
  final int piutangLeft;
  final int piutangPeople;

  DateTime? get firstDay {
    DateTime? f;
    for (final t in txs) {
      final DateTime d = DateTime(t.at.year, t.at.month, t.at.day);
      if (f == null || d.isBefore(f)) f = d;
    }
    return f;
  }
}

// ---------------------------------------------------------------- hasil

typedef RaporCategory = ({String name, int amount, int? deltaPct, int? budgetPct});
typedef RaporHighlight = ({String icon, String label, String value});

/// Tujuan saran (dipetakan ke layar oleh UI).
enum RaporAction { aturBudget, tagihan, target, catat }

typedef RaporTip = ({String text, String action, RaporAction target});

class Rapor {
  const Rapor({
    required this.month,
    required this.scores,
    required this.overall,
    required this.average,
    required this.income,
    required this.expense,
    required this.prevIncome,
    required this.prevExpense,
    required this.categories,
    required this.highlights,
    required this.tips,
    required this.note,
    required this.lowData,
    required this.daysLogged,
    required this.daysCounted,
    this.previous,
  });

  final DateTime month;
  final List<AspectScore> scores;
  final RaporGrade? overall;
  final double average;
  final int income;
  final int expense;
  final int prevIncome;
  final int prevExpense;
  final List<RaporCategory> categories;
  final List<RaporHighlight> highlights;
  final List<RaporTip> tips;

  /// "Kata HitungIn".
  final String note;

  /// Rajin mencatat < 50%: nilai lain mungkin kurang akurat.
  final bool lowData;
  final int daysLogged;
  final int daysCounted;
  final Rapor? previous;

  int get net => income - expense;
  int get graded => scores.where((s) => s.grade != null).length;

  /// Tren aspek dibanding bulan lalu: 1 naik, -1 turun, 0 tetap, null tak bisa dibandingkan.
  int? trendOf(RaporAspect a) {
    final RaporGrade? now = scores.firstWhere((s) => s.aspect == a).grade;
    final RaporGrade? before = previous?.scores.firstWhere((s) => s.aspect == a).grade;
    if (now == null || before == null) return null;
    return now.points.compareTo(before.points);
  }

  /// Judul besar rapor.
  String get headline {
    final RaporGrade? before = previous?.overall;
    if (overall == null) return 'Belum cukup data untuk dinilai';
    if (lowData) return 'Awal yang baik — lengkapi catatanmu';
    if (before == null) return 'Rapor pertamamu!';
    if (overall!.points > before.points) return 'Level up! ${before.label} → ${overall!.label}';
    if (overall!.points < before.points) return 'Turun ke ${overall!.label} — masih bisa dikejar';
    return 'Stabil di ${overall!.label}';
  }
}

// ---------------------------------------------------------------- hitungan

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
int _daysIn(DateTime m) => DateTime(m.year, m.month + 1, 0).day;
String _pct(double v) => '${(v * 100).round()}%';
String _num1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

int _signed(RaporTx t) => switch (t.kind) {
      TxKind.pemasukan || TxKind.utangMasuk => t.amount,
      TxKind.pengeluaran || TxKind.utangKeluar => -t.amount,
      TxKind.transfer => 0,
    };

/// Bulan rapor terakhir yang sudah selesai (bulan lalu dari [now]).
DateTime lastCompletedMonth(DateTime now) => DateTime(now.year, now.month - 1);

/// Bulan-bulan yang punya rapor, terbaru dulu (maks [limit]).
List<DateTime> raporMonths(RaporInput input, {int limit = 12}) {
  final DateTime? first = input.firstDay;
  if (first == null) return const [];
  final DateTime last = lastCompletedMonth(input.now);
  final List<DateTime> out = [];
  for (DateTime m = last; !m.isBefore(DateTime(first.year, first.month)) && out.length < limit; m = DateTime(m.year, m.month - 1)) {
    out.add(m);
  }
  return out;
}

Rapor computeRapor(RaporInput input, DateTime month, {bool withPrevious = true}) {
  final DateTime from = DateTime(month.year, month.month);
  final DateTime to = DateTime(month.year, month.month + 1);
  bool inMonth(DateTime d) => !d.isBefore(from) && d.isBefore(to);
  final List<RaporTx> mTx = [for (final t in input.txs) if (inMonth(t.at)) t];
  int sum(Iterable<RaporTx> xs, TxKind k) => xs.where((t) => t.kind == k).fold(0, (a, t) => a + t.amount);
  final int income = sum(mTx, TxKind.pemasukan);
  final int expense = sum(mTx, TxKind.pengeluaran);
  final DateTime pFrom = DateTime(month.year, month.month - 1);
  final List<RaporTx> pTx = [for (final t in input.txs) if (!t.at.isBefore(pFrom) && t.at.isBefore(from)) t];
  final int prevIncome = sum(pTx, TxKind.pemasukan);
  final int prevExpense = sum(pTx, TxKind.pengeluaran);
  final DateTime today = _day(input.now);

  // ---- Menabung
  final AspectScore menabung;
  if (income <= 0) {
    menabung = const AspectScore(RaporAspect.menabung, null,
        reason: 'Belum dinilai: pemasukan belum dicatat', mine: 'Pemasukan bulan ini Rp0', tip: 'Catat pemasukan (mis. gaji) supaya bisa dinilai.');
  } else {
    final double rate = (income - expense) / income;
    final RaporGrade g = rate >= .2 ? RaporGrade.juara : rate >= .1 ? RaporGrade.aman : rate >= 0 ? RaporGrade.nanggung : RaporGrade.waduh;
    final int toTwenty = (income * .2 - (income - expense)).ceil();
    menabung = AspectScore(
      RaporAspect.menabung,
      g,
      value: rate,
      reason: rate >= 0 ? 'Sisa ${_pct(rate)} (${Rupiah.compact(income - expense)})' : 'Tekor ${Rupiah.compact(expense - income)}',
      mine: '(${Rupiah.format(income)} − ${Rupiah.format(expense)}) ÷ ${Rupiah.format(income)} = ${_pct(rate)}',
      tip: g == RaporGrade.juara
          ? 'Mantap, pertahankan sisa ≥ 20%.'
          : 'Sisihkan ${Rupiah.compact(toTwenty)} lagi per bulan untuk mencapai 20% (Juara).',
    );
  }

  // ---- Tagihan & cicilan: kewajiban yang jatuh tempo di bulan ini.
  final Map<int, RaporBill> billById = {for (final b in input.bills) b.id: b};
  final List<({String name, int amount, bool installment, int lateDays, bool unpaid})> dues = [];
  for (final t in input.txs) {
    if (t.billId == null || t.kind != TxKind.pengeluaran) continue;
    final RaporBill? b = billById[t.billId];
    final DateTime? due = t.billDue;
    if (due != null ? !inMonth(due) : !inMonth(t.at)) continue;
    final int late = due == null ? 0 : math.max(0, _day(t.at).difference(_day(due)).inDays);
    dues.add((name: b?.name ?? t.note, amount: t.amount, installment: b?.installment ?? false, lateDays: late, unpaid: false));
  }
  for (final b in input.bills) {
    if (!b.active || !inMonth(b.nextDue)) continue;
    final int late = today.difference(_day(b.nextDue)).inDays;
    if (late <= 0) continue; // belum jatuh tempo
    dues.add((name: b.name, amount: b.amount, installment: b.installment, lateDays: late, unpaid: true));
  }
  final AspectScore tagihan;
  if (dues.isEmpty) {
    tagihan = const AspectScore(RaporAspect.tagihan, null, reason: 'Belum dinilai: tidak ada tagihan jatuh tempo', mine: 'Tidak ada tagihan bulan ini');
  } else {
    final List<({String name, int amount, bool installment, int lateDays, bool unpaid})> lates = [for (final d in dues) if (d.lateDays > 0) d]
      ..sort((a, b) => b.lateDays.compareTo(a.lateDays));
    final bool stale = dues.any((d) => d.unpaid && d.lateDays > 30);
    final RaporGrade g = stale
        ? RaporGrade.waduh
        : lates.isEmpty
            ? RaporGrade.juara
            : lates.length == 1 && lates.first.lateDays <= 7
                ? RaporGrade.aman
                : RaporGrade.nanggung;
    final int onTime = dues.length - lates.length;
    final String worst = lates.isEmpty
        ? ''
        : ' · ${lates.first.name} ${lates.first.unpaid ? 'belum dibayar ${lates.first.lateDays} hari' : 'telat ${lates.first.lateDays} hari'}';
    tagihan = AspectScore(
      RaporAspect.tagihan,
      g,
      value: lates.isEmpty ? 0 : lates.first.lateDays.toDouble(),
      reason: lates.isEmpty ? 'Semua ${dues.length} tagihan tepat waktu' : '$onTime dari ${dues.length} tepat$worst',
      mine: lates.isEmpty
          ? '${dues.length} tagihan, semuanya dibayar tepat waktu'
          : '${dues.length} tagihan: $onTime tepat waktu, ${lates.length} telat (${lates.map((d) => '${d.name} ${d.lateDays} hari').join(', ')})',
      tip: lates.isEmpty ? 'Pertahankan, riwayat bayar tepat waktu penting saat mengajukan kredit.' : 'Nyalakan pengingat tagihan H-3 supaya tidak telat lagi.',
    );
  }

  final int installments = dues.where((d) => d.installment).fold(0, (a, d) => a + d.amount) +
      input.utangDue.where((u) => inMonth(u.due)).fold(0, (a, u) => a + u.amount);
  final AspectScore cicilan;
  if (income <= 0) {
    cicilan = const AspectScore(RaporAspect.cicilan, null, reason: 'Belum dinilai: pemasukan belum dicatat', mine: 'Pemasukan bulan ini Rp0');
  } else if (installments == 0) {
    cicilan = const AspectScore(RaporAspect.cicilan, RaporGrade.juara, value: 0, reason: 'Bebas cicilan bulan ini', mine: 'Tidak ada cicilan, paylater, atau utang jatuh tempo', tip: 'Mantap, pertahankan.');
  } else {
    final double r = installments / income;
    final RaporGrade g = r <= .2 ? RaporGrade.juara : r <= .3 ? RaporGrade.aman : r <= .4 ? RaporGrade.nanggung : RaporGrade.waduh;
    cicilan = AspectScore(
      RaporAspect.cicilan,
      g,
      value: r,
      reason: 'Cicilan ${_pct(r)} dari pemasukan',
      mine: '${Rupiah.format(installments)} ÷ ${Rupiah.format(income)} = ${_pct(r)}',
      tip: r <= .3 ? 'Masih aman. Hindari cicilan baru sampai yang ada lunas.' : 'Di atas 30%: tahan cicilan/paylater baru dan lunasi yang terkecil dulu.',
    );
  }

  // ---- Budget
  final List<RaporBudget> budgets = input.budgets[from] ?? const [];
  int spentFor(int? cat) => mTx.where((t) => t.kind == TxKind.pengeluaran && (cat == null || t.categoryId == cat)).fold(0, (a, t) => a + t.amount);
  final AspectScore budget;
  final List<({String name, int limit, int spent})> catB = [
    for (final b in budgets)
      if (b.categoryId != null && b.limit > 0) (name: input.categoryNames[b.categoryId] ?? 'Kategori', limit: b.limit, spent: spentFor(b.categoryId)),
  ];
  final RaporBudget? totalB = budgets.where((b) => b.categoryId == null && b.limit > 0).firstOrNull;
  if (catB.isEmpty && totalB == null) {
    budget = const AspectScore(RaporAspect.budget, null,
        reason: 'Belum dinilai: belum ada budget', mine: 'Belum ada budget bulan ini', tip: 'Atur budget supaya disiplin belanja bisa dinilai.');
  } else {
    final List<({String name, int limit, int spent})> overs = [for (final c in catB) if (c.spent > c.limit) c]
      ..sort((a, b) => (b.spent / b.limit).compareTo(a.spent / a.limit));
    final double totalRatio = totalB == null ? 0 : expense / totalB.limit;
    final RaporGrade g;
    if (totalRatio > 1.2) {
      g = RaporGrade.waduh;
    } else if (catB.isEmpty) {
      g = totalRatio <= 1 ? RaporGrade.juara : totalRatio <= 1.1 ? RaporGrade.aman : RaporGrade.nanggung;
    } else if (overs.isEmpty && totalRatio <= 1) {
      g = RaporGrade.juara;
    } else if (overs.length <= 1 && (overs.isEmpty || overs.first.spent <= overs.first.limit * 1.1) && totalRatio <= 1.1) {
      g = RaporGrade.aman;
    } else {
      g = RaporGrade.nanggung;
    }
    final int safe = catB.length - overs.length;
    String overPct(({String name, int limit, int spent}) c) => '${((c.spent / c.limit - 1) * 100).round()}%';
    budget = AspectScore(
      RaporAspect.budget,
      g,
      value: overs.length.toDouble(),
      reason: catB.isEmpty
          ? 'Budget total ${_pct(totalRatio)} terpakai'
          : overs.isEmpty
              ? 'Semua ${catB.length} kategori aman'
              : '$safe dari ${catB.length} aman · ${overs.first.name} jebol ${overPct(overs.first)}',
      mine: [
        if (catB.isNotEmpty) '$safe aman${overs.isEmpty ? '' : ', ${overs.map((c) => '${c.name} ${Rupiah.compact(c.spent)} dari ${Rupiah.compact(c.limit)}').join(', ')}'}',
        if (totalB != null) 'Total ${Rupiah.compact(expense)} dari ${Rupiah.compact(totalB.limit)} (${_pct(totalRatio)})',
      ].join(' · '),
      tip: overs.isEmpty
          ? 'Pertahankan, budget-mu realistis.'
          : 'Naikkan budget ${overs.first.name} ke ${Rupiah.compact(_round50k(overs.first.spent))} atau tahan belanjanya bulan depan.',
    );
  }

  // ---- Ketahanan
  final int afterEnd = input.txs.where((t) => !t.at.isBefore(to)).fold(0, (a, t) => a + _signed(t));
  final int balanceEnd = input.balanceNow - afterEnd;
  final DateTime? first = input.firstDay;
  // Rata-rata pengeluaran bulan ini & 2 bulan sebelumnya (yang sudah ada datanya).
  final List<int> lastExp = [
    for (int k = 0; k < 3; k++)
      if (k == 0 || first == null || !DateTime(month.year, month.month - k).isBefore(DateTime(first.year, first.month)))
        input.txs
            .where((t) =>
                t.kind == TxKind.pengeluaran &&
                !t.at.isBefore(DateTime(month.year, month.month - k)) &&
                t.at.isBefore(DateTime(month.year, month.month - k + 1)))
            .fold(0, (a, t) => a + t.amount),
  ];
  final double avgExp = lastExp.isEmpty ? 0 : lastExp.reduce((a, b) => a + b) / lastExp.length;
  final AspectScore ketahanan;
  if (avgExp <= 0) {
    ketahanan = const AspectScore(RaporAspect.ketahanan, null, reason: 'Belum dinilai: belum ada pengeluaran', mine: 'Rata-rata pengeluaran Rp0');
  } else {
    final double months = math.max(0, balanceEnd) / avgExp;
    final RaporGrade g = months >= 6 ? RaporGrade.juara : months >= 3 ? RaporGrade.aman : months >= 1 ? RaporGrade.nanggung : RaporGrade.waduh;
    final int perMonth = _round50k(((3 * avgExp - balanceEnd) / 12).ceil());
    ketahanan = AspectScore(
      RaporAspect.ketahanan,
      g,
      value: months,
      reason: 'Saldo cukup ${_num1(months)} bulan pengeluaran',
      mine: '${Rupiah.format(balanceEnd)} ÷ ${Rupiah.format(avgExp.round())} = ${_num1(months)} bulan',
      tip: months >= 6
          ? 'Bantalanmu tebal. Kelebihan di atas 6 bulan bisa mulai diinvestasikan.'
          : months >= 3
          ? 'Bantalanmu sudah aman. Lanjutkan sampai 6 bulan pengeluaran untuk Juara.'
          : 'Sisihkan ${Rupiah.compact(math.max(50000, perMonth))}/bln ke Dana darurat untuk mencapai 3 bulan dalam setahun.',
    );
  }

  // ---- Rajin mencatat (hanya catatan buatan pengguna).
  final DateTime countFrom = first != null && first.isAfter(from) ? first : from;
  final DateTime countTo = today.isBefore(to) ? today.add(const Duration(days: 1)) : to;
  final int daysCounted = math.max(0, countTo.difference(countFrom).inDays);
  final int daysLogged = {for (final t in mTx) if (!t.auto && !t.at.isBefore(countFrom)) _day(t.at)}.length;
  final AspectScore mencatat;
  if (daysCounted == 0) {
    mencatat = const AspectScore(RaporAspect.mencatat, null, reason: 'Belum dinilai', mine: 'Belum ada hari untuk dihitung');
  } else {
    final double r = daysLogged / daysCounted;
    final RaporGrade g = r >= .8 ? RaporGrade.juara : r >= .5 ? RaporGrade.aman : r >= .25 ? RaporGrade.nanggung : RaporGrade.waduh;
    mencatat = AspectScore(
      RaporAspect.mencatat,
      g,
      value: r,
      reason: '$daysLogged dari $daysCounted hari tercatat',
      mine: '$daysLogged ÷ $daysCounted = ${_pct(r)}',
      tip: r >= .8 ? 'Mantap, lanjutkan kebiasaanmu.' : 'Catat sebentar tiap malam — 1 menit cukup.',
    );
  }

  final List<AspectScore> scores = [menabung, cicilan, tagihan, budget, ketahanan, mencatat];
  final List<AspectScore> graded = [for (final s in scores) if (s.grade != null) s];
  final double avg = graded.isEmpty ? 0 : graded.fold(0, (a, s) => a + s.grade!.points) / graded.length;
  final bool lowData = daysCounted > 0 && daysLogged / daysCounted < .5;

  // ---- Kategori terbesar
  Map<int?, int> byCat(List<RaporTx> xs) {
    final Map<int?, int> m = {};
    for (final t in xs) {
      if (t.kind == TxKind.pengeluaran) m[t.categoryId] = (m[t.categoryId] ?? 0) + t.amount;
    }
    return m;
  }

  final Map<int?, int> cur = byCat(mTx), prev = byCat(pTx);
  final List<MapEntry<int?, int>> top = cur.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final List<RaporCategory> categories = [
    for (final e in top.take(5))
      (
        name: e.key == null ? 'Tanpa kategori' : (input.categoryNames[e.key] ?? 'Kategori'),
        amount: e.value,
        deltaPct: (prev[e.key] ?? 0) > 0 ? ((e.value / prev[e.key]! - 1) * 100).round() : null,
        budgetPct: switch (budgets.where((b) => b.categoryId == e.key && e.key != null && b.limit > 0).firstOrNull) {
          final RaporBudget b? => (e.value * 100 / b.limit).round(),
          _ => null,
        },
      ),
  ];

  // ---- Sorotan
  final List<RaporHighlight> highlights = [];
  final Map<DateTime, int> perDay = {};
  for (final t in mTx) {
    if (t.kind == TxKind.pengeluaran) perDay[_day(t.at)] = (perDay[_day(t.at)] ?? 0) + t.amount;
  }
  if (perDay.isNotEmpty) {
    final MapEntry<DateTime, int> worst = perDay.entries.reduce((a, b) => b.value > a.value ? b : a);
    highlights.add((icon: '📅', label: 'Hari paling boros', value: '${DateFmt.longDate(worst.key, now: worst.key)} · ${Rupiah.compact(worst.value)}'));
  }
  final RaporTx? biggest =
      mTx.where((t) => t.kind == TxKind.pengeluaran).fold<RaporTx?>(null, (a, t) => a == null || t.amount > a.amount ? t : a);
  if (biggest != null) {
    final String what = biggest.note.isNotEmpty ? biggest.note : (input.categoryNames[biggest.categoryId] ?? 'Pengeluaran');
    highlights.add((icon: '🧾', label: 'Transaksi terbesar', value: '$what · ${Rupiah.format(biggest.amount)}'));
  }
  if (input.recurringMonthly.isNotEmpty) {
    highlights.add((
      icon: '🔁',
      label: 'Langganan & berulang',
      value: '${input.recurringMonthly.length} jadwal · ${Rupiah.compact(input.recurringMonthly.fold(0, (a, v) => a + v))}/bln',
    ));
  }
  final Map<String, ({int amount, int percent})> goals = {};
  for (final g in input.goalMoves) {
    if (!inMonth(g.at)) continue;
    final int prevAmt = goals[g.name]?.amount ?? 0;
    goals[g.name] = (amount: prevAmt + g.amount, percent: g.percentNow);
  }
  if (goals.isNotEmpty) {
    final MapEntry<String, ({int amount, int percent})> g = goals.entries.reduce((a, b) => b.value.amount > a.value.amount ? b : a);
    highlights.add((icon: '🛟', label: 'Target tabungan', value: '${g.key} ${Rupiah.format(g.value.amount, signed: true)} → ${g.value.percent}%'));
  }
  if (input.piutangLeft > 0) {
    highlights.add((icon: '🤝', label: 'Piutang belum kembali', value: '${Rupiah.compact(input.piutangLeft)} dari ${input.piutangPeople} orang'));
  }

  final Rapor? previous = withPrevious && first != null && !pFrom.isBefore(DateTime(first.year, first.month))
      ? computeRapor(input, pFrom, withPrevious: false)
      : null;

  // ---- Saran (maks 3)
  final List<RaporTip> tips = [];
  if (lowData) {
    tips.add((text: 'Catat pemasukan & pengeluaran harian supaya semua aspek bisa dinilai.', action: 'Catat', target: RaporAction.catat));
  }
  if (budget.grade == null && !lowData) {
    tips.add((text: 'Atur budget bulanan supaya Disiplin budget bisa dinilai.', action: 'Atur budget', target: RaporAction.aturBudget));
  } else if (budget.grade != null && budget.grade != RaporGrade.juara && budget.tip != null) {
    tips.add((text: budget.tip!, action: 'Atur budget', target: RaporAction.aturBudget));
  }
  if (tagihan.grade != null && tagihan.grade != RaporGrade.juara) {
    tips.add((text: 'Nyalakan pengingat tagihan H-3 supaya tidak telat lagi.', action: 'Pengingat', target: RaporAction.tagihan));
  }
  if (ketahanan.grade != null && ketahanan.grade!.points <= RaporGrade.nanggung.points && ketahanan.tip != null) {
    tips.add((text: ketahanan.tip!, action: 'Sisihkan', target: RaporAction.target));
  }

  final Rapor draft = Rapor(
    month: from,
    scores: scores,
    overall: graded.isEmpty ? null : RaporGrade.fromAverage(avg),
    average: avg,
    income: income,
    expense: expense,
    prevIncome: prevIncome,
    prevExpense: prevExpense,
    categories: categories,
    highlights: highlights,
    tips: tips.take(3).toList(),
    note: '',
    lowData: lowData,
    daysLogged: daysLogged,
    daysCounted: daysCounted,
    previous: previous,
  );
  return Rapor(
    month: from,
    scores: scores,
    overall: draft.overall,
    average: avg,
    income: income,
    expense: expense,
    prevIncome: prevIncome,
    prevExpense: prevExpense,
    categories: categories,
    highlights: highlights,
    tips: draft.tips,
    note: raporNote(draft),
    lowData: lowData,
    daysLogged: daysLogged,
    daysCounted: daysCounted,
    previous: previous,
  );
}

int _round50k(int v) => v <= 0 ? 0 : ((v + 49999) ~/ 50000) * 50000;

/// "Kata HitungIn": 1–2 kalimat santai dari perubahan terbesar bulan itu.
String raporNote(Rapor r) {
  if (r.overall == null) return 'Belum banyak yang bisa dinilai. Mulai catat pemasukan & pengeluaranmu, nanti rapornya makin seru.';
  if (r.lowData) {
    return 'Baru ${r.daysLogged} dari ${r.daysCounted} hari tercatat. Coba catat tiap malam seminggu ini — rapor berikutnya bakal jauh lebih akurat.';
  }
  final List<String> out = [];
  final AspectScore tabung = r.scores.firstWhere((s) => s.aspect == RaporAspect.menabung);
  final AspectScore? prevTabung = r.previous?.scores.firstWhere((s) => s.aspect == RaporAspect.menabung);
  if (tabung.value != null && prevTabung?.value != null) {
    final double a = prevTabung!.value!, b = tabung.value!;
    if (b - a >= .03) out.add('Sisa uangmu naik dari ${_pct(a)} ke ${_pct(b)} — mantap!');
    if (a - b >= .03) out.add('Sisa uangmu turun dari ${_pct(a)} ke ${_pct(b)}, bulan depan coba tahan sedikit ya.');
  } else if (tabung.value != null && tabung.value! >= .2) {
    out.add('Kamu berhasil menyisihkan ${_pct(tabung.value!)} pemasukan — keren!');
  }
  final RaporCategory? jump = r.categories.where((c) => (c.deltaPct ?? 0) >= 20).firstOrNull;
  if (jump != null && out.length < 2) out.add('${jump.name} naik ${jump.deltaPct}% dari bulan lalu, cek lagi yuk.');
  final AspectScore tagihan = r.scores.firstWhere((s) => s.aspect == RaporAspect.tagihan);
  if (tagihan.grade != null && tagihan.grade != RaporGrade.juara && out.length < 2) {
    out.add('Ada tagihan yang telat, nyalain pengingat biar bulan depan aman.');
  }
  if (out.isEmpty) {
    out.add(switch (r.overall!) {
      RaporGrade.juara => 'Bulan yang rapi banget. Pertahankan ritmenya!',
      RaporGrade.aman => 'Keuanganmu aman bulan ini. Satu langkah lagi ke Juara!',
      RaporGrade.nanggung => 'Masih ada yang bisa dirapikan — mulai dari satu saran di bawah.',
      RaporGrade.waduh => 'Bulan yang berat. Pelan-pelan, mulai dari satu saran di bawah dulu.',
    });
  }
  return out.take(2).join(' ');
}

// ---------------------------------------------------------------- prakiraan

/// Peringatan bulan berjalan (P3d): prakiraan total & kategori yang hampir habis.
typedef Forecast = ({int spent, int projected, int? limit, int daysLeft, int perDayToFit, List<({String name, int pct})> hot});

/// Null bila tidak ada yang perlu diperhatikan (atau masih terlalu awal bulan).
Forecast? computeForecast({
  required DateTime now,
  required int spent,
  required int? totalLimit,
  required List<({String name, int spent, int limit})> categories,
}) {
  final int day = now.day;
  final int days = _daysIn(now);
  if (day < 5) return null;
  final int projected = (spent / day * days).round();
  final int daysLeft = days - day;
  final List<({String name, int pct})> hot = [
    for (final c in categories)
      if (c.limit > 0 && c.spent * 100 ~/ c.limit >= 80 && daysLeft > 0) (name: c.name, pct: c.spent * 100 ~/ c.limit),
  ]..sort((a, b) => b.pct.compareTo(a.pct));
  final bool overTotal = totalLimit != null && totalLimit > 0 && projected > totalLimit;
  if (!overTotal && hot.isEmpty) return null;
  final int perDay = totalLimit == null || daysLeft <= 0 ? 0 : math.max(0, (totalLimit - spent) ~/ daysLeft);
  return (spent: spent, projected: projected, limit: totalLimit, daysLeft: daysLeft, perDayToFit: perDay, hot: hot);
}

/// "Oktober" untuk judul.
String raporMonthName(DateTime m) => DateFmt.months[m.month - 1];
