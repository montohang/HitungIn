import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';

/// Status jatuh tempo tagihan relatif terhadap hari ini.
enum BillDueState { terlambat, hariIni, segera, nanti }

typedef BillDue = ({BillDueState state, int days});

/// [days] = selisih hari kalender (negatif bila terlambat).
/// "Segera" = dalam rentang `remindDaysBefore` hari.
BillDue billDue(Bill bill, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime due = DateTime(bill.nextDue.year, bill.nextDue.month, bill.nextDue.day);
  // Pakai UTC agar pergantian jam musim panas tidak menggeser hitungan hari.
  final int days = DateTime.utc(due.year, due.month, due.day).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  final BillDueState state = days < 0
      ? BillDueState.terlambat
      : days == 0
          ? BillDueState.hariIni
          : days <= bill.remindDaysBefore
              ? BillDueState.segera
              : BillDueState.nanti;
  return (state: state, days: days);
}

/// Teks pendek: "Terlambat 2 hari", "Hari ini", "Besok", "3 hari lagi".
String billDueLabel(BillDue d) => switch (d.state) {
      BillDueState.terlambat => 'Terlambat ${-d.days} hari',
      BillDueState.hariIni => 'Hari ini',
      _ when d.days == 1 => 'Besok',
      _ => '${d.days} hari lagi',
    };

/// Tagihan yang perlu perhatian (terlambat, hari ini, atau segera).
bool billNeedsAttention(Bill bill, DateTime now) => billDue(bill, now).state != BillDueState.nanti;

/// Hitungan cicilan (P2-1); null untuk tagihan biasa.
typedef InstallmentInfo = ({
  int total,
  int paid,

  /// Cicilan berikutnya (1-based), mis. 4 untuk "Cicilan 4/12".
  int next,
  int remainingCount,

  /// Sisa = (tenor − dibayar) × nominal.
  int remainingAmount,

  /// Jatuh tempo cicilan terakhir.
  DateTime lastDue,
});

InstallmentInfo? installmentOf(Bill bill) {
  final int? total = bill.installmentTotal;
  if (total == null) return null;
  final int paid = bill.installmentPaid.clamp(0, total);
  final int left = total - paid;
  DateTime last = bill.nextDue;
  for (int i = 1; i < left; i++) {
    last = Dates.nextDue(last, bill.repeat, anchorDay: bill.anchorDay) ?? last;
  }
  return (
    total: total,
    paid: paid,
    next: paid + 1 > total ? total : paid + 1,
    remainingCount: left,
    remainingAmount: left * bill.amount,
    lastDue: last,
  );
}

/// Ringkasan cicilan yang masih berjalan: "Sisa cicilan Rp4,8 jt · 3 berjalan".
({int amount, int count}) installmentsSummary(Iterable<Bill> bills) {
  int amount = 0, count = 0;
  for (final Bill b in bills) {
    final InstallmentInfo? i = installmentOf(b);
    if (!b.active || i == null || i.remainingCount == 0) continue;
    amount += i.remainingAmount;
    count++;
  }
  return (amount: amount, count: count);
}
