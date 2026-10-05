import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';

import '../helpers/fakes.dart';

void main() {
  test('target berlaku mulai bulan diatur; bulan sebelumnya tetap target lama', () async {
    final env = TestEnv();
    final db = env.db;
    final int food = (await db.categoriesDao.active(kind: TxKind.pengeluaran)).first.id;
    Map<int?, int> at(List<Budget> l) => {for (final b in l) b.categoryId: b.limitAmount};

    await db.budgetsDao.saveAll(month: DateTime(2026, 9), total: 3000000, perCategory: {food: 500000});
    await db.budgetsDao.saveAll(month: DateTime(2026, 10), total: 4000000, perCategory: {food: 500000});

    expect(await db.budgetsDao.effective(DateTime(2026, 8)), isEmpty, reason: 'sebelum pertama diatur');
    expect(at(await db.budgetsDao.effective(DateTime(2026, 9))), {null: 3000000, food: 500000});
    expect(at(await db.budgetsDao.effective(DateTime(2026, 10))), {null: 4000000, food: 500000});
    expect(at(await db.budgetsDao.effective(DateTime(2027, 2))), {null: 4000000, food: 500000},
        reason: 'bulan baru mewarisi target terakhir');

    // Hapus kategori mulai November → Oktober tetap punya.
    await db.budgetsDao.saveAll(month: DateTime(2026, 11), total: 4000000, perCategory: {food: 0});
    expect(at(await db.budgetsDao.effective(DateTime(2026, 11))), {null: 4000000});
    expect(at(await db.budgetsDao.effective(DateTime(2026, 10))), {null: 4000000, food: 500000});

    // Mengubah bulan lama hanya berlaku sampai perubahan berikutnya.
    await db.budgetsDao.saveAll(month: DateTime(2026, 9), total: 3500000, perCategory: {food: 500000});
    expect(at(await db.budgetsDao.effective(DateTime(2026, 9))), {null: 3500000, food: 500000});
    expect(at(await db.budgetsDao.effective(DateTime(2026, 10))), {null: 4000000, food: 500000});

    // Nilai yang tidak berubah tidak menambah baris.
    final int rows = (await db.select(db.budgets).get()).length;
    await db.budgetsDao.saveAll(month: DateTime(2026, 12), total: 4000000, perCategory: {food: 0});
    expect((await db.select(db.budgets).get()).length, rows);

    // Progress bulanan memakai target bulan itu.
    final sep = await db.budgetsDao.watchProgress(DateTime(2026, 9)).first;
    expect(sep.firstWhere((b) => b.category == null).budget.limitAmount, 3500000);
    await db.close();
  });
}
