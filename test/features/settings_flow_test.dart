import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/branding/app_icon_variants.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';
import 'package:hitungin/features/security/pin_service.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

import '../helpers/app_harness.dart';

Finder _inSheet(Finder f) => find.descendant(of: find.byType(BottomSheet), matching: f);
Finder _inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);
Finder _field(String label) => find.widgetWithText(TextField, label);

/// Gulir di dalam lembar bawah sampai terlihat, lalu ketuk.
Future<void> _tapSheet(WidgetTester tester, String text) async {
  final Finder f = _inSheet(find.text(text));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.bySemanticsLabel(d).last);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tab Lainnya: ubah nama panggilan', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);

    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Belum diisi'), findsOneWidget);
    await app.tap('Nama panggilan');
    await tester.enterText(_inSheet(find.byType(TextField)), 'Rina');
    await _tapSheet(tester, 'Simpan');

    expect(find.text('Rina'), findsOneWidget);
    expect(await app.setting(SettingKeys.userName), 'Rina');
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rina', findRichText: true), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Dompet: tambah, arsipkan, dan tolak hapus dompet yang sudah dipakai', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 10000, app.tunai, DateTime(2026, 10, 1), category: app.food());
    await app.pump(tester);
    await app.push(tester, '/pengaturan/dompet');

    await app.tap('+ Tambah');
    await tester.enterText(_field('Nama dompet'), 'OVO');
    await tester.tap(_inSheet(find.text('E-wallet')));
    await tester.enterText(_field('Saldo awal'), '25000');
    await _tapSheet(tester, 'Simpan');
    expect(find.text('OVO'), findsOneWidget);
    expect(find.text('Rp25.000'), findsOneWidget);
    expect(find.text('E-wallet'), findsOneWidget, reason: 'grup E-wallet');

    // Sesuaikan saldo: isi saldo sekarang → saldo awal ikut menyesuaikan.
    await app.tap('OVO');
    await tester.enterText(_field('Saldo sekarang'), '30000');
    await _tapSheet(tester, 'Simpan');
    expect((await app.balances())['OVO'], 30000);

    // Nama kembar ditolak.
    await app.tap('+ Tambah');
    await tester.enterText(_field('Nama dompet'), 'ovo');
    await _tapSheet(tester, 'Simpan');
    expect(find.text('Nama dompet sudah dipakai.'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await app.tap('OVO');
    await _tapSheet(tester, 'Arsipkan');
    expect(find.text('Diarsipkan'), findsOneWidget);
    expect((await app.balances()).containsKey('OVO'), isFalse, reason: 'tidak ikut total');

    await app.tap('Tunai');
    await tester.tap(_inSheet(find.text('Hapus')));
    await tester.pumpAndSettle();
    await tester.tap(_inDialog(find.text('Hapus')));
    await tester.pumpAndSettle();
    expect(find.textContaining('sudah punya transaksi'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Kategori: kata kunci, warna & sub-kategori baru langsung dipakai Catat cepat; arsipkan', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/pengaturan/kategori');

    await app.tap('+ Baru');
    await tester.enterText(_field('Nama kategori'), 'Kucing');
    await tester.tap(find.bySemanticsLabel(RegExp('^Ikon fun')));
    await tester.tap(find.bySemanticsLabel('Warna Teal'));
    await tester.tap(find.bySemanticsLabel(RegExp('^Tambah sub-kategori')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sub-baru')), 'vaksin');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(_field('Kata kunci Catat cepat'), 'Whiskas, pasir ,whiskas');
    await _tapSheet(tester, 'Simpan');
    await app.scrollTo(find.text('Kucing'));
    final saved = (await app.run((db) => db.categoriesDao.active())).firstWhere((c) => c.name == 'Kucing');
    expect((saved.keywords, saved.icon, saved.color, saved.subs), ('whiskas,pasir', 'fun', 2, 'Vaksin'));
    expect(find.text('1 sub-kategori'), findsOneWidget);

    await app.push(tester, '/catat?text=whiskas%2050rb');
    await app.tap('Simpan · Rp50.000');
    final tx = (await app.run((db) => db.transactionsDao.watchRecent().first)).single;
    expect(tx.category!.name, 'Kucing');
    expect(tx.tx.amount, 50000);

    // Nama sub-kategori dikenali Catat cepat & tersimpan di transaksi.
    await app.push(tester, '/catat?text=vaksin%20150rb');
    await app.tap('Simpan · Rp150.000');
    // Saldo Tunai (Rp50.000, sudah terpakai) jadi minus → ditanya dulu, tidak diblokir.
    expect(find.text('Saldo Tunai jadi minus'), findsOneWidget);
    await app.tap('Tetap catat');
    final tx2 = (await app.run((db) => db.transactionsDao.watchRecent().first)).firstWhere((d) => d.tx.amount == 150000);
    expect((tx2.category!.name, tx2.tx.sub), ('Kucing', 'Vaksin'));

    await app.scrollTo(find.text('Kucing'));
    await app.tap('Kucing');
    await _tapSheet(tester, 'Arsipkan');
    await app.scrollTo(find.text('Diarsipkan'));
    expect(find.text('Diarsipkan'), findsOneWidget);
    expect((await app.run((db) => db.categoriesDao.active())).map((c) => c.name), isNot(contains('Kucing')));
    await app.close(tester);
  });

  testWidgets('Keamanan: ganti PIN (salah → benar → PIN baru) dan kunci otomatis', (tester) async {
    final app = AppHarness(tester, pin: true);
    await app.seed();
    await app.env.pin.setPin('258013');
    await app.pump(tester);
    await app.push(tester, '/pengaturan/keamanan');

    await app.tap('Setelah 5 menit');
    expect(await app.setting(SettingKeys.autoLock), 'menit5');
    expect(find.text('Tidak tersedia di HP ini'), findsOneWidget, reason: 'tanpa sensor sidik jari');

    await app.tap('Ganti PIN');
    await _enterPin(tester, '000000');
    expect(find.text('PIN salah. Sisa 4 percobaan.'), findsOneWidget);
    await _enterPin(tester, '258013');
    expect(find.text('PIN baru'), findsOneWidget);
    await _enterPin(tester, '258013');
    expect(find.text('PIN baru harus berbeda.'), findsOneWidget);
    await _enterPin(tester, '970412');
    expect(find.text('Ulangi PIN baru'), findsOneWidget);
    await _enterPin(tester, '970412');
    expect(find.text('PIN diganti'), findsOneWidget);
    expect(find.text('PIN & kunci'), findsOneWidget);
    expect(await app.env.pin.verify('970412'), isA<PinOk>());
    await app.close(tester);
  });

  testWidgets('Tema: aksen gratis tersimpan; aksen & ikon Pro mengarah ke layar Pro', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/pengaturan/tampilan');

    await tester.tap(find.bySemanticsLabel(RegExp('^Aksen Teal')));
    await tester.pumpAndSettle();
    expect(await app.setting(SettingKeys.themeAccent), 'teal');

    await tester.tap(find.bySemanticsLabel(RegExp('^Aksen Plum')));
    await tester.pumpAndSettle();
    expect(find.text(ProReason.tema.headline), findsOneWidget);
    expect(await app.setting(SettingKeys.themeAccent), 'teal');
    await app.back(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('^Ikon Emas')));
    await tester.pumpAndSettle();
    expect(find.text(ProReason.tema.headline), findsOneWidget);
    expect(app.env.appIcons.sets, isEmpty);
    await app.close(tester);
  });

  testWidgets('Tema (Pro): aksen Plum & ikon Emas bisa dipakai', (tester) async {
    final app = AppHarness(tester, pro: true);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/pengaturan/tampilan');

    await tester.tap(find.bySemanticsLabel(RegExp('^Aksen Plum')));
    await tester.pumpAndSettle();
    expect(await app.setting(SettingKeys.themeAccent), 'plum');

    await tester.tap(find.bySemanticsLabel(RegExp('^Ikon Emas')));
    await tester.pumpAndSettle();
    expect(app.env.appIcons.sets, [AppIconVariant.emas]);
    expect(find.textContaining('Ikon berganti setelah kamu keluar'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Cadangan: validasi kata sandi; CSV gratis ditawari Pro', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/pengaturan/cadangan');

    expect(find.text('Belum ada backup'), findsOneWidget);
    await app.tap('Backup sekarang');
    await tester.enterText(_field('Kata sandi'), 'pendek');
    await tester.enterText(_field('Ulangi kata sandi'), 'pendek');
    await tester.tap(_inSheet(find.text('Buat cadangan')));
    await tester.pumpAndSettle();
    expect(find.text('Minimal 8 karakter.'), findsOneWidget);
    await tester.enterText(_field('Kata sandi'), 'rahasia123');
    await tester.enterText(_field('Ulangi kata sandi'), 'rahasia124');
    await tester.tap(_inSheet(find.text('Buat cadangan')));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi tidak sama.'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await app.tap('Export CSV');
    expect(find.textContaining('Iklan sedang tidak tersedia'), findsOneWidget);
    await tester.tap(_inSheet(find.text('Lihat HitungIn Pro')));
    await tester.pumpAndSettle();
    expect(find.text(ProReason.csv.headline), findsWidgets);
    await app.close(tester);
  });
}
