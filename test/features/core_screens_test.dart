import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('Catat cepat dari beranda → tersimpan & muncul di transaksi terbaru', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);

    expect(find.text('Belum ada transaksi'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('home-catat-cepat')), 'kopi 25rb gopay');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // Form terisi otomatis.
    expect(find.text('Catat'), findsOneWidget);
    expect(find.widgetWithText(TextField, '25.000'), findsOneWidget);
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    final txs = await app.run((db) => db.transactionsDao.watchRecent().first);
    expect(txs.single.tx.amount, 25000);
    expect(txs.single.tx.kind, TxKind.pengeluaran);
    expect(txs.single.category!.id, app.food());
    expect(txs.single.wallet.name, 'GoPay');
    expect((await app.balances())['GoPay'], 75000);
    await app.close(tester);
  });

  testWidgets('Catat manual: validasi lalu simpan pemasukan', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);

    await tester.tap(find.bySemanticsLabel('Catat transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pump();
    expect(find.text('Isi nominalnya dulu.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('nominal')), '9200000');
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pump();
    expect(find.text('Pilih kategori.'), findsOneWidget);

    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gaji'));
    await tester.tap(find.textContaining('BCA ·'));
    await tester.tap(find.text('Kemarin'));
    await tester.pump();
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pumpAndSettle();

    final tx = (await app.run((db) => db.transactionsDao.watchRecent().first)).single.tx;
    expect(tx.kind, TxKind.pemasukan);
    expect(tx.amount, 9200000);
    expect(tx.walletId, app.bca);
    expect(tx.occurredAt.day, 1);
    await app.close(tester);
  });

  testWidgets('Pindah saldo lewat Catat cepat', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);
    await app.go(tester, '/catat?text=tf%20bca%20ke%20gopay%20100rb');

    expect(find.text('Ke dompet'), findsOneWidget);
    await tester.tap(find.text('Simpan transaksi'));
    await tester.pumpAndSettle();

    final b = await app.balances();
    expect((b['BCA'], b['GoPay'], b['Tunai']), (900000, 200000, 50000));
    await app.close(tester);
  });

  testWidgets('Detail: ubah nominal lalu hapus', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    final id = await app.addTx(TxKind.pengeluaran, 30000, app.tunai, DateTime(2026, 10, 2, 7), category: app.food(), note: 'Bakso');
    await app.pump(tester);
    await tester.tap(find.text('Bakso'));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('−Rp30.000'), findsOneWidget);

    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah transaksi'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nominal')), '35000');
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('−Rp35.000'), findsOneWidget);
    expect((await app.run((db) => db.transactionsDao.byId(id)))!.amount, 35000);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Hapus')));
    await tester.pumpAndSettle();
    expect(await app.run((db) => db.transactionsDao.byId(id)), isNull);
    expect(find.text('Belum ada transaksi'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Riwayat: per bulan, filter jenis, dan pencarian', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 25000, app.gopay, DateTime(2026, 10, 2, 8), category: app.food(), note: 'Kopi');
    await app.addTx(TxKind.pengeluaran, 50000, app.tunai, DateTime(2026, 10, 1, 18), category: app.transport(), note: 'Bensin');
    await app.addTx(TxKind.pemasukan, 9200000, app.bca, DateTime(2026, 10, 1, 9), category: app.cat['Gaji/pemasukan']);
    await app.addTx(TxKind.pengeluaran, 70000, app.tunai, DateTime(2026, 9, 20), category: app.food(), note: 'Martabak');
    await app.pump(tester);
    await app.go(tester, '/riwayat');

    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Martabak'), findsNothing);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);

    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    expect(find.text('Kopi'), findsNothing);
    expect(find.text('Gaji'), findsOneWidget);

    await tester.tap(find.text('Semua'));
    await tester.enterText(find.byKey(const Key('cari')), 'bens');
    await tester.pumpAndSettle();
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Kopi'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Martabak'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Laporan: ringkasan, per kategori, dan lompat ke riwayat', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 300000, app.tunai, DateTime(2026, 10, 1), category: app.food());
    await app.addTx(TxKind.pengeluaran, 100000, app.tunai, DateTime(2026, 10, 2), category: app.transport(), note: 'Bensin');
    await app.addTx(TxKind.pemasukan, 9200000, app.bca, DateTime(2026, 10, 1), category: app.cat['Gaji/pemasukan']);
    await app.addTx(TxKind.pengeluaran, 200000, app.tunai, DateTime(2026, 9, 10), category: app.food());
    await app.pump(tester);
    await app.go(tester, '/laporan');

    expect(find.text('Rp9,2 jt'), findsOneWidget);
    expect(find.text('Rp400rb'), findsOneWidget);
    expect(find.text('▲ 100% vs Sep'), findsOneWidget);
    expect(find.text('+Rp8.800.000'), findsOneWidget);
    expect(find.text('Tertinggi 1 Okt · Rp300.000'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Transportasi'), 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    await tester.tap(find.text('Transportasi'));
    await tester.pumpAndSettle();

    // Riwayat terfilter kategori Transportasi.
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Makan & Minum'), findsNothing);
    await app.close(tester);
  });

  testWidgets('Budget: atur total & kategori, tanda lewat batas', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 120000, app.tunai, DateTime(2026, 10, 1), category: app.food());
    await app.pump(tester);
    await app.go(tester, '/budget');

    expect(find.text('Belum ada budget'), findsOneWidget);
    await tester.tap(find.text('Atur budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('batas-budget')), '3000000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Total pengeluaran'), findsOneWidget);
    expect(find.text('4%'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Total pengeluaran')), findsNothing,
        reason: 'budget total sudah ada');
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Makan & Minum')));
    await tester.enterText(find.byKey(const Key('batas-budget')), '100000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Lewat batas'), findsOneWidget);
    expect(find.text('Lewat Rp20.000'), findsOneWidget);
    expect(find.text('120%'), findsOneWidget);

    // Beranda menampilkan ringkasan budget total.
    await app.go(tester, '/home');
    expect(find.text('Budget bulan ini'), findsOneWidget);
    await app.close(tester);
  });
}
