import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/default_data.dart';
import 'package:hitungin/core/db/providers.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';
import 'package:hitungin/features/scan/data/receipt_parser.dart';
import 'package:hitungin/features/scan/receipt_ocr.dart';
import 'package:hitungin/features/scan/scan_screen.dart';
import 'package:hitungin/features/scan/widgets/scan_intro_card.dart';

Wallet _w(int id, String name, WalletType type) => Wallet(
      id: id, name: name, type: type, initialBalance: 0, icon: 'wallet', color: 0, sortOrder: id, archived: false, createdAt: DateTime(2026));

void main() {
  test('kuota gratis 3 scan per bulan; reset otomatis saat ganti bulan; Pro tanpa batas', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final DateTime oct = DateTime(2026, 10, 21);
    expect(await scansUsed(db.settingsDao, oct), 0);
    for (int i = 0; i < 3; i++) {
      await countScan(db.settingsDao, oct);
    }
    expect(await scansUsed(db.settingsDao, oct), 3);
    expect(FreeLimits.canScanReceipt(usedThisMonth: 3, isPro: false), isFalse);
    expect(FreeLimits.canScanReceipt(usedThisMonth: 2, isPro: false), isTrue);
    expect(FreeLimits.canScanReceipt(usedThisMonth: 99, isPro: true), isTrue);
    expect(await scansUsed(db.settingsDao, DateTime(2026, 11, 1)), 0, reason: 'bulan baru');
    await countScan(db.settingsDao, DateTime(2026, 11, 1));
    expect(await scansUsed(db.settingsDao, DateTime(2026, 11, 2)), 1);
    await db.close();
  });

  test('dompet ditebak dari cara bayar, kategori dari nama toko/item', () {
    final wallets = [_w(1, 'Tunai', WalletType.tunai), _w(2, 'GoPay', WalletType.ewallet), _w(3, 'BCA', WalletType.bank)];
    final categories = [
      for (final (int i, (String name, TxKind kind, String icon, String keywords)) in defaultCategories.indexed)
        Category(id: i + 1, name: name, kind: kind, icon: icon, keywords: keywords, color: 0, subs: '', sortOrder: i, archived: false),
    ];
    String? cat(int? id) => categories.where((c) => c.id == id).firstOrNull?.name;
    final mini = guessFromReceipt(const ReceiptScan(merchant: 'Indomaret', payment: 'GOPAY'), wallets, categories);
    expect((mini.walletId, cat(mini.categoryId)), (2, 'Belanja'));
    final resto = guessFromReceipt(
        const ReceiptScan(merchant: 'Solaria', payment: 'BCA', items: [ReceiptItem(name: 'Nasi Goreng Spesial', qty: 1, price: 48000)]),
        wallets,
        categories);
    expect((resto.walletId, cat(resto.categoryId)), (3, 'Makan & Minum'));
    final qris = guessFromReceipt(const ReceiptScan(merchant: 'Toko Abc', payment: 'QRIS'), wallets, categories);
    expect(qris.walletId, isNull, reason: 'QRIS bukan dompet');
  });

  test('sisa pemilih gambar & pemindai dihapus; folder lain di cache (share, file_picker) tidak disentuh', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('hitungin_scan_');
    final Directory picked = await Directory('${tmp.path}/3f25223e-915c-4399-a78e-2764a872e056').create();
    await File('${picked.path}/1000060957.png').writeAsBytes([1, 2, 3]);
    await File('${tmp.path}/5675890d-988a-4073-a53d-6573025168e37093235097738630678.jpg').create();
    final Directory scanner = await Directory('${tmp.path}/mlkit_docscan_ui_client').create();
    await File('${scanner.path}/page_0.jpg').writeAsBytes([1]);
    await Directory('${tmp.path}/share').create();
    await File('${tmp.path}/share/rekap.png').writeAsBytes([1]);
    await purgePickerTemp(tmp);
    final List<String> left = [for (final e in tmp.listSync(recursive: true)) e.path.substring(tmp.path.length + 1)]..sort();
    expect(left, ['mlkit_docscan_ui_client', 'share', 'share/rekap.png']);
    await tmp.delete(recursive: true);
  });

  test('kartu kenalan scan: tampil sampai ditutup/dicoba, lalu hilang permanen; rute langsung ke scan', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final sub = container.listen(scanIntroDoneProvider, (_, __) {});
    expect(await container.read(scanIntroDoneProvider.future), isFalse);
    await markScanIntroDone(db.settingsDao);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(scanIntroDoneProvider).value, isTrue);
    expect(receiptScanRoute, '/catat?scan=1');
    sub.close();
    container.dispose();
    await db.close();
  });
}
