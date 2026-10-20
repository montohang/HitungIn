import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/reminder_scheduler.dart';
import 'package:hitungin/features/goals/data/goal_reminders.dart';
import 'package:hitungin/features/goals/data/goals.dart';
import 'package:hitungin/features/goals/data/goals_dao.dart';
import 'package:hitungin/features/goals/goal_achieved_screen.dart';
import 'package:hitungin/features/goals/goals_screen.dart';
import 'package:hitungin/features/home/data/allowance.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';
import 'package:hitungin/features/transactions/quick_entry_parser.dart';

Wallet _w(int id, String name, WalletType type) => Wallet(
      id: id,
      name: name,
      type: type,
      initialBalance: 0,
      icon: 'wallet',
      color: 0,
      sortOrder: id,
      archived: false,
      createdAt: DateTime(2026),
    );

void main() {
  final DateTime now = DateTime(2026, 10, 20, 9);

  group('progres & tonggak', () {
    test('persen dibulatkan ke bawah, 0–100', () {
      expect(goalPercent(0, 1000000), 0);
      expect(goalPercent(640000, 1000000), 64);
      expect(goalPercent(999999, 1000000), 99, reason: 'belum 100% sebelum benar-benar tercapai');
      expect(goalPercent(1500000, 1000000), 100);
      expect(goalPercent(-5, 1000000), 0);
    });

    test('tonggak 25/50/75/100 hanya saat dilewati; yang tertinggi bila sekaligus', () {
      expect(goalMilestoneCrossed(before: 200000, after: 260000, target: 1000000), 25);
      expect(goalMilestoneCrossed(before: 260000, after: 300000, target: 1000000), isNull);
      expect(goalMilestoneCrossed(before: 100000, after: 800000, target: 1000000), 75);
      expect(goalMilestoneCrossed(before: 900000, after: 1000000, target: 1000000), 100);
      expect(goalMilestoneCrossed(before: 800000, after: 700000, target: 1000000), isNull);
    });
  });

  group('perkiraan tercapai', () {
    List<DepositFact> deps(List<(int, DateTime)> xs) => [for (final (a, d) in xs) (amount: a, walletId: 1, at: d)];

    test('dengan tanggal target: setoran per minggu, dibulatkan ke atas ke ribuan', () {
      // Sisa 4.750.000, 20 Okt → 31 Mar 2027 = 163 hari = 24 minggu.
      final e = goalEstimate(target: 6000000, saved: 1250000, dueDate: DateTime(2027, 3, 31), deposits: const [], now: now);
      expect(e, isA<GoalPerWeek>());
      expect((e as GoalPerWeek).perWeek, 198000);
      expect(goalEstimateText(e, now: now), 'Sisihkan Rp198rb per minggu supaya tercapai 31 Mar 2027');
    });

    test('tanggal target hari ini → seluruh sisa minggu ini; sudah lewat → terlambat', () {
      expect((goalEstimate(target: 1000000, saved: 400000, dueDate: now, deposits: const [], now: now) as GoalPerWeek).perWeek,
          600000);
      expect(goalEstimate(target: 1000000, saved: 400000, dueDate: DateTime(2026, 10, 19), deposits: const [], now: now),
          isA<GoalOverdue>());
    });

    test('tanpa tanggal: dari rata-rata setoran 60 hari terakhir (ambil ikut dikurangi)', () {
      final e = goalEstimate(
        target: 10000000,
        saved: 6400000,
        dueDate: null,
        deposits: deps([
          (5000000, DateTime(2026, 6, 1)), // di luar 60 hari
          (1000000, DateTime(2026, 9, 1)),
          (800000, DateTime(2026, 10, 1)),
          (-200000, DateTime(2026, 10, 10)),
        ]),
        now: now,
      );
      // Bersih 1,6 jt / 60 hari → sisa 3,6 jt butuh 135 hari → 4 Mar 2027.
      expect(e, isA<GoalEta>());
      expect(((e as GoalEta).eta, e.perMonth), (DateTime(2027, 3, 4), 800000));
      expect(goalEstimateText(e, now: now), 'Dengan kecepatan sekarang (Rp800rb/bln), tercapai sekitar Mar 2027');
    });

    test('tanpa tanggal & belum ada setoran → ajakan; sudah penuh → tercapai', () {
      expect(goalEstimate(target: 1000000, saved: 0, dueDate: null, deposits: const [], now: now), isA<GoalNoPace>());
      expect(goalEstimate(target: 1000000, saved: 1000000, dueDate: DateTime(2026, 1, 1), deposits: const [], now: now),
          isA<GoalDone>());
    });

    test('lama menabung: hari di bawah sebulan, lalu bulan', () {
      expect(goalDurationLabel(DateTime(2026, 10, 1), DateTime(2026, 10, 13)), '12 hari');
      expect(goalDurationLabel(DateTime(2026, 2, 10), DateTime(2026, 10, 20)), '8 bln');
      expect(goalDurationLabel(DateTime(2026, 10, 20), DateTime(2026, 10, 20)), '1 hari');
    });
  });

  group('disisihkan dari Jatah', () {
    test('hanya setoran dari dompet yang dihitung; per target tidak pernah negatif', () {
      final List<DepositFact> darurat = [(amount: 6400000, walletId: 9, at: now)]; // dompet tabungan, tidak dihitung
      final List<DepositFact> bali = [
        (amount: 1500000, walletId: 1, at: now),
        (amount: -250000, walletId: 1, at: now),
      ];
      final List<DepositFact> aneh = [(amount: -100000, walletId: 2, at: now)];
      expect(setAsideFrom([darurat, bali, aneh], {1, 2}), 1250000);
      expect(setAsideFrom([darurat], {1, 2}), 0);
    });

    test('Jatah: uang bebas berkurang sebesar yang disisihkan', () {
      Allowance a(int setAside) => computeAllowance(
            now: now,
            payday: 25,
            balance: 3000000,
            spentToday: 0,
            bills: const [],
            recurring: const [],
            setAside: setAside,
            setAsideNames: const ['Liburan Bali'],
          );
      // 25 Okt gajian → 5 hari.
      expect(a(0).jatah, 600000);
      expect(a(1000000).jatah, 400000);
      expect(a(1000000).free, 2000000);
      expect(a(3000000).state, AllowanceState.habis);
    });
  });

  group('GoalsDao', () {
    late AppDatabase db;
    late int bca;

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 2000000);
    });
    tearDown(() => db.close());

    Future<GoalWithDeposits> load(int id) async => (await db.goalsDao.byId(id))!;

    test('setor & ambil: terkumpul berubah, saldo dompet & transaksi tidak', () async {
      final id = await db.goalsDao.add(name: ' Dana darurat ', target: 1000000, emoji: '🛟');
      expect(await db.goalsDao.deposit(id, amount: 400000, at: now, walletId: bca), 400000);
      expect(await db.goalsDao.withdraw(id, amount: 150000, at: now, walletId: bca), 250000);
      final g = await load(id);
      expect((g.goal.name, g.saved, g.left, g.percent, g.active), ('Dana darurat', 250000, 750000, 25, true));
      expect((await db.walletsDao.watchBalances().first).single.balance, 2000000);
      expect(await db.transactionsDao.watchRecent().first, isEmpty);
      expect(() => db.goalsDao.withdraw(id, amount: 300000, at: now), throwsArgumentError);
      expect(() => db.goalsDao.deposit(id, amount: 0, at: now), throwsArgumentError);
    });

    test('tercapai dicatat sekali; dilepas bila setoran dihapus atau target dinaikkan', () async {
      final id = await db.goalsDao.add(name: 'HP baru', target: 500000);
      await db.goalsDao.deposit(id, amount: 300000, at: DateTime(2026, 10, 1), walletId: bca);
      final int last = (await load(id)).deposits.single.id;
      await db.goalsDao.deposit(id, amount: 200000, at: DateTime(2026, 10, 20), walletId: bca);
      GoalWithDeposits g = await load(id);
      expect((g.reached, g.active, g.goal.achievedAt), (true, false, DateTime(2026, 10, 20)));
      await db.goalsDao.deposit(id, amount: 50000, at: DateTime(2026, 10, 25), walletId: bca);
      expect((await load(id)).goal.achievedAt, DateTime(2026, 10, 20), reason: 'tanggal tercapai pertama dipertahankan');

      await db.goalsDao.removeDeposit(last);
      g = await load(id);
      expect(g.saved, 250000);
      expect(g.goal.achievedAt, isNull);

      await db.goalsDao.deposit(id, amount: 250000, at: DateTime(2026, 10, 26), walletId: bca);
      await db.goalsDao.edit((await load(id)).goal.copyWith(target: 900000));
      expect((await load(id)).goal.achievedAt, isNull);
    });

    test('arsip & hapus: hapus target ikut menghapus setorannya; dompet dihapus → setoran tetap', () async {
      final id = await db.goalsDao.add(name: 'Nikah', target: 50000000);
      await db.goalsDao.deposit(id, amount: 1000000, at: now, walletId: bca);
      await db.goalsDao.setArchived(id, true);
      expect((await load(id)).active, isFalse);

      final gopay = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet);
      final other = await db.goalsDao.add(name: 'Laptop', target: 9000000);
      await db.goalsDao.deposit(other, amount: 100000, at: now, walletId: gopay);
      await db.goalsDao.remove(id);
      expect(await db.goalsDao.byId(id), isNull);
      expect((await db.select(db.goalDeposits).get()).map((d) => d.goalId), [other]);
    });

    test('pengingat bawaan mati; bisa dinyalakan dengan hari & jam', () async {
      final id = await db.goalsDao.add(name: 'Liburan', target: 6000000);
      expect(((await load(id)).goal.remind, (await load(id)).goal.remindWeekday, (await load(id)).goal.remindHour),
          (false, 1, 19));
      await db.goalsDao.setReminder(id, on: true, weekday: 5, hour: 21);
      final Goal g = (await load(id)).goal;
      expect((g.remind, g.remindWeekday, g.remindHour), (true, 5, 21));
    });
  });

  group('pengingat setoran mingguan', () {
    GoalWithDeposits g(int id, {bool remind = true, int weekday = 1, int hour = 19, bool archived = false, int saved = 0}) => (
          goal: Goal(
            id: id,
            name: 'Liburan',
            emoji: '🏝️',
            target: 1000000,
            note: '',
            archived: archived,
            remind: remind,
            remindWeekday: weekday,
            remindHour: hour,
            achievedAt: saved >= 1000000 ? now : null,
            createdAt: DateTime(2026, 9),
          ),
          deposits: [
            if (saved > 0) GoalDeposit(id: 1, goalId: id, amount: saved, walletId: 1, at: now, createdAt: now),
          ],
        );

    test('hari & jam pilihan berikutnya; mati / arsip / tercapai dilewati', () {
      // 20 Okt 2026 = Selasa 09.00.
      final plans = planGoalReminders([
        g(1, weekday: 1),
        g(2, weekday: 2, hour: 19, saved: 400000),
        g(3, weekday: 2, hour: 8),
        g(4, remind: false),
        g(5, archived: true),
        g(6, saved: 1000000),
      ], now);
      expect([for (final p in plans) (p.id ~/ 4, p.at)], [
        (goalReminderOwner(1), DateTime(2026, 10, 26, 19)),
        (goalReminderOwner(2), DateTime(2026, 10, 20, 19)),
        (goalReminderOwner(3), DateTime(2026, 10, 27, 8)),
      ]);
      expect(plans[1].title, 'Waktunya menyisihkan untuk Liburan 🏝️');
      expect(plans[1].body, 'Sudah 40% · kurang Rp600.000 lagi.');
      expect(plans[1].payload, 'goal:2');
    });

    test('ketuk notifikasi → detail target', () {
      expect(routeForNotification('goal:7'), '/target/7');
      expect(routeForNotification('goal:x'), '/target');
    });
  });

  group('Catat cepat & batas gratis', () {
    final parser = QuickEntryParser(wallets: [_w(1, 'Tunai', WalletType.tunai), _w(2, 'GoPay', WalletType.ewallet)], categories: const []);

    test('"nabung 100rb dana darurat" → setoran target, dompet ikut terbaca', () {
      final e = parser.parse('nabung 100rb dana darurat', now: now);
      expect((e.goal, e.amount, e.walletId), ('dana darurat', 100000, null));
      final f = parser.parse('setor 250rb ke liburan bali dari gopay', now: now);
      expect((f.goal, f.amount, f.walletId), ('liburan bali', 250000, 2));
      expect(parser.parse('nabung 50rb', now: now).goal, '');
      expect(parser.parse('kopi 25rb gopay', now: now).goal, isNull);
    });

    test('target dicari dari nama yang disebut; kosong + satu target aktif → target itu', () {
      GoalWithDeposits mk(int id, String name, {bool archived = false}) => (
            goal: Goal(
              id: id,
              name: name,
              emoji: '🎯',
              target: 1000000,
              note: '',
              archived: archived,
              remind: false,
              remindWeekday: 1,
              remindHour: 19,
              createdAt: now,
            ),
            deposits: const <GoalDeposit>[],
          );
      final all = [mk(1, 'Dana darurat'), mk(2, 'Liburan Bali'), mk(3, 'Nikah', archived: true)];
      expect(findGoal(all, 'dana darurat')?.goal.id, 1);
      expect(findGoal(all, 'bali')?.goal.id, 2);
      expect(findGoal(all, 'nikah'), isNull, reason: 'target arsip tidak menerima setoran cepat');
      expect(findGoal(all, ''), isNull);
      expect(findGoal([all.first], '')?.goal.id, 1);
      final draft = goalDraftFrom(Uri.parse(goalDraftLink((name: 'dana darurat', amount: 100000, walletId: 2))).queryParameters);
      expect(draft, (name: 'dana darurat', amount: 100000, walletId: 2));
    });

    test('versi gratis 1 target aktif; Pro tanpa batas', () {
      expect(FreeLimits.canAddGoal(active: 0, isPro: false), isTrue);
      expect(FreeLimits.canAddGoal(active: 1, isPro: false), isFalse);
      expect(FreeLimits.canAddGoal(active: 5, isPro: true), isTrue);
    });
  });
}
