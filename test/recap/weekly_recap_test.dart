import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/tables.dart';
import 'package:hitungin/features/recap/data/recap_reminders.dart';
import 'package:hitungin/features/recap/data/weekly_recap.dart';

RecapTx _tx(TxKind k, int amount, DateTime at, [String cat = 'Makan']) =>
    (kind: k, amount: amount, at: at, categoryId: null, category: cat);

void main() {
  final mon = DateTime(2026, 10, 12); // Senin

  test('awal minggu = Senin, juga melewati pergantian bulan', () {
    expect(weekStart(DateTime(2026, 10, 18, 23)), mon);
    expect(weekStart(mon), mon);
    expect(weekStart(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('rekap hanya pemasukan/pengeluaran; pindah saldo & utang tidak dihitung', () {
    final r = computeWeeklyRecap(start: mon, loggedDays: {mon, DateTime(2026, 10, 17)}, txs: [
      _tx(TxKind.pengeluaran, 50000, DateTime(2026, 10, 12, 9)),
      _tx(TxKind.pengeluaran, 120000, DateTime(2026, 10, 17, 9), 'Belanja'),
      _tx(TxKind.pemasukan, 900000, DateTime(2026, 10, 15)),
      _tx(TxKind.transfer, 500000, DateTime(2026, 10, 13)),
      _tx(TxKind.utangKeluar, 200000, DateTime(2026, 10, 14)),
      _tx(TxKind.pengeluaran, 300000, DateTime(2026, 10, 6), 'Belanja'), // minggu sebelumnya
      _tx(TxKind.pengeluaran, 999000, DateTime(2026, 10, 19)), // minggu berikutnya
    ]);
    expect((r.out, r.income, r.prevOut, r.saved, r.daysLogged), (170000, 900000, 300000, 130000, 2));
    expect(r.perDay, [50000, 0, 0, 0, 0, 120000, 0]);
    expect((r.topDay, r.topCategories.first.name), (5, 'Belanja'));
    expect(r.insight, 'Belanja turun 60% dari minggu lalu. Pertahankan!');
  });

  test('insight: naik tajam, lalu hari paling boros; minggu kosong tanpa insight', () {
    final up = computeWeeklyRecap(start: mon, loggedDays: const {}, txs: [
      _tx(TxKind.pengeluaran, 100000, DateTime(2026, 10, 5), 'Kopi'),
      _tx(TxKind.pengeluaran, 150000, DateTime(2026, 10, 13), 'Kopi'),
    ]);
    expect(up.insight, 'Kopi naik 50% dari minggu lalu.');
    final day = computeWeeklyRecap(start: mon, loggedDays: const {}, txs: [_tx(TxKind.pengeluaran, 20000, DateTime(2026, 10, 16))]);
    expect(day.insight, 'Pengeluaran paling banyak di hari Jumat.');
    expect(computeWeeklyRecap(start: mon, loggedDays: const {}, txs: const []).insight, isNull);
  });

  group('streak', () {
    Set<DateTime> days(List<int> octDays) => {for (final d in octDays) DateTime(2026, 10, d)};

    test('berturut-turut; hari ini belum dicatat tidak memutus', () {
      final s = computeStreak(days([15, 16, 17, 18]), DateTime(2026, 10, 19, 10));
      expect((s.current, s.best), (4, 4));
      expect(computeStreak(days([15, 16, 17, 18, 19]), DateTime(2026, 10, 19, 10)).current, 5);
    });

    test('hari santai: satu hari kosong per minggu tidak memutus, dua memutus', () {
      final s = computeStreak(days([12, 13, 15, 16, 17, 18]), DateTime(2026, 10, 18, 21));
      expect(s.current, 6);
      expect(s.restDays, {DateTime(2026, 10, 14)});
      final broken = computeStreak(days([12, 15, 16, 17, 18]), DateTime(2026, 10, 18, 21));
      expect(broken.current, 4, reason: '13 & 14 kosong di minggu yang sama');
    });

    test('melewati pergantian bulan; rekor tetap tersimpan setelah putus', () {
      final logged = {
        for (int i = 0; i < 10; i++) DateTime(2026, 9, 25 + i), // 25 Sep – 4 Okt
        DateTime(2026, 10, 18), DateTime(2026, 10, 19),
      };
      final s = computeStreak(logged, DateTime(2026, 10, 19, 9));
      expect((s.current, s.best), (2, 10));
    });

    test('belum pernah mencatat → 0', () {
      expect(computeStreak(const {}, DateTime(2026, 10, 19)).current, 0);
    });
  });

  group('notifikasi rekap', () {
    test('Senin berikutnya 08.00; pengingat malam hanya bila streak ≥ 3 & belum mencatat', () {
      final p = planRecapReminders(now: DateTime(2026, 10, 15, 9), weekly: true, evening: true, streak: 4, loggedToday: false);
      expect([for (final x in p) x.at], [DateTime(2026, 10, 19, 8), DateTime(2026, 10, 15, 20)]);
      expect(p.first.payload, 'recap:week');
      expect(planRecapReminders(now: DateTime(2026, 10, 19, 9), weekly: true, evening: false, streak: 0, loggedToday: false).single.at,
          DateTime(2026, 10, 26, 8), reason: 'Senin lewat jam 8 → minggu depan');
      expect(planRecapReminders(now: DateTime(2026, 10, 15, 9), weekly: false, evening: true, streak: 2, loggedToday: false), isEmpty);
      expect(planRecapReminders(now: DateTime(2026, 10, 15, 9), weekly: false, evening: true, streak: 5, loggedToday: true), isEmpty);
    });
  });
}
