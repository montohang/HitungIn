import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/dev/sample_data.dart';
import 'package:hitungin/features/export/data/export_report.dart';
import 'package:hitungin/features/export/data/pdf_report.dart';
import 'package:hitungin/features/export/data/xlsx_export.dart';
import 'package:pdf/pdf.dart';

AppDatabase _db() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

ByteData _font(String name) => ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  final DateTime now = DateTime(2026, 10, 29, 14, 30);

  test('periode: bulan ini, bulan lalu, 3 bulan, tahun ini, semua, pilih sendiri; label & nama berkas', () {
    expect(exportRange(ExportPeriod.bulanIni, now), (from: DateTime(2026, 10), to: DateTime(2026, 11)));
    expect(exportRange(ExportPeriod.bulanLalu, now), (from: DateTime(2026, 9), to: DateTime(2026, 10)));
    expect(exportRange(ExportPeriod.tigaBulan, now), (from: DateTime(2026, 8), to: DateTime(2026, 11)));
    expect(exportRange(ExportPeriod.tahunIni, now).from, DateTime(2026));
    expect(exportRange(ExportPeriod.semua, now, firstData: DateTime(2026, 7, 14, 9)).from, DateTime(2026, 7, 14));
    final custom = (from: DateTime(2026, 10, 5), to: DateTime(2026, 10, 13));
    expect(exportRange(ExportPeriod.pilih, now, custom: custom), custom);
    expect(rangeLabel(exportRange(ExportPeriod.bulanIni, now), now), 'Oktober 2026');
    expect(rangeLabel(exportRange(ExportPeriod.tigaBulan, now), now), 'Agu – Okt 2026');
    expect(rangeLabel(custom, now), '5–12 Okt 2026');
    expect(exportFileName(ExportFormat.pdf, exportRange(ExportPeriod.bulanIni, now)), 'hitungin-laporan-2026-10.pdf');
    expect(exportFileName(ExportFormat.xlsx, exportRange(ExportPeriod.tigaBulan, now)), 'hitungin-2026-08_2026-10.xlsx');
    // Gratis: PDF bulan berjalan saja.
    expect(exportAllowedFree(ExportFormat.pdf, exportRange(ExportPeriod.bulanIni, now), now), isTrue);
    expect(exportAllowedFree(ExportFormat.pdf, exportRange(ExportPeriod.bulanLalu, now), now), isFalse);
    expect(exportAllowedFree(ExportFormat.xlsx, exportRange(ExportPeriod.bulanIni, now), now), isFalse);
  });

  test('ringkasan & per dompet: transfer/utang tidak dihitung; saldo akhir periode; filter dompet', () async {
    final db = _db();
    final tunai = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 100000);
    final bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
    final cats = await db.categoriesDao.active();
    int cat(String n, TxKind k) => cats.firstWhere((c) => c.name == n && c.kind == k).id;
    await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 5000000, walletId: bca, categoryId: cat('Gaji', TxKind.pemasukan), occurredAt: DateTime(2026, 10, 1, 9));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 50000, walletId: tunai, categoryId: cat('Makan & Minum', TxKind.pengeluaran), occurredAt: DateTime(2026, 10, 2, 12));
    await db.transactionsDao.add(kind: TxKind.transfer, amount: 200000, walletId: bca, toWalletId: tunai, occurredAt: DateTime(2026, 10, 3, 8));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 30000, walletId: tunai, categoryId: cat('Transportasi', TxKind.pengeluaran), occurredAt: DateTime(2026, 11, 2, 8));
    final x = await loadExportInput(db, range: exportRange(ExportPeriod.bulanIni, now), now: now);
    final s = summarize(x);
    expect((s.income, s.expense, s.net, s.count, s.topCategory), (5000000, 50000, 4950000, 3, 'Makan & Minum'));
    final w = {for (final r in perWallet(x)) r.wallet.name: r};
    expect((w['Tunai']!.balance, w['BCA']!.balance), (250000, 5800000));
    expect((w['BCA']!.transferOut, w['Tunai']!.transferIn), (200000, 200000));
    final onlyTunai = await loadExportInput(db, range: exportRange(ExportPeriod.bulanIni, now), now: now, walletId: tunai);
    expect((onlyTunai.txs.length, onlyTunai.walletLabel), (2, 'Tunai'));
    await db.close();
  });

  test('Excel: sheet yang ada datanya, nominal angka, baris judul dibekukan & filter otomatis', () async {
    final db = _db();
    await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 200000);
    await seedSampleData(db, now);
    await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 70000, walletId: 1, occurredAt: DateTime(2026, 10, 10));
    final x = await loadExportInput(db, range: exportRange(ExportPeriod.tigaBulan, now), now: now);
    final bytes = XlsxExport.build(x);
    final book = Excel.decodeBytes(bytes);
    expect(book.tables.keys, containsAll(['Ringkasan', 'Transaksi', 'Bulanan', 'Per kategori', 'Per dompet', 'Harian', 'Budget', 'Utang-piutang', 'Target tabungan']));
    expect(book.tables.keys, isNot(contains('Patungan')), reason: 'tanpa data → tidak dibuat');
    expect(book.tables.keys, isNot(contains('Sheet1')));
    expect(XlsxExport.sheetNames(x).first, 'Ringkasan');
    final tx = book.tables['Transaksi']!;
    expect(tx.row(0).first?.value.toString(), 'Tanggal');
    expect(tx.maxRows - 1, x.txs.length);
    final nominal = tx.row(1)[7]?.value;
    expect(nominal, isA<IntCellValue>(), reason: 'nominal angka, bukan teks');
    final zip = ZipDecoder().decodeBytes(bytes);
    final sheetXml = [
      for (final f in zip.files)
        if (f.name.startsWith('xl/worksheets/sheet')) utf8.decode(f.content as List<int>),
    ];
    expect(sheetXml.every((s) => s.contains('state="frozen"')), isTrue);
    expect(sheetXml.where((s) => s.contains('<autoFilter ref="A1:')).length, XlsxExport.sheetNames(x).length - 1,
        reason: 'semua sheet tabel (kecuali Ringkasan) diberi filter');
    await db.close();
  });

  test('PDF: dibuat dengan font aplikasi; lampiran menambah halaman', () async {
    final db = _db();
    await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 200000);
    await seedSampleData(db, now);
    final x = await loadExportInput(db, range: exportRange(ExportPeriod.bulanIni, now), now: now);
    final fonts = (regular: _font('PlusJakartaSans-Regular.ttf'), bold: _font('PlusJakartaSans-Bold.ttf'), display: _font('BricolageGrotesque-Bold.ttf'));
    final withAtt = await PdfReport.build(x, attachment: true, accent: const PdfColor.fromInt(0xFF5B4BDB), fonts: fonts);
    final without = await PdfReport.build(x, attachment: false, accent: const PdfColor.fromInt(0xFF5B4BDB), fonts: fonts);
    expect(ascii.decode(withAtt.sublist(0, 5)), '%PDF-');
    int pages(List<int> b) => RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(b)).length;
    expect(pages(without), 2, reason: 'ringkasan + posisi keuangan');
    expect(pages(withAtt), greaterThan(2));
    expect(PdfReport.rp(-1250000), '-Rp1.250.000');
    await db.close();
  });
}
