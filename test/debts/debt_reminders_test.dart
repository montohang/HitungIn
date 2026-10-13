import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/data/bill_reminders.dart';
import 'package:hitungin/features/bills/reminder_scheduler.dart';
import 'package:hitungin/features/debts/data/debt_reminders.dart';
import 'package:hitungin/features/debts/data/debts_dao.dart';

DebtWithPayments _debt(int id, DebtDirection dir, String name, int amount, DateTime? due, {int paid = 0}) => (
      debt: Debt(
        id: id,
        direction: dir,
        name: name,
        amount: amount,
        occurredAt: DateTime(2026, 10, 1),
        dueDate: due,
        note: '',
        createdAt: DateTime(2026, 10, 1),
      ),
      payments: [
        if (paid > 0) DebtPayment(id: id, debtId: id, amount: paid, paidAt: DateTime(2026, 10, 10), createdAt: DateTime(2026, 10, 10)),
      ],
    );

class _Scheduler implements ReminderScheduler {
  final List<ReminderPlan> scheduled = [];
  final Set<int> shown = {};
  @override
  Future<void> init({required void Function(String payload) onTap}) async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionGranted() async => true;
  @override
  Future<void> cancelPending() async => scheduled.clear();
  @override
  Future<void> dismissShown({required Set<int> keepBillIds}) async => shown.retainAll(keepBillIds);
  @override
  Future<void> schedule(List<ReminderPlan> plans) async => scheduled.addAll(plans);
}

void main() {
  final now = DateTime(2026, 10, 19, 8);
  final debts = [
    _debt(1, DebtDirection.utang, 'Kak Sinta', 300000, DateTime(2026, 10, 25), paid: 100000),
    _debt(2, DebtDirection.piutang, 'Budi', 200000, DateTime(2026, 10, 20)),
    _debt(3, DebtDirection.piutang, 'Tanpa tempo', 50000, null),
    _debt(4, DebtDirection.piutang, 'Lunas', 50000, DateTime(2026, 10, 22), paid: 50000),
  ];

  test('H-1 & hari H untuk yang belum lunas dan punya jatuh tempo; teks dua arah', () {
    final plans = planDebtReminders(debts, now, hour: 9);
    expect([for (final p in plans) (p.at, p.payload)], [
      (DateTime(2026, 10, 24, 9), 'debt:1'),
      (DateTime(2026, 10, 25, 9), 'debt:1'),
      (DateTime(2026, 10, 19, 9), 'debt:2'),
      (DateTime(2026, 10, 20, 9), 'debt:2'),
    ]);
    expect((plans[0].title, plans[0].body), ('Utang ke Kak Sinta', 'Jatuh tempo besok · sisa Rp200.000'));
    expect((plans[3].title, plans[3].body), ('Waktunya menagih Budi', 'Jatuh tempo hari ini · sisa pinjaman Rp200.000'));
  });

  test('id tidak bentrok dengan tagihan maupun notifikasi uji', () {
    final ids = [for (final p in planDebtReminders(debts, now, hour: 9)) p.id];
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(isDebugReminderId(id), isFalse);
      expect(billIdOfReminder(id), greaterThanOrEqualTo(500000));
    }
  });

  test('sinkron bersama tagihan; Pro saja; notifikasi tampil tetap ada sampai lunas', () async {
    final s = _Scheduler()..shown.addAll({debtReminderOwner(2), debtReminderOwner(1)});
    final n = await syncBillReminders(
        scheduler: s, bills: const [], settings: (enabled: true, hour: 9), isPro: true, now: now, debts: debts);
    expect(n, 4);
    expect(s.shown, {debtReminderOwner(2)}, reason: 'Budi (besok) sudah masuk masa pengingat, Kak Sinta belum');
    final paid = [debts[0], _debt(2, DebtDirection.piutang, 'Budi', 200000, DateTime(2026, 10, 20), paid: 200000)];
    await syncBillReminders(scheduler: s, bills: const [], settings: (enabled: true, hour: 9), isPro: true, now: now, debts: paid);
    expect(s.shown, isEmpty);
    expect(await syncBillReminders(scheduler: s, bills: const [], settings: (enabled: true, hour: 9), isPro: false, now: now, debts: debts), 0);
  });

  test('ketuk notifikasi utang → detail catatannya', () {
    expect(routeForNotification('debt:7'), '/utang?id=7');
    expect(routeForNotification('bill:3'), '/tagihan');
    expect(routeForNotification('lain'), isNull);
  });
}
