import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/tables.dart';
import 'package:hitungin/features/home/data/allowance.dart';

UpcomingDue _due(String name, int amount, DateTime next, {BillRepeat repeat = BillRepeat.bulanan}) =>
    (name: name, amount: amount, next: next, repeat: repeat, anchorDay: next.day);

void main() {
  group('tanggal gajian berikutnya', () {
    test('sebelum tanggal gajian → bulan ini; pada/sesudahnya → bulan depan', () {
      expect(nextPaydayAfter(DateTime(2026, 10, 19), 25), DateTime(2026, 10, 25));
      expect(nextPaydayAfter(DateTime(2026, 10, 25), 25), DateTime(2026, 11, 25), reason: 'hari gajian memulai periode baru');
      expect(nextPaydayAfter(DateTime(2026, 10, 26), 25), DateTime(2026, 11, 25));
    });

    test('tanggal 31 di Februari → hari terakhir; tahun kabisat', () {
      expect(nextPaydayAfter(DateTime(2027, 2, 10), 31), DateTime(2027, 2, 28));
      expect(nextPaydayAfter(DateTime(2028, 2, 10), 30), DateTime(2028, 2, 29));
      expect(nextPaydayAfter(DateTime(2026, 12, 31), 31), DateTime(2027, 1, 31));
    });

    test('bawaan tanggal 1 = bulan kalender', () {
      expect(nextPaydayAfter(DateTime(2026, 10, 19), 1), DateTime(2026, 11, 1));
    });
  });

  group('jatah hari ini', () {
    final now = DateTime(2026, 10, 19, 8, 42);

    test('saldo − tagihan − berulang sampai gajian, dibagi sisa hari, dibulatkan ke ratusan', () {
      final a = computeAllowance(
        now: now,
        payday: 1,
        balance: 8450000,
        spentToday: 0,
        bills: [_due('Listrik PLN', 450000, DateTime(2026, 10, 21))],
        recurring: [_due('Spotify', 54990, DateTime(2026, 10, 25))],
      );
      expect((a.billsDue, a.recurringDue, a.daysToPayday), (450000, 54990, 13));
      expect(a.jatah, 611100, reason: '(8.450.000 − 450.000 − 54.990) ÷ 13 = 611.153 → 611.100');
      expect(a.state, AllowanceState.aman);
      expect(a.billNames, ['Listrik PLN']);
    });

    test('belanja hari ini tidak mengubah jatah, hanya sisanya', () {
      Allowance at(int spent) => computeAllowance(
          now: now, payday: 1, balance: 1300000 - spent, spentToday: spent, bills: const [], recurring: const []);
      expect(at(0).jatah, at(28000).jatah);
      expect(at(28000).remaining, at(0).jatah - 28000);
    });

    test('tagihan terlambat yang belum lunas tetap mengurangi; sesudah gajian tidak', () {
      final a = computeAllowance(
        now: now,
        payday: 1,
        balance: 1000000,
        spentToday: 0,
        bills: [_due('Kos', 500000, DateTime(2026, 10, 15)), _due('Netflix', 54000, DateTime(2026, 11, 2))],
        recurring: const [],
      );
      expect(a.billsDue, 500000);
    });

    test('pengeluaran berulang mingguan dihitung tiap kemunculan sampai gajian', () {
      final a = computeAllowance(
        now: now,
        payday: 1,
        balance: 1000000,
        spentToday: 0,
        bills: const [],
        recurring: [_due('Arisan', 50000, DateTime(2026, 10, 20), repeat: BillRepeat.mingguan)],
      );
      expect(a.recurringDue, 100000, reason: '20 & 27 Okt; 3 Nov sudah lewat periode');
    });

    test('budget total lebih kecil → jatah mengikuti budget', () {
      final a = computeAllowance(
        now: now,
        payday: 1,
        balance: 8450000,
        spentToday: 28000,
        bills: const [],
        recurring: const [],
        budgetLeft: 1080000,
      );
      expect(a.useBudget, isTrue);
      expect(a.daysLeftInMonth, 13);
      expect(a.jatah, 85200, reason: '(1.080.000 + 28.000) ÷ 13 = 85.230 → 85.200');
      expect(a.remaining, 57200);
    });

    test('keadaan: menipis, lewat (dengan jatah besok), habis, kosong', () {
      Allowance at({required int balance, required int spent, int bills = 0}) => computeAllowance(
            now: now,
            payday: 1,
            balance: balance,
            spentToday: spent,
            bills: bills == 0 ? const [] : [_due('Kos', bills, DateTime(2026, 10, 25))],
            recurring: const [],
          );
      // jatah = 1.300.000 ÷ 13 = 100.000
      expect(at(balance: 1300000 - 85000, spent: 85000).state, AllowanceState.menipis);
      final lewat = at(balance: 1300000 - 115000, spent: 115000);
      expect(lewat.state, AllowanceState.lewat);
      expect(lewat.remaining, -15000);
      expect(lewat.tomorrow, 98700, reason: '1.185.000 ÷ 12 = 98.750 → 98.700');
      expect(at(balance: 400000, spent: 0, bills: 500000).state, AllowanceState.habis);
      expect(at(balance: 0, spent: 0).state, AllowanceState.kosong);
    });

    test('hari terakhir periode: tidak ada jatah besok', () {
      final a = computeAllowance(
          now: DateTime(2026, 10, 31), payday: 1, balance: 50000, spentToday: 0, bills: const [], recurring: const []);
      expect((a.daysToPayday, a.jatah, a.tomorrow), (1, 50000, null));
    });
  });
}
