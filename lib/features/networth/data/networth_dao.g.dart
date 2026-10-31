// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'networth_dao.dart';

// ignore_for_file: type=lint
mixin _$NetWorthDaoMixin on DatabaseAccessor<AppDatabase> {
  $NetItemsTable get netItems => attachedDatabase.netItems;
  $NetSnapshotsTable get netSnapshots => attachedDatabase.netSnapshots;
  NetWorthDaoManager get managers => NetWorthDaoManager(this);
}

class NetWorthDaoManager {
  final _$NetWorthDaoMixin _db;
  NetWorthDaoManager(this._db);
  $$NetItemsTableTableManager get netItems =>
      $$NetItemsTableTableManager(_db.attachedDatabase, _db.netItems);
  $$NetSnapshotsTableTableManager get netSnapshots =>
      $$NetSnapshotsTableTableManager(_db.attachedDatabase, _db.netSnapshots);
}
