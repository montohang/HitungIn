import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';

void main() {
  late AppDatabase db;
  late int bca, gopay, salary, subs;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank);
    gopay = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet);
    final cats = await db.categoriesDao.active();
    salary = cats.firstWhere((c) => c.name == 'Gaji').id;
    subs = cats.firstWhere((c) => c.name == 'Tagihan').id;
  });
  tearDown(() => db.close());

  Future<List<Txn>> txs() => db.select(db.transactions).get();

  group('transaksi berulang', () {
    test('belum jatuh tempo → tidak dicatat; jatuh tempo → dicatat jam 08.00 & maju sebulan', () async {
      final id = await db.recurringDao.add(
        kind: TxKind.pemasukan, amount: 9200000, walletId: bca, categoryId: salary, note: 'Gaji', repeat: BillRepeat.bulanan, firstRun: DateTime(2026, 10, 25));
      expect(await db.recurringDao.runDue(DateTime(2026, 10, 24, 23)), 0);
      expect(await db.recurringDao.runDue(DateTime(2026, 10, 25, 6)), 1);
      expect(await db.recurringDao.runDue(DateTime(2026, 10, 25, 22)), 0, reason: 'tidak dobel di hari yang sama');

      final tx = (await txs()).single;
      expect((tx.amount, tx.kind, tx.note, tx.recurringId), (9200000, TxKind.pemasukan, 'Gaji', id));
      expect(tx.occurredAt, DateTime(2026, 10, 25, 8));
      expect((await db.recurringDao.watchAll().first).single.nextRun, DateTime(2026, 11, 25));
    });

    test('susulan setelah lama tidak dibuka, tanggal 31 kembali ke 31', () async {
      await db.recurringDao.add(
        kind: TxKind.pengeluaran, amount: 54000, walletId: gopay, categoryId: subs, note: 'Netflix', repeat: BillRepeat.bulanan, firstRun: DateTime(2026, 1, 31));
      expect(await db.recurringDao.runDue(DateTime(2026, 4, 15)), 3);
      expect([for (final t in await txs()) t.occurredAt.day], [31, 28, 31]);
      expect((await db.recurringDao.watchAll().first).single.nextRun, DateTime(2026, 4, 30));
    });

    test('susulan dibatasi, jadwal tetap maju melewati hari ini', () async {
      await db.recurringDao.add(
        kind: TxKind.pengeluaran, amount: 1000, walletId: bca, categoryId: subs, repeat: BillRepeat.mingguan, firstRun: DateTime(2020, 1, 1));
      expect(await db.recurringDao.runDue(DateTime(2026, 10, 4)), 36);
      expect((await db.recurringDao.watchAll().first).single.nextRun.isAfter(DateTime(2026, 10, 4)), isTrue);
    });

    test('transfer berulang memindah saldo; jadwal nonaktif dilewati', () async {
      final id = await db.recurringDao.add(
        kind: TxKind.transfer, amount: 200000, walletId: bca, toWalletId: gopay, repeat: BillRepeat.bulanan, firstRun: DateTime(2026, 10, 1));
      await db.recurringDao.runDue(DateTime(2026, 10, 1));
      final b = {for (final w in await db.walletsDao.watchBalances().first) w.wallet.name: w.balance};
      expect(b, {'BCA': -200000, 'GoPay': 200000});

      await db.recurringDao.setActive(id, false);
      expect(await db.recurringDao.runDue(DateTime(2026, 12, 1)), 0);
    });

    test('hapus jadwal → transaksi yang sudah tercatat tetap ada', () async {
      final id = await db.recurringDao.add(
        kind: TxKind.pemasukan, amount: 10, walletId: bca, categoryId: salary, repeat: BillRepeat.tahunan, firstRun: DateTime(2026, 1, 1));
      await db.recurringDao.runDue(DateTime(2026, 6, 1));
      await db.recurringDao.remove(id);
      expect((await txs()).single.recurringId, isNull);
    });

    test('validasi', () {
      expect(
        () => db.recurringDao.add(kind: TxKind.pengeluaran, amount: 0, walletId: bca, repeat: BillRepeat.bulanan, firstRun: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => db.recurringDao.add(kind: TxKind.pengeluaran, amount: 5, walletId: bca, repeat: BillRepeat.sekali, firstRun: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => db.recurringDao.add(kind: TxKind.transfer, amount: 5, walletId: bca, toWalletId: bca, repeat: BillRepeat.bulanan, firstRun: DateTime(2026)),
        throwsArgumentError,
      );
    });
  });

  group('laporan Pro', () {
    setUp(() async {
      final food = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
      final t = db.transactionsDao;
      await t.add(kind: TxKind.pemasukan, amount: 9000000, walletId: bca, categoryId: salary, occurredAt: DateTime(2026, 8, 25));
      await t.add(kind: TxKind.pengeluaran, amount: 300000, walletId: bca, categoryId: food, occurredAt: DateTime(2026, 8, 3));
      await t.add(kind: TxKind.pengeluaran, amount: 50000, walletId: gopay, categoryId: food, occurredAt: DateTime(2026, 10, 2));
      await t.add(kind: TxKind.pengeluaran, amount: 70000, walletId: bca, categoryId: food, occurredAt: DateTime(2026, 10, 3));
      await t.add(kind: TxKind.transfer, amount: 999, walletId: bca, toWalletId: gopay, occurredAt: DateTime(2026, 10, 3));
    });

    test('tren bulanan: bulan kosong tetap ada, transfer tidak dihitung', () async {
      final m = await db.transactionsDao.watchMonthlyTotals(DateTime(2026, 10), months: 3).first;
      expect([for (final e in m) (e.month.month, e.income, e.expense)], [(8, 9000000, 300000), (9, 0, 0), (10, 0, 120000)]);
      final y = await db.transactionsDao.watchMonthlyTotals(DateTime(2026, 2), months: 12).first;
      expect(y.first.month, DateTime(2025, 3));
      expect(y.last.month, DateTime(2026, 2));
    });

    test('filter dompet di ringkasan, kategori, harian, dan tren', () async {
      final dao = db.transactionsDao;
      final from = DateTime(2026, 10), to = DateTime(2026, 11);
      expect(await dao.watchSummary(from, to, walletId: gopay).first, (income: 0, expense: 50000));
      expect((await dao.watchCategoryTotals(from, to, walletId: bca).first).single.total, 70000);
      expect(await dao.watchDailyExpense(from, to, walletId: gopay).first, {DateTime(2026, 10, 2): 50000});
      final trend = await dao.watchMonthlyTotals(DateTime(2026, 10), months: 3, walletId: gopay).first;
      expect([for (final e in trend) e.expense], [0, 0, 50000]);
    });
  });
}
