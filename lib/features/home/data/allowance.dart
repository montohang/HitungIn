import '../../../core/db/tables.dart';
import '../../../core/utils/dates.dart';

/// Satu kewajiban yang akan jatuh tempo (tagihan, cicilan, pengeluaran
/// berulang, atau utang). [times] membatasi jumlah kemunculan (sisa cicilan);
/// null = tanpa batas.
typedef UpcomingDue = ({String name, int amount, DateTime next, BillRepeat repeat, int anchorDay, int? times});

/// Keadaan kartu "Jatah hari ini".
enum AllowanceState {
  /// Belum ada saldo di dompet yang dihitung → ajak isi saldo.
  kosong,

  /// Tagihan & pengeluaran berulang sudah menutup saldo sampai gajian.
  habis,
  aman,

  /// Sisa hari ini < 20% jatah.
  menipis,

  /// Pengeluaran hari ini melebihi jatah.
  lewat,
}

/// Hasil hitungan jatah harian (P1-1). Semua nominal dalam rupiah.
class Allowance {
  const Allowance({
    required this.state,
    required this.jatah,
    required this.spentToday,
    required this.nextPayday,
    required this.daysToPayday,
    required this.balance,
    required this.billsDue,
    required this.recurringDue,
    this.debtsDue = 0,
    this.debtNames = const [],
    this.setAside = 0,
    this.setAsideNames = const [],
    required this.perSaldo,
    required this.perBudget,
    required this.useBudget,
    required this.daysLeftInMonth,
    required this.budgetLeft,
    required this.tomorrow,
    required this.billNames,
    required this.recurringNames,
  });

  final AllowanceState state;
  final int jatah;
  final int spentToday;

  /// Tanggal gajian berikutnya; periode berakhir sehari sebelumnya.
  final DateTime nextPayday;

  /// Sisa hari sampai gajian, termasuk hari ini.
  final int daysToPayday;

  final int balance;
  final int billsDue;
  final int recurringDue;

  /// Utang (aku berutang) yang jatuh tempo sampai akhir periode (P2-2).
  final int debtsDue;
  final List<String> debtNames;

  /// Uang yang disisihkan untuk target tabungan dari dompet yang dihitung (P3b).
  final int setAside;
  final List<String> setAsideNames;

  /// Jatah per hari menurut saldo, dan menurut sisa budget bulan ini (null
  /// bila budget total tidak diatur).
  final int perSaldo;
  final int? perBudget;

  /// Jatah memakai sisa budget karena lebih kecil dari hitungan saldo.
  final bool useBudget;
  final int daysLeftInMonth;
  final int? budgetLeft;

  /// Jatah besok bila hari ini tidak ada pengeluaran lagi (null di hari
  /// terakhir periode).
  final int? tomorrow;
  final List<String> billNames;
  final List<String> recurringNames;

  int get remaining => jatah - spentToday;

  /// Uang yang tidak terikat tagihan/berulang sampai gajian (sudah dikurangi
  /// pengeluaran hari ini, karena saldo sekarang sudah termasuk itu).
  int get free => balance - billsDue - recurringDue - debtsDue - setAside;
}

/// Tanggal gajian berikutnya setelah [today] untuk tanggal [payday] (1–31;
/// di bulan pendek jadi hari terakhir bulan). Hari gajian itu sendiri
/// memulai periode baru.
DateTime nextPaydayAfter(DateTime today, int payday) {
  final DateTime d = Dates.day(today);
  DateTime inMonth(int year, int month) {
    final DateTime first = DateTime(year, month);
    final int last = Dates.daysInMonth(first.year, first.month);
    return DateTime(first.year, first.month, payday > last ? last : payday);
  }

  final DateTime thisMonth = inMonth(d.year, d.month);
  return thisMonth.isAfter(d) ? thisMonth : inMonth(d.year, d.month + 1);
}

int _floor100(int v) => v <= 0 ? 0 : (v ~/ 100) * 100;

