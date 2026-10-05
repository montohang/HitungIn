import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/backup/data/backup_age.dart';
import 'package:hitungin/features/budget/data/budget_insights.dart';
import 'package:hitungin/features/budget/data/budgets_dao.dart';
import 'package:hitungin/features/transactions/data/transactions_dao.dart' show monthlyAverages;

BudgetProgress _b(int limit, int spent, {String? category}) => (
      budget: Budget(id: 1, categoryId: category == null ? null : 1, limitAmount: limit, createdAt: DateTime(2026)),
      category: category == null
          ? null
          : Category(
              id: 1, name: category, kind: TxKind.pengeluaran, icon: 'x', keywords: '', sortOrder: 0, archived: false),
      spent: spent,
    );

void main() {
  final DateTime oct19 = DateTime(2026, 10, 19, 14);

  group('budgetOverview', () {
    test('kosong → null', () => expect(budgetOverview(const []), isNull));

    test('pakai budget total bila ada', () {
      final o = budgetOverview([_b(500000, 450000, category: 'Makan'), _b(3000000, 1200000)])!;
      expect((o.limit, o.spent, o.fromTotal), (3000000, 1200000, true));
    });

    test('tanpa total → jumlah budget kategori', () {
      final o = budgetOverview([_b(500000, 450000, category: 'Makan'), _b(300000, 100000, category: 'Transportasi')])!;
      expect((o.limit, o.spent, o.fromTotal), (800000, 550000, false));
    });
  });

  test('hari berjalan & tersisa', () {
    expect(monthElapsed(oct19), closeTo(19 / 31, 1e-9));
    expect(daysLeftInMonth(oct19), 12);
    expect(daysLeftInMonth(DateTime(2026, 10, 31)), 0);
  });

  group('hottestCategory', () {
    test('ambil yang ≥ 80% dan lebih cepat dari waktu berjalan; abaikan budget total', () {
      final hot = hottestCategory([
        _b(1000000, 950000), // total, diabaikan
        _b(500000, 410000, category: 'Makan & Minum'), // 82%
        _b(200000, 180000, category: 'Hiburan'), // 90%
        _b(300000, 100000, category: 'Transportasi'),
      ], oct19);
      expect(hot!.category!.name, 'Hiburan');
    });

    test('aman bila pemakaian di bawah 80% atau sejalan dengan waktu', () {
      expect(hottestCategory([_b(500000, 300000, category: 'Makan')], oct19), isNull);
      // Hari terakhir: 90% < 100% waktu berjalan → masih aman.
      expect(hottestCategory([_b(500000, 450000, category: 'Makan')], DateTime(2026, 10, 31)), isNull);
    });
  });

  test('safeDailySpend membagi sisa ke hari tersisa', () {
    expect(safeDailySpend(_b(500000, 250000, category: 'Makan'), oct19), 250000 ~/ 12);
    expect(safeDailySpend(_b(500000, 600000, category: 'Makan'), oct19), 0);
    expect(safeDailySpend(_b(500000, 400000, category: 'Makan'), DateTime(2026, 10, 31)), 100000);
  });

  test('shortCategoryName', () {
    expect(shortCategoryName('Makan & Minum'), 'Makan');
    expect(shortCategoryName('Transportasi'), 'Transportasi');
  });

  group('backupAge', () {
    final DateTime now = DateTime(2026, 10, 19, 9);
    test('belum pernah', () => expect(backupAge(null, now), (label: 'belum ada backup', fresh: false)));
    test('hari ini / kemarin / N hari', () {
      expect(backupAge(DateTime(2026, 10, 19, 1), now), (label: 'hari ini', fresh: true));
      expect(backupAge(DateTime(2026, 10, 18, 23), now), (label: 'kemarin', fresh: true));
      expect(backupAge(DateTime(2026, 10, 5), now), (label: '14 hari lalu', fresh: true));
      expect(backupAge(DateTime(2026, 10, 4), now), (label: '15 hari lalu', fresh: false));
    });
    test('lebih dari sebulan', () {
      expect(backupAge(DateTime(2026, 8, 1), now), (label: 'lebih dari sebulan lalu', fresh: false));
    });
  });

  test('saran batas dibulatkan ke atas per 50rb', () {
    expect(suggestLimit(0), 0);
    expect(suggestLimit(1), 50000);
    expect(suggestLimit(1250000), 1250000);
    expect(suggestLimit(1260000), 1300000);
  });

  test('status pembagian total', () {
    String f(int v) => 'Rp$v';
    expect(allocationStatus(100, 100, f), 'Semua terbagi');
    expect(allocationStatus(100, 60, f), 'Sisa Rp40');
    expect(allocationStatus(100, 130, f), 'Lebih Rp30');
  });

  test('rata-rata bulanan dibagi jumlah bulan yang ada datanya', () {
    expect(monthlyAverages(const []), isEmpty);
    final avg = monthlyAverages([
      (categoryId: 1, amount: 300000, at: DateTime(2026, 8, 3)),
      (categoryId: 1, amount: 100000, at: DateTime(2026, 9, 3)),
      (categoryId: 2, amount: 50000, at: DateTime(2026, 9, 9)),
    ]);
    expect(avg, {1: 200000, 2: 25000});
  });
}
