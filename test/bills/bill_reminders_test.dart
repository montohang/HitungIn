import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/data/bill_reminders.dart';
import 'package:hitungin/features/bills/reminder_scheduler.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';

Bill _bill(int id, DateTime due, {int remind = 3, bool active = true, int amount = 450000, String name = 'Listrik PLN'}) => Bill(
      id: id,
      name: name,
      amount: amount,
      nextDue: due,
      repeat: BillRepeat.bulanan,
      anchorDay: due.day,
      remindDaysBefore: remind,
      active: active,
      createdAt: DateTime(2026),
    );

class _RecordingScheduler implements ReminderScheduler {
  int cancels = 0;
  final List<ReminderPlan> scheduled = [];

  @override
  Future<void> init({required void Function(String payload) onTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> cancelAll() async {
    cancels++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(List<ReminderPlan> plans) async => scheduled.addAll(plans);
}

void main() {
  final now = DateTime(2026, 10, 4, 10, 0);

  group('rencana pengingat', () {
    test('H-3 dan hari H pada jam pilihan, isi jelas', () {
      final plans = planBillReminders([_bill(7, DateTime(2026, 10, 21))], now, hour: 9);
      expect(plans, hasLength(2));
      expect(plans[0].at, DateTime(2026, 10, 18, 9));
      expect(plans[0].title, 'Tagihan: Listrik PLN');
      expect(plans[0].body, 'Jatuh tempo 3 hari lagi · Rp450.000');
      expect(plans[1].at, DateTime(2026, 10, 21, 9));
      expect(plans[1].body, 'Jatuh tempo hari ini · Rp450.000');
      expect({plans[0].id, plans[1].id}, {reminderId(7, 0), reminderId(7, 1)});
    });

    test('H-1 berbunyi "besok"; remind 0 → hanya hari H', () {
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 10), remind: 1)], now, hour: 9).first.body, startsWith('Jatuh tempo besok'));
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 10), remind: 0)], now, hour: 9), hasLength(1));
    });

    test('waktu yang sudah lewat dilewati; tagihan terlambat tidak dinotifikasi', () {
      // H-3 = 3 Okt (lewat), hari H = 6 Okt.
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 6))], now, hour: 9).single.at, DateTime(2026, 10, 6, 9));
      // Jatuh tempo hari ini jam 9, sekarang 10.00 → sudah lewat.
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 4))], now, hour: 9), isEmpty);
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 1))], now, hour: 9), isEmpty);
      // Jam 19 hari ini masih akan datang.
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 4))], now, hour: 19), hasLength(1));
    });

    test('tagihan nonaktif diabaikan; urut waktu; dibatasi jumlahnya', () {
      expect(planBillReminders([_bill(1, DateTime(2026, 10, 20), active: false)], now, hour: 9), isEmpty);
      final plans = planBillReminders([_bill(1, DateTime(2026, 12, 1)), _bill(2, DateTime(2026, 10, 9))], now, hour: 9);
      expect([for (final p in plans) p.billId], [2, 2, 1, 1]);
      final many = [for (int i = 1; i <= 100; i++) _bill(i, DateTime(2026, 11, 1 + i % 28))];
      expect(planBillReminders(many, now, hour: 9), hasLength(maxScheduledReminders));
    });

    test('ID unik antar tagihan', () {
      final ids = {for (int b = 1; b < 200; b++) for (int s = 0; s < 2; s++) reminderId(b, s)};
      expect(ids, hasLength(398));
    });
  });

  group('pengaturan pengingat', () {
    late AppDatabase db;
    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    test('default aktif jam 09.00; tersimpan & terbaca lagi; nilai rusak → default', () async {
      expect(await loadReminderSettings(db.settingsDao), (enabled: true, hour: 9));
      await saveReminderSettings(db.settingsDao, (enabled: false, hour: 19));
      expect(await loadReminderSettings(db.settingsDao), (enabled: false, hour: 19));
      await db.settingsDao.write('bills.reminderHour', '99');
      expect((await loadReminderSettings(db.settingsDao)).hour, 9);
    });
  });

  group('sinkronisasi', () {
    final bills = [_bill(1, DateTime(2026, 10, 21)), _bill(2, DateTime(2026, 11, 1), remind: 0)];

    test('Pro + aktif → jadwal lama dibatalkan lalu dijadwalkan ulang', () async {
      final s = _RecordingScheduler();
      final n = await syncBillReminders(scheduler: s, bills: bills, settings: (enabled: true, hour: 7), isPro: true, now: now);
      expect(n, 3);
      expect(s.cancels, 1);
      expect(s.scheduled.map((p) => p.at.hour).toSet(), {7});
      // Dipanggil lagi (mis. tagihan dibayar) → tidak dobel.
      await syncBillReminders(scheduler: s, bills: bills.sublist(1), settings: (enabled: true, hour: 7), isPro: true, now: now);
      expect(s.scheduled, hasLength(1));
    });

    test('dimatikan atau bukan Pro → semua notifikasi dibatalkan', () async {
      final s = _RecordingScheduler();
      await syncBillReminders(scheduler: s, bills: bills, settings: (enabled: true, hour: 9), isPro: true, now: now);
      expect(await syncBillReminders(scheduler: s, bills: bills, settings: (enabled: false, hour: 9), isPro: true, now: now), 0);
      expect(s.scheduled, isEmpty);
      await syncBillReminders(scheduler: s, bills: bills, settings: (enabled: true, hour: 9), isPro: true, now: now);
      expect(await syncBillReminders(scheduler: s, bills: bills, settings: (enabled: true, hour: 9), isPro: false, now: now), 0);
      expect(s.scheduled, isEmpty);
    });

    test('notifikasi = fitur Pro', () {
      expect(FreeLimits.canUseBillNotifications(isPro: false), isFalse);
      expect(FreeLimits.canUseBillNotifications(isPro: true), isTrue);
    });
  });
}