/// Total kemunculan [items] dari tanggal [from] sampai [until] (inklusif).
/// [overdue] true = tanggal yang sudah lewat tetap dihitung sekali (tagihan
/// terlambat yang belum dibayar).
({int total, List<String> names}) _dueUntil(List<UpcomingDue> items, DateTime from, DateTime until, {required bool overdue}) {
  int total = 0;
  final List<String> names = [];
  for (final UpcomingDue it in items) {
    DateTime? at = Dates.day(it.next);
    int count = 0;
    while (at != null && !at.isAfter(until) && count < (it.times ?? 60)) {
      if (overdue || !at.isBefore(from)) {
        total += it.amount;
        if (!names.contains(it.name)) names.add(it.name);
      }
      count++;
      at = Dates.nextDue(at, it.repeat, anchorDay: it.anchorDay);
    }
  }
  return (total: total, names: names);
}

/// Hitung jatah hari ini. [balance] = saldo dompet yang ikut dihitung,
/// [setAside] = uang di dompet itu yang disisihkan untuk target tabungan,
/// [spentToday] = pengeluaran hari ini dari dompet itu, [budgetLeft] =
/// batas budget total bulan ini dikurangi pemakaiannya (null bila tidak
/// diatur).
Allowance computeAllowance({
  required DateTime now,
  required int payday,
  required int balance,
  required int spentToday,
  required List<UpcomingDue> bills,
  required List<UpcomingDue> recurring,
  List<UpcomingDue> debts = const [],
  int setAside = 0,
  List<String> setAsideNames = const [],
  int? budgetLeft,
}) {
  final DateTime today = Dates.day(now);
  final DateTime next = nextPaydayAfter(today, payday);
  final DateTime periodEnd = next.subtract(const Duration(days: 1));
  final int daysPay = next.difference(today).inDays.clamp(1, 366);
  final int daysMonth = Dates.daysInMonth(today.year, today.month) - today.day + 1;

  final b = _dueUntil(bills, today, periodEnd, overdue: true);
  final r = _dueUntil(recurring, today, periodEnd, overdue: false);
  final d = _dueUntil(debts, today, periodEnd, overdue: true);
  final int free = balance - b.total - r.total - d.total - setAside;

  final int perSaldo = _floor100((free + spentToday) ~/ daysPay);
  final int? perBudget = budgetLeft == null ? null : _floor100((budgetLeft + spentToday) ~/ daysMonth);
  final bool useBudget = perBudget != null && perBudget < perSaldo;
  final int jatah = useBudget ? perBudget : perSaldo;

  final int? tomorrow = useBudget
      ? (daysMonth > 1 ? _floor100(budgetLeft! ~/ (daysMonth - 1)) : null)
      : (daysPay > 1 ? _floor100(free ~/ (daysPay - 1)) : null);

  final AllowanceState state;
  if (balance <= 0 && spentToday == 0) {
    state = AllowanceState.kosong;
  } else if (free + spentToday <= 0 || jatah == 0) {
    state = AllowanceState.habis;
  } else if (spentToday > jatah) {
    state = AllowanceState.lewat;
  } else if (jatah - spentToday < jatah * 0.2) {
    state = AllowanceState.menipis;
  } else {
    state = AllowanceState.aman;
  }

  return Allowance(
    state: state,
    jatah: jatah,
    spentToday: spentToday,
    nextPayday: next,
    daysToPayday: daysPay,
    balance: balance,
    billsDue: b.total,
    recurringDue: r.total,
    debtsDue: d.total,
    debtNames: d.names,
    setAside: setAside,
    setAsideNames: setAsideNames,
    perSaldo: perSaldo,
    perBudget: perBudget,
    useBudget: useBudget,
    daysLeftInMonth: daysMonth,
    budgetLeft: budgetLeft,
    tomorrow: tomorrow,
    billNames: b.names,
    recurringNames: r.names,
  );
}
