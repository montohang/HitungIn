import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';

part 'budgets_dao.g.dart';

/// Budget beserta pemakaiannya di satu bulan. [category] kosong = budget total.
typedef BudgetProgress = ({Budget budget, Category? category, int spent});

@DriftAccessor(tables: [Budgets, Categories, Transactions])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  /// Budget total tampil paling atas, lalu urutan kategori.
  Stream<List<BudgetProgress>> watchProgress(DateTime month) {
    final (DateTime from, DateTime to) = Dates.monthRange(month);
    return customSelect(
      '''
      SELECT b.id AS b_id, b.category_id AS b_category_id, b.limit_amount AS b_limit_amount,
             b.created_at AS b_created_at, c.*,
             COALESCE((
               SELECT SUM(t.amount) FROM transactions t
               WHERE t.kind = 'pengeluaran'
                 AND t.occurred_at >= ?1 AND t.occurred_at < ?2
                 AND (b.category_id IS NULL OR t.category_id = b.category_id)
             ), 0) AS spent
      FROM budgets b
      LEFT JOIN categories c ON c.id = b.category_id
      ORDER BY b.category_id IS NOT NULL, c.sort_order, b.id
      ''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {budgets, categories, transactions},
    ).watch().map((rows) => [
          for (final row in rows)
            (
              budget: Budget(
                id: row.read<int>('b_id'),
                categoryId: row.readNullable<int>('b_category_id'),
                limitAmount: row.read<int>('b_limit_amount'),
                createdAt: row.read<DateTime>('b_created_at'),
              ),
              category: row.readNullable<int>('b_category_id') == null ? null : categories.map(row.data),
              spent: row.read<int>('spent'),
            ),
        ]);
  }

  /// Membuat atau mengganti batas untuk [categoryId] (null = total).
  Future<void> setLimit({int? categoryId, required int limitAmount}) => transaction(() async {
        final existing = await (select(budgets)
              ..where((b) => categoryId == null ? b.categoryId.isNull() : b.categoryId.equals(categoryId)))
            .getSingleOrNull();
        if (existing == null) {
          await into(budgets).insert(BudgetsCompanion.insert(categoryId: Value(categoryId), limitAmount: limitAmount));
        } else {
          await (update(budgets)..where((b) => b.id.equals(existing.id)))
              .write(BudgetsCompanion(limitAmount: Value(limitAmount)));
        }
      });

  Future<void> remove(int id) => (delete(budgets)..where((b) => b.id.equals(id))).go();
}
