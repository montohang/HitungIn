import '../../../core/db/app_database.dart';
import '../../../core/utils/rupiah.dart';
import '../../bills/data/bill_reminders.dart';
import 'debts_dao.dart';

/// Utang-piutang yang dingatkan: belum lunas dan punya jatuh tempo.
bool _remindable(DebtWithPayments d) => d.debt.dueDate != null && d.left > 0;

/// Masa pengingat utang: H-1 sampai lewat jatuh tempo, selama belum lunas.
Set<int> debtsInReminderWindow(List<DebtWithPayments> debts, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  return {
    for (final DebtWithPayments d in debts)
      if (_remindable(d) &&
          !DateTime(d.debt.dueDate!.year, d.debt.dueDate!.month, d.debt.dueDate!.day - 1).isAfter(today))
        debtReminderOwner(d.debt.id),
  };
}

/// Judul & isi notifikasi untuk [d]; [daysBefore] 1 = H-1, 0 = hari H.
({String title, String body}) debtReminderText(DebtWithPayments d, {required int daysBefore}) {
  final bool mine = d.debt.direction == DebtDirection.utang;
  return (
    title: mine ? 'Utang ke ${d.debt.name}' : 'Waktunya menagih ${d.debt.name}',
    body: '${daysBefore == 1 ? 'Jatuh tempo besok' : 'Jatuh tempo hari ini'} · '
        '${mine ? 'sisa' : 'sisa pinjaman'} ${Rupiah.format(d.left)}',
  );
}

/// Pengingat jatuh tempo utang-piutang (P2-2, Pro): H-1 dan hari H pada
/// jam pengingat tagihan. Utangku → "Bayar utang ke …"; piutang → "Waktunya
/// menagih …". Waktu yang sudah lewat dilewati.
List<ReminderPlan> planDebtReminders(List<DebtWithPayments> debts, DateTime now, {required int hour}) {
  final List<ReminderPlan> out = [];
  for (final DebtWithPayments d in debts) {
    if (!_remindable(d)) continue;
    final Debt debt = d.debt;
    final DateTime due = debt.dueDate!;
    final int owner = debtReminderOwner(debt.id);
    for (final (int slot, int daysBefore) in const [(0, 1), (1, 0)]) {
      final DateTime at = DateTime(due.year, due.month, due.day - daysBefore, hour);
      if (!at.isAfter(now)) continue;
      final ({String title, String body}) text = debtReminderText(d, daysBefore: daysBefore);
      out.add((
        id: owner * 4 + slot,
        billId: 0,
        at: at,
        title: text.title,
        body: text.body,
        payload: '$debtPayloadPrefix${debt.id}',
      ));
    }
  }
  return out;
}
