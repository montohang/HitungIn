import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';

part 'budgets_dao.g.dart';

/// Budget beserta pemakaiannya di satu bulan. [category] kosong = budget total.
typedef BudgetProgress = ({Budget budget, Category? category, int spent});

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  /// Target yang berlaku di [month]: per kategori (null = total) baris dengan
  /// from_month terbesar ≤ bulan itu; batas 0 berarti dihapus → tidak tampil.
  static const String _effectiveWhere = '''
      b.from_month <= ?3
      AND b.from_month = (SELECT MAX(b2.from_month) FROM budgets b2
                          WHERE b2.from_month <= ?3 AND b2.category_id IS b.category_id)
      AND b.limit_amount > 0
  ''';

  Budget _budget(QueryRow row) => Budget(
        id: row.read<int>('b_id'),
        categoryId: row.readNullable<int>('b_category_id'),
        limitAmount: row.read<int>('b_limit_amount'),
        fromMonth: row.read<DateTime>('b_from_month'),
        createdAt: row.read<DateTime>('b_created_at'),
      );

  /// Budget total tampil paling atas, lalu urutan kategori.
  Stream<List<BudgetProgress>> watchProgress(DateTime month) {
    final (DateTime from, DateTime to) = Dates.monthRange(month);
    return customSelect(
      '''
      SELECT b.id AS b_id, b.category_id AS b_category_id, b.limit_amount AS b_limit_amount,
             b.from_month AS b_from_month, b.created_at AS b_created_at, c.*,
             COALESCE((
               SELECT SUM(t.amount) FROM transactions t
               WHERE t.kind = 'pengeluaran'
                 AND t.occurred_at >= ?1 AND t.occurred_at < ?2
                 AND (b.category_id IS NULL OR t.category_id = b.category_id)
             ), 0) AS spent
      FROM budgets b
      LEFT JOIN categories c ON c.id = b.category_id
      WHERE $_effectiveWhere
      ORDER BY b.category_id IS NOT NULL, c.sort_order, b.id
      ''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to), Variable.withDateTime(from)],
      readsFrom: {budgets, categories, transactions},
    ).watch().map((rows) => [
          for (final row in rows)
            (
              budget: _budget(row),
              category: row.readNullable<int>('b_category_id') == null ? null : categories.map(row.data),
              spent: row.read<int>('spent'),
            ),
        ]);
  }

  /// Target yang berlaku di [month] (untuk mengisi Atur budget).
  Future<List<Budget>> effective(DateTime month) {
    final Variable<DateTime> m = Variable.withDateTime(DateTime(month.year, month.month));
    return customSelect(
        '''
        SELECT b.id AS b_id, b.category_id AS b_category_id, b.limit_amount AS b_limit_amount,
               b.from_month AS b_from_month, b.created_at AS b_created_at
        FROM budgets b WHERE $_effectiveWhere
        ''',
        // ?1/?2 tidak dipakai; _effectiveWhere memakai ?3.
        variables: [m, m, m],
        readsFrom: {budgets},
      ).get().then((rows) => [for (final r in rows) _budget(r)]);
  }

  /// Membuat atau mengganti batas [categoryId] (null = total) mulai bulan
  /// [from] (default: berlaku sejak awal). 0 = tanpa budget mulai bulan itu.
  Future<void> setLimit({int? categoryId, required int limitAmount, DateTime? from}) => transaction(() async {
        final DateTime month = from == null ? DateTime(2000) : DateTime(from.year, from.month);
        final existing = await (select(budgets)
              ..where((b) =>
                  (categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId)) &
                  b.fromMonth.equals(month)))
            .getSingleOrNull();
        if (existing == null) {
          await into(budgets).insert(BudgetsCompanion.insert(
            categoryId: Value(categoryId),
            limitAmount: limitAmount,
            fromMonth: Value(month),
          ));
        } else {
          await (update(budgets)..where((b) => b.id.equals(existing.id)))
              .write(BudgetsCompanion(limitAmount: Value(limitAmount)));
        }
      });

  /// Simpan isian Atur budget untuk [month] dan bulan-bulan sesudahnya.
  /// Hanya nilai yang berubah dari target yang berlaku yang ditulis; 0 = hapus.
  Future<void> saveAll({required DateTime month, required int total, required Map<int, int> perCategory}) =>
      transaction(() async {
        final Map<int?, int> current = {for (final b in await effective(month)) b.categoryId: b.limitAmount};
        Future<void> put(int? categoryId, int amount) async {
          if ((current[categoryId] ?? 0) == amount) return;
          await setLimit(categoryId: categoryId, limitAmount: amount, from: month);
        }

        await put(null, total);
        for (final e in perCategory.entries) {
          await put(e.key, e.value);
        }
      });
}
