import '../../../core/db/app_database.dart';

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
