import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/export/data/export_report.dart';
import 'package:hitungin/features/export/data/xlsx_export.dart';
import 'package:hitungin/features/networth/data/net_worth.dart';
import 'package:hitungin/features/networth/networth_provider.dart';

AppDatabase _db() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  final DateTime now = DateTime(2026, 10, 29, 14, 30);

  test('gram: tulis & baca dengan koma; nilai emas = berat × harga per gram', () {
    expect(parseGrams('10,5'), 10500);
    expect(parseGrams('2.25'), 2250);
    expect(parseGrams('abc'), isNull);
    expect(formatGrams(10500), '10,5');
    expect(formatGrams(10000), '10');
  });

  Future<NetWorth> compute(AppDatabase db, {required bool manual}) async => computeNetWorth(
        wallets: await db.walletsDao.watchBalances().first,
        debts: await db.debtsDao.watchAll().first,
        bills: await db.billsDao.watchActive().first,
        items: await db.netWorthDao.items(),
        includeManual: manual,
      );

  Future<AppDatabase> seeded() async {
    final db = _db();
    await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 1000000);
    await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 70000, occurredAt: DateTime(2026, 10, 10));
    await db.debtsDao.add(direction: DebtDirection.utang, name: 'Sari', amount: 50000, occurredAt: DateTime(2026, 10, 11));
    await db.billsDao.add(
        name: 'Cicilan HP', amount: 650000, dueDate: DateTime(2026, 11, 12), repeat: BillRepeat.bulanan, installmentTotal: 12, installmentPaid: 10);
    await db.netWorthDao.add(kind: NetItemKind.emas, name: 'Emas', milligrams: 10500, pricePerGram: 1350000, now: DateTime(2026, 9, 20));
    await db.netWorthDao.add(kind: NetItemKind.properti, name: 'Motor', value: 12000000, now: now);
    await db.netWorthDao.add(kind: NetItemKind.pinjaman, name: 'KTA Bank', value: 2000000, now: now);
    return db;
  }

  test('otomatis: dompet, piutang, utang, sisa cicilan; manual hanya bila Pro', () async {
    final db = await seeded();
    final free = await compute(db, manual: false);
    expect([for (final l in free.assets) l.name], ['Dompet', 'Piutang']);
    expect([for (final l in free.liabilities) (l.name, l.value)], [('Utang ke Sari', 50000), ('Cicilan HP', 1300000)]);
    expect(free.assets.every((l) => l.item == null), isTrue, reason: 'versi gratis: komponen otomatis saja');

    final pro = await compute(db, manual: true);
    final Map<String, int> v = {for (final l in [...pro.assets, ...pro.liabilities]) l.name: l.value};
    expect((v['Emas'], v['Motor'], v['KTA Bank']), (14175000, 12000000, 2000000));
    expect(pro.totalLiabilities, 3350000);
    expect(pro.net, free.net + 14175000 + 12000000 - 2000000);
    expect(pro.composition.keys, containsAll([NetGroup.dompet, NetGroup.emas, NetGroup.properti]));
    final NetItem gold = (await db.netWorthDao.items()).first;
    expect(netItemStale(gold, now), isTrue, reason: 'lebih dari 30 hari belum diperbarui');
    expect(netItemHint(gold, now), '10,5 g × Rp1.350.000 · diperbarui 39 hari lalu');
    await db.netWorthDao.edit(gold.copyWith(pricePerGram: const Value(1400000)), now: now);
    expect(netItemStale((await db.netWorthDao.items()).first, now), isFalse);
    await db.close();
  });

  test('urutan jenis mengikuti bawaan; lewat 30 hari dihitung per tanggal seperti keterangannya', () async {
    final db = _db();
    await db.netWorthDao.add(kind: NetItemKind.lainnya, name: 'Jam', value: 1, now: now);
    await db.netWorthDao.add(kind: NetItemKind.properti, name: 'Motor', value: 1, now: now);
    await db.netWorthDao.add(kind: NetItemKind.investasi, name: 'RDPU', value: 1, now: now);
    final w = await compute(db, manual: true);
    expect([for (final l in w.assets.skip(1)) l.name], ['RDPU', 'Motor', 'Jam']);
    expect(w.composition.keys.toList(), [NetGroup.investasi, NetGroup.properti, NetGroup.lainnya]);
    final NetItem i = (await db.netWorthDao.items()).first;
    final DateTime updated = DateTime(2026, 10, 31, 14, 47);
    final NetItem old = i.copyWith(updatedAt: updated);
    expect(netItemStale(old, DateTime(2026, 11, 30, 23)), isFalse, reason: '30 hari belum lewat');
    expect(netItemStale(old, DateTime(2026, 12, 1)), isTrue, reason: 'tertulis 31 hari lalu');
    expect(netItemHint(old, DateTime(2026, 12, 1)), contains('31 hari lalu'));
    await db.close();
  });

  test('catatan bulanan ditimpa dalam bulan yang sama; selisih dari bulan lalu', () async {
    final db = await seeded();
    final w = await compute(db, manual: true);
    await recordNetSnapshot(db, w, DateTime(2026, 9, 30, 20));
    await db.netWorthDao.saveSnapshot(DateTime(2026, 9, 30), assets: 10000000, liabilities: 1000000, now: DateTime(2026, 9, 30, 21));
    await recordNetSnapshot(db, w, now);
    await recordNetSnapshot(db, w, now.add(const Duration(hours: 1)));
    final snaps = await db.netWorthDao.snapshots();
    expect([for (final s in snaps) s.month], [DateTime(2026, 9), DateTime(2026, 10)]);
    expect(netWorthDelta(snaps, w, now), w.net - 9000000);
    expect(netWorthDelta([], w, now), isNull);
    await db.close();
  });

  test('export: sheet Kekayaan bersih (semua dompet saja), manual mengikuti Pro', () async {
    final db = await seeded();
    final range = exportRange(ExportPeriod.bulanIni, now);
    final x = await loadExportInput(db, range: range, now: now);
    expect(XlsxExport.sheetNames(x), contains('Kekayaan bersih'));
    final sheet = Excel.decodeBytes(XlsxExport.build(x)).tables['Kekayaan bersih']!;
    expect(sheet.row(0).first?.value.toString(), 'Jenis');
    final List<String> hints = [for (int r = 1; r < sheet.maxRows; r++) '${sheet.row(r)[2]?.value}'];
    expect(hints, contains(startsWith('10,5 g × Rp1.350.000')), reason: 'keterangan emas sama dengan di layar');
    expect(sheet.maxRows, 1 + x.netWorth!.assets.length + x.netWorth!.liabilities.length + 1);
    expect(XlsxExport.sheetNames(x), isNot(contains('Tren kekayaan')), reason: 'belum ada catatan');
    await db.netWorthDao.saveSnapshot(DateTime(2026, 9), assets: 10, liabilities: 3, now: now);
    final withTrend = await loadExportInput(db, range: range, now: now);
    final trend = Excel.decodeBytes(XlsxExport.build(withTrend)).tables['Tren kekayaan']!;
    expect(trend.row(1).first?.value.toString(), '2026-09');
    expect(trend.row(1)[3]?.value, isA<IntCellValue>());
    final free = await loadExportInput(db, range: range, now: now, includeManualNet: false);
    expect(free.netWorth!.assets.any((l) => l.item != null), isFalse);
    final oneWallet = await loadExportInput(db, range: range, now: now, walletId: 1);
    expect(oneWallet.netWorth, isNull);
    await db.close();
  });
}
