
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/backup/data/auto_backup.dart';
import 'package:hitungin/features/backup/data/backup_codec.dart';
import 'package:hitungin/features/backup/data/backup_service.dart';
import 'package:saf_folder/saf_folder.dart';

AppDatabase _db() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Folder di memori.
class _Folder implements SafFolder {
  final Map<String, Uint8List> files = {};
  bool access = true;
  String? failWrite;

  @override
  Future<bool> accessible(String tree) async => access;

  @override
  Future<List<SafFile>> list(String tree) async => [
        for (final e in files.entries) (doc: e.key, name: e.key, size: e.value.length),
      ];

  @override
  Future<void> write(String tree, String name, Uint8List bytes) async {
    if (failWrite != null) throw SafFolderException(failWrite!, null);
    files[name] = bytes;
  }

  @override
  Future<void> delete(String doc) async => files.remove(doc);

  @override
  Future<void> release(String tree) async {}

  @override
  Future<({String tree, String label})?> pick() async => null;
}

void main() {
  final DateTime start = DateTime(2026, 10, 1, 3);
  const String pw = 'sandi-uji-123';

  Future<({AppDatabase db, AutoBackupStore store, _Folder folder})> setup() async {
    final db = _db();
    await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 100000);
    final store = AutoBackupStore(MemorySecureStore());
    await store.enable(tree: 'tree', label: 'Documents/HitungIn', password: pw, now: start);
    return (db: db, store: store, folder: _Folder());
  }

  Future<AutoBackupOutcome> run(({AppDatabase db, AutoBackupStore store, _Folder folder}) e, DateTime now, {bool force = false}) =>
      runAutoBackup(db: e.db, store: e.store, folder: e.folder, now: now, force: force);

  test('salinan pertama bisa dibuka dengan password, status tercatat', () async {
    final e = await setup();
    expect(await run(e, start), AutoBackupOutcome.written);
    expect(e.folder.files.keys, ['hitungin-auto-2026-10-01.hitungin']);
    final data = await BackupCodec.decrypt(e.folder.files.values.first, pw);
    expect(BackupService(e.db).inspect(data).wallets, 1);
    final s = await e.store.read();
    expect((s.lastAt, s.lastCheckAt, s.error), (start, start, null));
    expect(s.lastSize, e.folder.files.values.first.length);
    await e.db.close();
  });

  test('data tidak berubah → tanpa salinan baru; berubah → salinan baru; catatan kekayaan tidak dihitung', () async {
    final e = await setup();
    await run(e, start);
    final next = start.add(const Duration(days: 1));
    await e.db.netWorthDao.saveSnapshot(start, assets: 1, liabilities: 0, now: start);
    await run(e, next);
    expect(e.folder.files.length, 2, reason: 'nilai catatan bulanan berubah');
    final day3 = start.add(const Duration(days: 2));
    await e.db.netWorthDao.saveSnapshot(start, assets: 1, liabilities: 0, now: day3);
    expect(await run(e, day3), AutoBackupOutcome.unchanged, reason: 'hanya jam catatan yang berubah');
    expect(e.folder.files.length, 2);
    expect((await e.store.read()).lastCheckAt, day3);
    await e.db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 5);
    expect(await run(e, start.add(const Duration(days: 3))), AutoBackupOutcome.written);
    expect(e.folder.files.length, 3);
    await e.db.close();
  });

  test('salinan hilang dari folder → dibuat lagi walau data sama', () async {
    final e = await setup();
    await run(e, start);
    e.folder.files.clear();
    expect(await run(e, start.add(const Duration(days: 1))), AutoBackupOutcome.written);
    await e.db.close();
  });

  test('rotasi menyisakan 7 salinan terbaru; backup manual & berkas lain tidak tersentuh', () async {
    final e = await setup();
    e.folder.files['hitungin-2026-09-01.hitungin'] = Uint8List(1);
    e.folder.files['catatan.txt'] = Uint8List(1);
    for (int i = 0; i < 9; i++) {
      await run(e, start.add(Duration(days: i)), force: true);
    }
    final names = e.folder.files.keys.toSet();
    expect(names, containsAll(['hitungin-2026-09-01.hitungin', 'catatan.txt']));
    expect(autoBackupFiles(names).length, 7);
    expect(names, isNot(contains('hitungin-auto-2026-10-01.hitungin')));
    expect(names, isNot(contains('hitungin-auto-2026-10-02.hitungin')));
    expect(names, contains('hitungin-auto-2026-10-09.hitungin'));
    await e.db.close();
  });

  test('gagal: salinan lama utuh, sebab tercatat; berhasil lagi → galat hilang', () async {
    final e = await setup();
    await run(e, start);
    final day2 = start.add(const Duration(days: 1));
    e.folder.access = false;
    expect(await run(e, day2, force: true), AutoBackupOutcome.failed);
    expect((await e.store.read()).error, AutoBackupError.folder);
    e.folder.access = true;
    e.folder.failWrite = 'no_space';
    expect(await run(e, day2, force: true), AutoBackupOutcome.failed);
    expect((await e.store.read()).error, AutoBackupError.space);
    expect(e.folder.files.length, 1);
    e.folder.failWrite = null;
    expect(await run(e, day2, force: true), AutoBackupOutcome.written);
    expect((await e.store.read()).error, isNull);
    await e.db.close();
  });

  test('mati → tidak berjalan; matikan menghapus password', () async {
    final e = await setup();
    await e.store.clear();
    expect(await e.store.password(), isNull);
    expect((await e.store.read()).enabled, isFalse);
    expect(await run(e, start), AutoBackupOutcome.off);
    expect(e.folder.files, isEmpty);
    await e.db.close();
  });

  test('waktu terlewat, kartu salinan & notifikasi', () {
    final s = AutoBackupState(enabled: true, enabledAt: start, lastCheckAt: start);
    expect(autoBackupNeedsCatchUp(s, start.add(const Duration(days: 3))), isFalse);
    expect(autoBackupNeedsCatchUp(s, start.add(const Duration(days: 4))), isTrue);
    expect(autoBackupNeedsCatchUp(const AutoBackupState(), start), isFalse);

    final d31 = start.add(const Duration(days: 31));
    expect(autoBackupCopyDue(s, null, start.add(const Duration(days: 30))), isFalse);
    expect(autoBackupCopyDue(s, null, d31), isTrue);
    expect(autoBackupCopyDue(s, d31, d31), isFalse, reason: 'baru backup manual');
    expect(autoBackupCopyDue(s.copyWith(copyDismissedAt: d31), null, d31.add(const Duration(days: 30))), isFalse);
    expect(autoBackupCopyDue(s.copyWith(copyDismissedAt: d31), null, d31.add(const Duration(days: 31))), isTrue);

    expect(autoBackupNotice(s, null, start), isNull, reason: 'lancar berarti diam');
    final bad = s.copyWith(error: AutoBackupError.folder);
    expect(autoBackupNotice(bad, null, start), AutoBackupNotice.failed);
    expect(autoBackupNotice(bad.copyWith(failNoticeAt: start), null, start.add(const Duration(hours: 5))), isNull);
    expect(autoBackupNotice(bad.copyWith(failNoticeAt: start), null, start.add(const Duration(days: 1))), AutoBackupNotice.failed);
    final d7 = start.add(const Duration(days: 7));
    expect(autoBackupNotice(s, null, d7), AutoBackupNotice.stalled);
    expect(autoBackupNotice(s.copyWith(stallNoticeAt: d7), null, d7.add(const Duration(days: 1))), isNull);
    final fresh = s.copyWith(lastCheckAt: d31);
    expect(autoBackupNotice(fresh, null, d31), AutoBackupNotice.copy);
    expect(autoBackupNotice(fresh.copyWith(copyNoticeAt: d31), null, d31), isNull);
  });
}
