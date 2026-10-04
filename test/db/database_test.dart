import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/connection.dart';
import 'package:hitungin/core/db/db_key.dart';
import 'package:hitungin/core/db/default_data.dart';
import 'package:hitungin/core/theme/app_tokens.dart';
import 'package:hitungin/core/theme/theme_controller.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('kategori bawaan terisi saat database dibuat', () async {
    final cats = await db.categoriesDao.active();
    expect(cats, hasLength(defaultCategories.length));
    expect((await db.categoriesDao.active(kind: TxKind.pemasukan)).map((c) => c.name), contains('Gaji'));
  });

  group('saldo dompet', () {
    test('saldo awal + pemasukan − pengeluaran ± transfer', () async {
      final bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
      final gopay = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet);
      final at = DateTime(2026, 10, 2);
      await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 9200000, walletId: bca, occurredAt: at);
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 25000, walletId: gopay, occurredAt: at);
      await db.transactionsDao.add(kind: TxKind.transfer, amount: 200000, walletId: bca, toWalletId: gopay, occurredAt: at);

      final balances = await db.walletsDao.watchBalances().first;
      expect({for (final b in balances) b.wallet.name: b.balance}, {'BCA': 10000000, 'GoPay': 175000});
      expect(await db.walletsDao.watchTotalBalance().first, 10175000);
    });

    test('dompet terpakai tidak bisa dihapus', () async {
      final id = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai);
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 5000, walletId: id, occurredAt: DateTime(2026));
      expect(await db.walletsDao.deleteIfUnused(id), isFalse);
      final empty = await db.walletsDao.add(name: 'Kosong', type: WalletType.lainnya);
      expect(await db.walletsDao.deleteIfUnused(empty), isTrue);
    });
  });

  group('transaksi', () {
    late int wallet;
    late int food;
    setUp(() async {
      wallet = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai);
      food = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
    });

    test('nominal ≤ 0 dan transfer ke dompet sama ditolak', () async {
      expect(
        () => db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 0, walletId: wallet, occurredAt: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => db.transactionsDao
            .add(kind: TxKind.transfer, amount: 10, walletId: wallet, toWalletId: wallet, occurredAt: DateTime(2026)),
        throwsArgumentError,
      );
    });

    test('ringkasan & total per kategori hanya dalam rentang', () async {
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 25000, walletId: wallet, categoryId: food, occurredAt: DateTime(2026, 10, 2));
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 15000, walletId: wallet, categoryId: food, occurredAt: DateTime(2026, 10, 3));
      await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 100000, walletId: wallet, occurredAt: DateTime(2026, 10, 5));
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 99000, walletId: wallet, categoryId: food, occurredAt: DateTime(2026, 9, 30));

      final from = DateTime(2026, 10);
      final to = DateTime(2026, 11);
      expect(await db.transactionsDao.watchSummary(from, to).first, (income: 100000, expense: 40000));
      final totals = await db.transactionsDao.watchCategoryTotals(from, to).first;
      expect(totals.single.category.id, food);
      expect(totals.single.total, 40000);
      final daily = await db.transactionsDao.watchDailyExpense(from, to).first;
      expect(daily, {DateTime(2026, 10, 2): 25000, DateTime(2026, 10, 3): 15000});
    });

    test('riwayat: urutan terbaru, filter & pencarian', () async {
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 25000, walletId: wallet, categoryId: food, note: 'Kopi', occurredAt: DateTime(2026, 10, 1));
      await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 50000, walletId: wallet, note: 'Bensin', occurredAt: DateTime(2026, 10, 2));

      final all = await db.transactionsDao.watchBetween(DateTime(2026, 10), DateTime(2026, 11)).first;
      expect(all.map((d) => d.tx.note), ['Bensin', 'Kopi']);
      expect(all.last.category?.name, 'Makan & Minum');
      expect(all.first.category, isNull);
      expect(all.first.wallet.name, 'Tunai');

      final found = await db.transactionsDao.watchBetween(DateTime(2026, 10), DateTime(2026, 11), search: 'makan').first;
      expect(found.single.tx.note, 'Kopi');
      final recent = await db.transactionsDao.watchRecent(limit: 1).first;
      expect(recent.single.tx.note, 'Bensin');
    });
  });

  test('budget: total & per kategori dengan pemakaian bulan berjalan', () async {
    final wallet = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai);
    final cats = await db.categoriesDao.active(kind: TxKind.pengeluaran);
    final food = cats.firstWhere((c) => c.name == 'Makan & Minum').id;
    final transport = cats.firstWhere((c) => c.name == 'Transportasi').id;
    await db.budgetsDao.setLimit(limitAmount: 3000000);
    await db.budgetsDao.setLimit(categoryId: food, limitAmount: 1000000);
    await db.budgetsDao.setLimit(categoryId: food, limitAmount: 1200000); // ganti, bukan tambah
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 300000, walletId: wallet, categoryId: food, occurredAt: DateTime(2026, 10, 2));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 50000, walletId: wallet, categoryId: transport, occurredAt: DateTime(2026, 10, 2));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 70000, walletId: wallet, categoryId: food, occurredAt: DateTime(2026, 11, 1));

    final progress = await db.budgetsDao.watchProgress(DateTime(2026, 10, 15)).first;
    expect(progress, hasLength(2));
    expect(progress[0].category, isNull);
    expect(progress[0].spent, 350000);
    expect(progress[1].category!.name, 'Makan & Minum');
    expect(progress[1].budget.limitAmount, 1200000);
    expect(progress[1].spent, 300000);
  });

  group('tagihan', () {
    test('bayar bulanan: catat pengeluaran & majukan jatuh tempo', () async {
      final wallet = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
      final id = await db.billsDao.add(name: 'Kos', amount: 800000, dueDate: DateTime(2026, 1, 31), repeat: BillRepeat.bulanan, walletId: wallet);
      Bill bill = (await db.billsDao.watchActive().first).single;

      final txId = await db.billsDao.pay(bill);
      final tx = await db.transactionsDao.byId(txId);
      expect(tx!.billId, id);
      expect(tx.note, 'Kos');
      expect(tx.amount, 800000);

      bill = (await db.billsDao.watchActive().first).single;
      expect(bill.nextDue, DateTime(2026, 2, 28));
      await db.billsDao.pay(bill);
      bill = (await db.billsDao.watchActive().first).single;
      expect(bill.nextDue, DateTime(2026, 3, 31), reason: 'kembali ke tanggal asli');
      expect(await db.walletsDao.watchTotalBalance().first, 1000000 - 1600000);
    });

    test('tagihan sekali bayar jadi nonaktif', () async {
      final wallet = await db.walletsDao.add(name: 'BCA', type: WalletType.bank);
      await db.billsDao.add(name: 'Servis', amount: 300000, dueDate: DateTime(2026, 10, 9), repeat: BillRepeat.sekali);
      final bill = (await db.billsDao.watchActive().first).single;
      expect(() => db.billsDao.pay(bill), throwsArgumentError, reason: 'belum ada dompet');
      await db.billsDao.pay(bill, walletId: wallet);
      expect(await db.billsDao.watchActive().first, isEmpty);
    });
  });

  test('pengaturan kunci–nilai', () async {
    expect(await db.settingsDao.read(SettingKeys.themeMode), isNull);
    await db.settingsDao.write(SettingKeys.themeMode, 'terang');
    await db.settingsDao.write(SettingKeys.themeMode, 'amoled');
    expect(await db.settingsDao.read(SettingKeys.themeMode), 'amoled');
  });

  test('pilihan tema dibaca kembali dari database', () async {
    expect((await loadThemeSettings(db.settingsDao)).mode, AppThemeMode.gelap);
    await db.settingsDao.write(SettingKeys.themeMode, 'terang');
    await db.settingsDao.write(SettingKeys.themeAccent, 'teal');
    await db.settingsDao.write(SettingKeys.themeGradientCard, 'true');
    final s = await loadThemeSettings(db.settingsDao);
    expect((s.mode, s.accent, s.gradientBalanceCard), (AppThemeMode.terang, AccentPreset.teal, true));
    await db.settingsDao.write(SettingKeys.themeMode, 'tidak-ada');
    expect((await loadThemeSettings(db.settingsDao)).mode, AppThemeMode.gelap);
  });

  test('file database terenkripsi: tanpa kunci tidak bisa dibaca', () async {
    final dir = await Directory.systemTemp.createTemp('hitungin');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/test.db');
    final key = DbKeyStore.generate();

    final enc = AppDatabase(NativeDatabase(file, setup: (raw) => applyCipherKey(raw, key)));
    await enc.walletsDao.add(name: 'Rahasia', type: WalletType.tunai);
    await enc.close();

    final bytes = await file.readAsBytes();
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));

    final plain = sqlite3.open(file.path);
    expect(() => plain.select('SELECT * FROM wallets'), throwsA(isA<SqliteException>()));
    plain.close();

    final wrong = sqlite3.open(file.path);
    expect(() => applyCipherKey(wrong, DbKeyStore.generate()), throwsA(isA<SqliteException>()));
    wrong.close();

    final again = AppDatabase(NativeDatabase(file, setup: (raw) => applyCipherKey(raw, key)));
    expect((await again.walletsDao.active()).single.name, 'Rahasia');
    await again.close();
  });
}
