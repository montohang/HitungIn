import '../../../core/db/tables.dart';
import '../../../core/utils/dates.dart';

/// Satu transaksi yang relevan untuk rekap (dipisah dari kelas Drift supaya
/// mudah dites).
typedef RecapTx = ({TxKind kind, int amount, DateTime at, int? categoryId, String category});

/// Senin 00.00 minggu yang memuat [d].
DateTime weekStart(DateTime d) {
  final DateTime day = Dates.day(d);
  return DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));
}

/// Rekap satu minggu Senin–Minggu (P3a). Hanya Pemasukan & Pengeluaran —
/// pindah saldo dan utang-piutang tidak dihitung, sama seperti Laporan.
class WeeklyRecap {
  const WeeklyRecap({
    required this.start,
    required this.out,
    required this.income,
    required this.prevOut,
    required this.perDay,
    required this.topCategories,
    required this.daysLogged,
    required this.insight,
  });

  /// Senin minggu ini.
  final DateTime start;
  final int out;
  final int income;

  /// Pengeluaran minggu sebelumnya.
  final int prevOut;

  /// Pengeluaran Senin..Minggu.
  final List<int> perDay;

  /// Maks. 3 kategori pengeluaran terbesar: (nama, total).
  final List<({String name, int total})> topCategories;

  /// Hari yang punya catatan buatan pengguna (0–7).
  final int daysLogged;
  final String? insight;

  DateTime get end => DateTime(start.year, start.month, start.day + 6);

  /// Positif = lebih hemat dari minggu sebelumnya.
  int get saved => prevOut - out;

  bool get isEmpty => out == 0 && income == 0;

  /// Indeks hari paling boros (0 = Senin), null bila tidak ada pengeluaran.
  int? get topDay {
    int best = -1, max = 0;
    for (int i = 0; i < perDay.length; i++) {
      if (perDay[i] > max) {
        max = perDay[i];
        best = i;
      }
    }
    return best < 0 ? null : best;
  }

  int get averagePerDay => out ~/ 7;
}

const List<String> recapDayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// Hitung rekap minggu yang dimulai [start] dari [txs] (boleh berisi
/// transaksi di luar rentang; dua minggu ke belakang dibutuhkan untuk
/// perbandingan). [loggedDays] = hari dengan catatan buatan pengguna.
WeeklyRecap computeWeeklyRecap({required DateTime start, required List<RecapTx> txs, required Set<DateTime> loggedDays}) {
  final DateTime s = Dates.day(start);
  final DateTime e = DateTime(s.year, s.month, s.day + 7);
  final DateTime ps = DateTime(s.year, s.month, s.day - 7);
  final List<int> perDay = List.filled(7, 0);
  final Map<String, int> cats = {}, prevCats = {};
  int out = 0, income = 0, prevOut = 0;
  for (final RecapTx t in txs) {
    if (t.kind != TxKind.pengeluaran && t.kind != TxKind.pemasukan) continue;
    final bool thisWeek = !t.at.isBefore(s) && t.at.isBefore(e);
    final bool prevWeek = !t.at.isBefore(ps) && t.at.isBefore(s);
    if (t.kind == TxKind.pemasukan) {
      if (thisWeek) income += t.amount;
      continue;
    }
    if (thisWeek) {
      out += t.amount;
      perDay[Dates.day(t.at).difference(s).inDays.clamp(0, 6)] += t.amount;
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    } else if (prevWeek) {
      prevOut += t.amount;
      prevCats[t.category] = (prevCats[t.category] ?? 0) + t.amount;
    }
  }
  final List<({String name, int total})> top = [
    for (final MapEntry<String, int> e in (cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(3))
      (name: e.key, total: e.value),
  ];
  final int logged = [for (int i = 0; i < 7; i++) DateTime(s.year, s.month, s.day + i)].where(loggedDays.contains).length;
  final WeeklyRecap draft = WeeklyRecap(
    start: s,
    out: out,
    income: income,
    prevOut: prevOut,
    perDay: perDay,
    topCategories: top,
    daysLogged: logged,
    insight: null,
  );
  return WeeklyRecap(
    start: s,
    out: out,
    income: income,
    prevOut: prevOut,
    perDay: perDay,
    topCategories: top,
    daysLogged: logged,
    insight: recapInsight(draft, cats, prevCats),
  );
}

/// Satu kalimat insight dari aturan sederhana, urut prioritas:
/// kategori yang turun/naik paling tajam (≥ 20%, minggu lalu ≥ Rp50rb),
/// lalu hari paling boros.
String? recapInsight(WeeklyRecap r, Map<String, int> cats, Map<String, int> prevCats) {
  if (r.out == 0) return null;
  ({String name, int pct})? down, up;
  for (final MapEntry<String, int> p in prevCats.entries) {
    if (p.value < 50000) continue;
    final int now = cats[p.key] ?? 0;
    final int pct = ((now - p.value) * 100 / p.value).round();
    if (pct <= -20 && (down == null || pct < down.pct)) down = (name: p.key, pct: pct);
    if (pct >= 20 && (up == null || pct > up.pct)) up = (name: p.key, pct: pct);
  }
  if (down != null) return '${down.name} turun ${-down.pct}% dari minggu lalu. Pertahankan!';
  if (up != null) return '${up.name} naik ${up.pct}% dari minggu lalu.';
  final int? d = r.topDay;
  return d == null ? null : 'Pengeluaran paling banyak di hari ${recapDayNames[d]}.';
}

/// Streak mencatat (P3a): hari berturut-turut yang punya catatan buatan
/// pengguna. Satu hari kosong per minggu Senin–Minggu tidak memutus streak
/// ("hari santai"). Hari ini yang belum dicatat juga tidak memutus.
typedef Streak = ({int current, int best, Set<DateTime> restDays});

Streak computeStreak(Set<DateTime> loggedDays, DateTime now) {
  final DateTime today = Dates.day(now);
  if (loggedDays.isEmpty) return (current: 0, best: 0, restDays: const {});
  final Set<DateTime> logged = {for (final d in loggedDays) Dates.day(d)};
  final DateTime first = logged.reduce((a, b) => a.isBefore(b) ? a : b);

  // Arus mundur dari hari ini untuk streak sekarang.
  int current = 0;
  final Set<DateTime> rest = {};
  final Set<DateTime> restWeeks = {};
  DateTime d = today;
  if (!logged.contains(d)) d = d.subtract(const Duration(days: 1));
  while (!d.isBefore(first)) {
    if (logged.contains(d)) {
      current++;
    } else {
      final DateTime w = weekStart(d);
      if (restWeeks.contains(w)) break;
      restWeeks.add(w);
      rest.add(d);
    }
    d = DateTime(d.year, d.month, d.day - 1);
  }
  // Hari santai di ujung awal yang tidak diikuti catatan tidak dihitung.
  rest.removeWhere((r) => !logged.contains(DateTime(r.year, r.month, r.day - 1)));

  // Rekor: pindai maju dengan aturan yang sama.
  int best = 0, run = 0;
  final Set<DateTime> used = {};
  for (DateTime x = first; !x.isAfter(today); x = DateTime(x.year, x.month, x.day + 1)) {
    if (logged.contains(x)) {
      run++;
      if (run > best) best = run;
    } else if (x == today) {
      // Hari ini belum dicatat: belum putus.
    } else if (run > 0 && !used.contains(weekStart(x)) && logged.contains(DateTime(x.year, x.month, x.day + 1))) {
      used.add(weekStart(x));
    } else {
      run = 0;
    }
  }
  return (current: current, best: best < current ? current : best, restDays: rest);
}
