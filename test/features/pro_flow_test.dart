import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/widgets/app_chip.dart';
import 'package:hitungin/features/premium/data/billing.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../helpers/app_harness.dart';

Finder _inSheet(Finder f) => find.descendant(of: find.byType(BottomSheet), matching: f);
Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _tapSheet(WidgetTester tester, String text, {bool chip = false}) async {
  final Finder f = _inSheet(chip ? find.widgetWithText(AppChip, text) : find.text(text));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

PurchaseDetails _purchase(PurchaseStatus status) => PurchaseDetails(
      purchaseID: 'GPA.1',
      productID: proProductId,
      verificationData: PurchaseVerificationData(localVerificationData: '{}', serverVerificationData: 't', source: 'google_play'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = status != PurchaseStatus.pending;

void main() {
  testWidgets('Layar Pro: beli → menunggu pembayaran → lunas → Pro aktif di Pengaturan', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/premium?from=iklan');

    expect(find.text(ProReason.iklan.headline), findsWidgets);
    expect(find.text('Beli Pro · Rp59.000'), findsOneWidget);
    expect(find.text('Segera'), findsNothing, reason: 'semua manfaat sudah tersedia');
    await app.tap('Beli Pro · Rp59.000');
    expect(app.env.billing.buys, 1);
    expect(find.text('Membuka Google Play…'), findsOneWidget);

    app.env.billing.emit([_purchase(PurchaseStatus.pending)]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Menunggu pembayaran selesai'), findsOneWidget);

    app.env.billing.emit([_purchase(PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();
    expect(find.text('Terima kasih sudah mendukung HitungIn!'), findsOneWidget);
    expect(find.textContaining('Beli Pro'), findsNothing);
    expect(app.env.billing.completed, hasLength(1));

    // Google Play kini mencatat pembelian ini sebagai milik akun.
    app.env.billing.ownedResult = (purchased: {proProductId}, pending: <String>{});
    final int restoresBefore = app.env.billing.restores;
    await app.tap('Pulihkan pembelian');
    expect(app.env.billing.restores, restoresBefore + 1);

    await app.back(tester);
    await app.push(tester, '/pengaturan');
    expect(find.text('HitungIn Pro aktif'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Batas gratis Budget: total + 2 kategori, lalu ditawari Pro', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.run((db) async {
      await db.budgetsDao.setLimit(categoryId: app.food(), limitAmount: 1000000);
      await db.budgetsDao.setLimit(categoryId: app.transport(), limitAmount: 500000);
    });
    await app.pump(tester);
    await app.go(tester, '/budget');

    // Atur budget: total boleh; kategori ke-3 → layar Pro.
    await app.tap('+ Atur');
    await app.tap('Ubah');
    await tester.enterText(find.byKey(const Key('batas-budget')), '4000000');
    await _tapSheet(tester, 'Pakai');
    expect(find.text('Rp4.000.000'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Tambah Belanja 50 ribu'));
    await tester.pumpAndSettle();
    expect(find.text(ProReason.budget.headline), findsWidgets);
    await app.back(tester);

    await app.tap('Simpan budget');
    final budgets = await app.run((db) => db.budgetsDao.effective(DateTime(2026, 10)));
    expect(budgets.where((b) => b.categoryId == null).single.limitAmount, 4000000);
    expect(budgets, hasLength(3));
    await app.close(tester);
  });

  testWidgets('Tagihan (gratis): tambah, bayar → tercatat & jatuh tempo maju; batas 3; notifikasi = Pro', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.run((db) async {
      await db.billsDao.add(name: 'Kos', amount: 1500000, dueDate: DateTime(2026, 10, 5), repeat: BillRepeat.bulanan, walletId: app.bca);
      await db.billsDao.add(name: 'Netflix', amount: 54000, dueDate: DateTime(2026, 10, 20), repeat: BillRepeat.bulanan);
    });
    await app.pump(tester);
    await app.push(tester, '/tagihan');

    expect(find.text('Notifikasi pengingat'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);

    expect(find.text('30 hari ke depan'), findsOneWidget);
    expect(find.text('2 tagihan belum dibayar'), findsOneWidget);
    await app.tap('+ Tambah');
    await tester.enterText(_field('Nama tagihan'), 'Internet');
    await tester.enterText(_field('Nominal'), '350000');
    await _tapSheet(tester, 'Simpan');
    expect(find.text('Internet'), findsOneWidget);

    // Bayar Kos (dompet BCA sudah terpilih dari tagihan).
    await tester.tap(find.bySemanticsLabel(RegExp('^Tandai lunas Kos')));
    await tester.pumpAndSettle();
    expect(find.text('Bayar Kos'), findsOneWidget);
    await _tapSheet(tester, 'Tandai lunas');
    expect(find.textContaining('jatuh tempo berikutnya sudah dimajukan'), findsOneWidget);
    final kos = (await app.run((db) => db.billsDao.watchActive().first)).firstWhere((b) => b.name == 'Kos');
    expect(kos.nextDue, DateTime(2026, 11, 5));
    expect((await app.balances())['BCA'], 1000000 - 1500000);
    await app.scrollTo(find.text('Sudah dicatat bulan ini'));
    expect(find.text('Lunas 2 Okt · BCA'), findsOneWidget);

    // 3 tagihan aktif → tambah lagi = layar Pro.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await app.tap('+ Tambah');
    expect(find.text(ProReason.tagihan.headline), findsWidgets);
    await app.back(tester);

    await app.tap('Notifikasi pengingat');
    expect(find.text(ProReason.notifikasi.headline), findsWidgets);
    await app.close(tester);
  });

  testWidgets('Tagihan (Pro): notifikasi dijadwalkan, ganti jam, matikan, izin ditolak', (tester) async {
    final app = AppHarness(tester, pro: true);
    await app.seed();
    await app.run((db) => db.billsDao.add(
        name: 'Listrik', amount: 450000, dueDate: DateTime(2026, 10, 20), repeat: BillRepeat.bulanan, remindDaysBefore: 3));
    await app.pump(tester);
    await tester.pump(const Duration(seconds: 1)); // jeda sinkronisasi
    final reminders = app.env.reminders;
    expect(reminders.scheduled.map((p) => p.at), [DateTime(2026, 10, 17, 9), DateTime(2026, 10, 20, 9)]);

    await app.push(tester, '/tagihan');
    await app.tap('19.00');
    await tester.pump(const Duration(seconds: 1));
    expect(reminders.scheduled.map((p) => p.at.hour).toSet(), {19});
    expect(await app.setting(SettingKeys.billReminderHour), '19');

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(reminders.scheduled, isEmpty);
    expect(await app.setting(SettingKeys.billReminders), 'false');

    // Nyalakan lagi saat izin HP ditolak → minta izin & tampilkan peringatan.
    reminders.granted = false;
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(reminders.permissionRequests, 1);
    expect(find.textContaining('Notifikasi HitungIn sedang dimatikan'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Laporan (gratis): bulan lama, tren, dan filter dompet mengarah ke Pro', (tester) async {
    final app = AppHarness(tester);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 50000, app.gopay, DateTime(2026, 10, 1), category: app.food());
    await app.addTx(TxKind.pengeluaran, 20000, app.tunai, DateTime(2026, 10, 1), category: app.food());
    await app.addTx(TxKind.pengeluaran, 30000, app.tunai, DateTime(2026, 9, 3), category: app.food());
    await app.pump(tester);
    await app.go(tester, '/laporan');

    // Arus kas 6 bulan gratis; 12 bulan mengarah ke Pro.
    await app.scrollTo(find.text('Arus kas 6 bulan'));
    await app.tap('12 bulan · PRO');
    expect(find.text(ProReason.laporan.headline), findsWidgets, reason: 'layar Pro');
    await app.back(tester);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text('Sep 2026'), findsOneWidget);
    expect(find.text('Selisih bulan ini'), findsOneWidget, reason: 'bulan lalu masih gratis');

    await app.tap('GoPay');
    expect(find.text(ProReason.laporan.headline), findsWidgets, reason: 'filter dompet = Pro');
    await app.back(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Versi gratis menampilkan laporan bulan ini dan bulan lalu'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Laporan (Pro): filter dompet & tren 6 bulan', (tester) async {
    final app = AppHarness(tester, pro: true);
    await app.seed();
    await app.addTx(TxKind.pengeluaran, 50000, app.gopay, DateTime(2026, 10, 1), category: app.food());
    await app.addTx(TxKind.pengeluaran, 700000, app.bca, DateTime(2026, 10, 2), category: app.food());
    await app.addTx(TxKind.pengeluaran, 300000, app.bca, DateTime(2026, 8, 2), category: app.food());
    await app.pump(tester);
    await app.go(tester, '/laporan');

    expect(find.text('Rp750rb'), findsNWidgets(2), reason: 'kartu Pengeluaran + tengah donat');
    await app.tap('GoPay');
    expect(find.text('Rp50rb'), findsWidgets);
    expect(find.text('Rp750rb'), findsNothing);

    await app.tap('Semua dompet');
    await app.scrollTo(find.text('Arus kas 6 bulan'));
    await app.scrollTo(find.text('Agustus 2026'));
    expect(find.text('Agustus 2026'), findsOneWidget, reason: 'tabel arus kas (Pro)');
    await app.tap('12 bulan');
    expect(find.text('Arus kas 12 bulan'), findsOneWidget);
    await app.close(tester);
  });

  testWidgets('Transaksi berulang: gratis → Pro; Pro → jadwal dibuat & langsung tercatat', (tester) async {
    final free = AppHarness(tester);
    await free.seed();
    await free.pump(tester);
    await free.push(tester, '/pengaturan/berulang');
    await free.tap('Tambah jadwal');
    expect(find.text(ProReason.berulang.headline), findsWidgets);
    await free.close(tester);

    final app = AppHarness(tester, pro: true);
    await app.seed();
    await app.pump(tester);
    await app.push(tester, '/pengaturan/berulang');
    expect(find.text('Belum ada jadwal'), findsOneWidget);
    await tester.tap(find.text('Tambah jadwal').last);
    await tester.pumpAndSettle();
    await tester.tap(_inSheet(find.text('Pemasukan')));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Nominal'), '9200000');
    await tester.enterText(_field('Catatan'), 'Gaji');
    await _tapSheet(tester, 'Gaji', chip: true);
    await _tapSheet(tester, 'BCA', chip: true);
    await _tapSheet(tester, 'Simpan');

    expect(find.text('Gaji'), findsOneWidget);
    expect(find.textContaining('Bulanan · 2 Nov'), findsOneWidget, reason: 'mulai hari ini → sudah tercatat, berikutnya bulan depan');
    final txs = await app.run((db) => db.select(db.transactions).get());
    expect((txs.single.amount, txs.single.kind, txs.single.recurringId != null), (9200000, TxKind.pemasukan, true));
    await app.close(tester);
  });
}
