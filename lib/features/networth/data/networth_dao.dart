import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'networth_dao.g.dart';

/// Aset/kewajiban manual & catatan bulanan Kekayaan bersih (P3h).
@DriftAccessor(tables: [NetItems, NetSnapshots])
class NetWorthDao extends DatabaseAccessor<AppDatabase> with _$NetWorthDaoMixin {
  NetWorthDao(super.attachedDatabase);

  Stream<List<NetItem>> watchItems() =>
      (select(netItems)..orderBy([(i) => OrderingTerm.asc(i.kind), (i) => OrderingTerm.asc(i.id)])).watch();

  Future<List<NetItem>> items() => (select(netItems)..orderBy([(i) => OrderingTerm.asc(i.id)])).get();

  /// Tambah aset/kewajiban. Emas: [milligrams] × [pricePerGram]; lainnya [value].
  Future<int> add({
    required NetItemKind kind,
    required String name,
    int value = 0,
    int? milligrams,
    int? pricePerGram,
    required DateTime now,
  }) {
    _check(name);
    return into(netItems).insert(NetItemsCompanion.insert(
      kind: kind,
      name: name.trim(),
      value: Value(value),
      milligrams: Value(milligrams),
      pricePerGram: Value(pricePerGram),
      updatedAt: now,
    ));
  }

  /// Perbarui nilai/harga/nama; [updatedAt] ikut maju.
  Future<void> edit(NetItem item, {required DateTime now}) {
    _check(item.name);
    return update(netItems).replace(item.copyWith(name: item.name.trim(), updatedAt: now));
  }

  Future<void> remove(int id) => (delete(netItems)..where((i) => i.id.equals(id))).go();

  static void _check(String name) {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name', 'Nama wajib diisi');
  }

  /// Simpan kondisi bulan [month] (ditimpa bila sudah ada).
  Future<void> saveSnapshot(DateTime month, {required int assets, required int liabilities, required DateTime now}) =>
      into(netSnapshots).insertOnConflictUpdate(NetSnapshotsCompanion.insert(
        month: DateTime(month.year, month.month),
        assets: assets,
        liabilities: liabilities,
        updatedAt: now,
      ));

  Stream<List<NetSnapshot>> watchSnapshots() =>
      (select(netSnapshots)..orderBy([(s) => OrderingTerm.asc(s.month)])).watch();

  Future<List<NetSnapshot>> snapshots() => (select(netSnapshots)..orderBy([(s) => OrderingTerm.asc(s.month)])).get();
}
