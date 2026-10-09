import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/backup/data/backup_codec.dart';
import 'package:hitungin/features/backup/data/backup_service.dart';
import 'package:hitungin/features/backup/data/csv_export.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

AppDatabase _db() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Isi contoh: 2 dompet, transaksi biasa + transfer, budget, tagihan, pengaturan.
Future<void> _seed(AppDatabase db) async {
  final bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
  final gopay = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet);
  final food = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
  await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 25000, walletId: gopay, categoryId: food, note: 'Kopi', occurredAt: DateTime(2026, 10, 2, 8, 42));
  await db.transactionsDao.add(kind: TxKind.transfer, amount: 200000, walletId: bca, toWalletId: gopay, occurredAt: DateTime(2026, 10, 1));
  await db.budgetsDao.setLimit(categoryId: food, limitAmount: 500000);
  await db.billsDao.add(name: 'Kos', amount: 1500000, dueDate: DateTime(2026, 10, 31), repeat: BillRepeat.bulanan, walletId: bca);
  await db.settingsDao.write(SettingKeys.userName, 'Rina');
  await db.settingsDao.write(SettingKeys.onboardingDone, 'true');
  await db.recurringDao.add(kind: TxKind.pengeluaran, amount: 54000, walletId: gopay, categoryId: food, note: 'Langganan', repeat: BillRepeat.bulanan, firstRun: DateTime(2026, 11, 2));
}

