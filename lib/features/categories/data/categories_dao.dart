import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'categories_dao.g.dart';

/// Rapikan isian kata kunci: `"Kopi, nasi ,kopi"` → `"kopi,nasi"`.
String normalizeCategoryKeywords(String raw) => raw
    .split(RegExp(r'[,\n]'))
    .map((k) => k.trim().toLowerCase())
    .where((k) => k.isNotEmpty)
    .toSet()
    .join(',');

/// Sub-kategori dari isian bebas: dipisah koma/baris, dirapikan, tanpa duplikat (tak peka huruf besar).
String normalizeSubs(String raw) {
  final Set<String> seen = {};
  final List<String> out = [];
  for (final String part in raw.split(RegExp(r'[,\n]'))) {
    final String s = part.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty || !seen.add(s.toLowerCase())) continue;
    out.add(s[0].toUpperCase() + s.substring(1));
  }
  return out.join(',');
}

/// Daftar sub-kategori sebuah kategori.
List<String> subsOf(Category? c) =>
    c == null || c.subs.isEmpty ? const [] : [for (final s in c.subs.split(',')) if (s.trim().isNotEmpty) s.trim()];

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  SimpleSelectStatement<$CategoriesTable, Category> _active({TxKind? kind}) => select(categories)
    ..where((c) => c.archived.equals(false) & (kind == null ? const Constant(true) : c.kind.equalsValue(kind)))
    ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.id)]);

  Stream<List<Category>> watchActive({TxKind? kind}) => _active(kind: kind).watch();

  Future<List<Category>> active({TxKind? kind}) => _active(kind: kind).get();

  /// Untuk layar Kelola kategori: termasuk yang diarsipkan (di akhir).
  Stream<List<Category>> watchAll(TxKind kind) => (select(categories)
        ..where((c) => c.kind.equalsValue(kind))
        ..orderBy([
          (c) => OrderingTerm(expression: c.archived),
          (c) => OrderingTerm(expression: c.sortOrder),
          (c) => OrderingTerm(expression: c.id),
        ]))
      .watch();

  /// Semua kategori satu jenis, termasuk yang diarsipkan (cek nama kembar).
  Future<List<Category>> allOfKind(TxKind kind) => (select(categories)..where((c) => c.kind.equalsValue(kind))).get();

  Future<void> reorder(List<int> idsInOrder) => batch((b) {
        for (final (int i, int id) in idsInOrder.indexed) {
          b.update(categories, CategoriesCompanion(sortOrder: Value(i)), where: (c) => c.id.equals(id));
        }
      });

  /// Jumlah transaksi yang memakai kategori (untuk peringatan saat diarsipkan).
  Future<int> usage(int id) async {
    final Expression<int> count = attachedDatabase.transactions.id.count();
    return (selectOnly(attachedDatabase.transactions)
          ..addColumns([count])
          ..where(attachedDatabase.transactions.categoryId.equals(id)))
        .map((r) => r.read(count)!)
        .getSingle();
  }

  Future<int> add({
    required String name,
    required TxKind kind,
    String icon = 'other',
    String keywords = '',
    int color = 0,
    String subs = '',
  }) async {
    assert(kind != TxKind.transfer, 'Kategori hanya untuk pengeluaran/pemasukan');
    final Expression<int> max = categories.sortOrder.max();
    final int? current = await (selectOnly(categories)..addColumns([max])).map((r) => r.read(max)).getSingle();
    return into(categories).insert(CategoriesCompanion.insert(
      name: name.trim(),
      kind: kind,
      icon: Value(icon),
      keywords: Value(keywords),
      color: Value(color),
      subs: Value(subs),
      sortOrder: Value((current ?? -1) + 1),
    ));
  }

  Future<void> edit(Category category) => update(categories).replace(category);

  /// Kategori tidak dihapus supaya riwayat tetap utuh — cukup diarsipkan.
  Future<void> setArchived(int id, bool archived) =>
      (update(categories)..where((c) => c.id.equals(id))).write(CategoriesCompanion(archived: Value(archived)));
}
