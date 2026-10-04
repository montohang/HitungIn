import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  SimpleSelectStatement<$CategoriesTable, Category> _active({TxKind? kind}) => select(categories)
    ..where((c) => c.archived.equals(false) & (kind == null ? const Constant(true) : c.kind.equalsValue(kind)))
    ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.id)]);

  Stream<List<Category>> watchActive({TxKind? kind}) => _active(kind: kind).watch();

  Future<List<Category>> active({TxKind? kind}) => _active(kind: kind).get();

  Future<int> add({required String name, required TxKind kind, String icon = 'other', String keywords = ''}) async {
    assert(kind != TxKind.transfer, 'Kategori hanya untuk pengeluaran/pemasukan');
    final Expression<int> max = categories.sortOrder.max();
    final int? current = await (selectOnly(categories)..addColumns([max])).map((r) => r.read(max)).getSingle();
    return into(categories).insert(CategoriesCompanion.insert(
      name: name.trim(),
      kind: kind,
      icon: Value(icon),
      keywords: Value(keywords),
      sortOrder: Value((current ?? -1) + 1),
    ));
  }

  Future<void> edit(Category category) => update(categories).replace(category);

  /// Kategori tidak dihapus supaya riwayat tetap utuh — cukup diarsipkan.
  Future<void> setArchived(int id, bool archived) =>
      (update(categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(archived: Value(archived)));
}