void main() {
  group('BackupCodec', () {
    final data = <String, Object?>{'app': 'HitungIn', 'n': 42, 'teks': 'Kopi ☕ Rp25.000'};

    test('enkripsi → dekripsi kembali utuh', () async {
      final bytes = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      expect(ascii.decode(bytes.sublist(0, 12)), 'HITUNGIN-BAK');
      expect(utf8.decode(bytes, allowMalformed: true), isNot(contains('Kopi')), reason: 'isi tidak boleh terbaca');
      expect(await BackupCodec.decrypt(bytes, 'rahasia123'), data);
    });

    test('garam & nonce acak: dua enkripsi berbeda', () async {
      final a = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      final b = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      expect(a, isNot(b));
    });

    test('kata sandi salah ditolak', () async {
      final bytes = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      expect(() => BackupCodec.decrypt(bytes, 'rahasia124'), throwsA(isA<BackupPasswordException>()));
    });

    test('isi atau header yang diubah ditolak', () async {
      final bytes = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      final body = Uint8List.fromList(bytes)..[bytes.length - 20] ^= 1;
      expect(() => BackupCodec.decrypt(body, 'rahasia123'), throwsA(isA<BackupPasswordException>()));
      final salt = Uint8List.fromList(bytes)..[20] ^= 1;
      expect(() => BackupCodec.decrypt(salt, 'rahasia123'), throwsA(isA<BackupPasswordException>()));
    });

    test('bukan berkas cadangan / versi lebih baru', () async {
      expect(() => BackupCodec.decrypt(Uint8List.fromList(utf8.encode('halo dunia, ini bukan cadangan sama sekali ya')), 'x'),
          throwsA(isA<BackupFormatException>()));
      final bytes = await BackupCodec.encrypt(data, 'rahasia123', iterations: 1000);
      final future = Uint8List.fromList(bytes)..[12] = 99;
      expect(() => BackupCodec.decrypt(future, 'rahasia123'), throwsA(isA<BackupFormatException>()));
    });
  });

  group('BackupService', () {
    test('cadangkan → pulihkan ke HP lain: semua data & saldo sama', () async {
      final source = _db();
      await _seed(source);
      final snap = await BackupService(source, clock: () => DateTime(2026, 10, 4, 13)).snapshot();
      // Lewat JSON + enkripsi, persis seperti berkas sungguhan.
      final restored = await BackupCodec.decrypt(await BackupCodec.encrypt(snap, 'rahasia123', iterations: 1000), 'rahasia123');

      final target = _db();
      await target.walletsDao.add(name: 'Akan hilang', type: WalletType.tunai, initialBalance: 5);
      await target.settingsDao.write(SettingKeys.onboardingDone, 'true');
      final service = BackupService(target);

      final s = service.inspect(restored);
      expect((s.wallets, s.transactions, s.budgets, s.bills, s.recurring), (2, 2, 1, 1, 1));
      expect(s.createdAt, DateTime(2026, 10, 4, 13));

      await service.restore(restored);
      final balances = {for (final b in await target.walletsDao.watchBalances().first) b.wallet.name: b.balance};
      expect(balances, {'BCA': 800000, 'GoPay': 175000});
      final txs = await target.transactionsDao.watchBetween(DateTime(2026, 10), DateTime(2026, 11)).first;
      expect(txs.map((d) => d.tx.note), containsAll(['Kopi', '']));
      expect(txs.firstWhere((d) => d.tx.note == 'Kopi').category!.name, 'Makan & Minum');
      expect((await target.budgetsDao.watchProgress(DateTime(2026, 10)).first).single.spent, 25000);
      final bill = (await target.billsDao.watchActive().first).single;
      expect((bill.name, bill.anchorDay, bill.repeat), ('Kos', 31, BillRepeat.bulanan));
      expect(await target.settingsDao.read(SettingKeys.userName), 'Rina');
      final rec = (await target.recurringDao.watchAll().first).single;
      expect((rec.note, rec.nextRun, rec.anchorDay), ('Langganan', DateTime(2026, 11, 2), 2));
      expect(await target.settingsDao.read(SettingKeys.onboardingDone), 'true', reason: 'status perangkat tetap');
      expect(await target.settingsDao.read(SettingKeys.lastBackupAt), DateTime(2026, 10, 4, 13).toIso8601String(),
          reason: 'data = isi cadangan itu, jadi Beranda tidak menulis "belum ada backup"');

      // Data baru setelah pulih tetap bisa ditambah (id tidak bentrok).
      await target.walletsDao.add(name: 'OVO', type: WalletType.ewallet);
      await source.close();
      await target.close();
    });

    test('verifikasi sebelum disimpan: berkas cocok lolos, tidak cocok ditolak', () async {
      final db = _db();
      await _seed(db);
      final service = BackupService(db);
      final snap = await service.snapshot();
      final bytes = await BackupCodec.encrypt(snap, 'rahasia123', iterations: 1000);
      await service.verifyEncrypted(bytes, 'rahasia123', snap);

      final other = await service.snapshot();
      ((other['tables']! as Map)['transactions']! as List).clear();
      await expectLater(service.verifyEncrypted(bytes, 'rahasia123', other), throwsFormatException);
      await db.close();
    });

    test('cadangan lama (v1, tanpa transaksi berulang) tetap bisa dipulihkan', () async {
      final db = _db();
      await _seed(db);
      final snap = await BackupService(db).snapshot();
      final tables = Map<String, Object?>.from(snap['tables']! as Map)..remove('recurring');
      final target = _db();
      await BackupService(target).restore({...snap, 'schemaVersion': 1, 'tables': tables});
      expect(await target.walletsDao.active(), hasLength(2));
      expect(await target.recurringDao.watchAll().first, isEmpty);
      await db.close();
      await target.close();
    });

    test('status onboarding tidak ikut dicadangkan', () async {
      final db = _db();
      await _seed(db);
      final snap = await BackupService(db).snapshot();
      final settings = (snap['tables']! as Map)['settings'] as List;
      expect(settings.map((s) => (s as Map)['key']), isNot(contains(SettingKeys.onboardingDone)));
      await db.close();
    });

    test('cadangan asing / versi lebih baru ditolak tanpa mengubah data', () async {
      final db = _db();
      await _seed(db);
      final service = BackupService(db);
      expect(() => service.restore({'app': 'Lain', 'format': 1}), throwsFormatException);
      final snap = await service.snapshot();
      expect(() => service.restore({...snap, 'schemaVersion': 999}), throwsFormatException);
      expect(await db.walletsDao.active(), hasLength(2));
      await db.close();
    });

    test('baris rusak → pemulihan dibatalkan seluruhnya', () async {
      final db = _db();
      await _seed(db);
      final snap = await BackupService(db).snapshot();
      final tables = Map<String, Object?>.from(snap['tables']! as Map);
      // Transaksi menunjuk dompet yang tidak ada → foreign key gagal.
      final txs = [for (final t in tables['transactions']! as List) Map<String, Object?>.from(t as Map)];
      txs.first['walletId'] = 999;
      tables['transactions'] = txs;

      final other = _db();
      await other.walletsDao.add(name: 'Tetap ada', type: WalletType.tunai);
      await expectLater(BackupService(other).restore({...snap, 'tables': tables}), throwsA(anything));
      expect((await other.walletsDao.active()).single.name, 'Tetap ada');
      await db.close();
      await other.close();
    });
  });

  group('CsvExport', () {
    test('kolom, tanda nominal, dan escape', () async {
      final db = _db();
      await _seed(db);
      final food = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
      final gopay = (await db.walletsDao.active()).firstWhere((w) => w.name == 'GoPay').id;
      await db.transactionsDao.add(
          kind: TxKind.pengeluaran, amount: 50000, walletId: gopay, categoryId: food, note: 'Makan "enak", berdua', occurredAt: DateTime(2026, 10, 3, 19, 5));
      await db.transactionsDao.add(
          kind: TxKind.pengeluaran, amount: 1000, walletId: gopay, categoryId: food, note: '=SUM(A1)', occurredAt: DateTime(2026, 10, 3, 20));
      final items = await db.transactionsDao.watchBetween(DateTime(2026, 10), DateTime(2026, 11)).first;

      final lines = CsvExport.build(items).trim().split('\n');
      expect(lines.first, 'Tanggal,Jam,Jenis,Kategori,Dompet,Ke dompet,Nominal,Catatan');
      expect(lines, contains('2026-10-03,19:05,Pengeluaran,Makan & Minum,GoPay,,-50000,"Makan ""enak"", berdua"'));
      expect(lines, contains("2026-10-03,20:00,Pengeluaran,Makan & Minum,GoPay,,-1000,'=SUM(A1)"));
      expect(lines, contains('2026-10-01,00:00,Transfer,,BCA,GoPay,200000,'));
      expect(CsvExport.bytes(items).sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      await db.close();
    });
  });
}
