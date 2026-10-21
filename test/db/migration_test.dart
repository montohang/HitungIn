import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  // AppDatabase selalu bermigrasi ke versi terbaru, jadi validasi ke v8.
  test('v1 → v8: skema hasil migrasi sama dengan skema baru', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    await db.close();
  });

  test('v1 → v2: data lama tetap utuh & fitur baru langsung bisa dipakai', () async {
    final schema = await verifier.schemaAt(1);
    // Isi data dengan SQL polos versi 1.
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, sort_order, archived, created_at) "
          "VALUES (1, 'BCA', 'bank', 1000000, 'bank', 0, 0, 1759000000)")
      ..execute("INSERT INTO categories (id, name, kind, icon, keywords, sort_order, archived) "
          "VALUES (1, 'Gaji', 'pemasukan', 'salary', 'gaji', 0, 0)")
      ..execute("INSERT INTO transactions (kind, amount, wallet_id, category_id, note, occurred_at, created_at, updated_at) "
          "VALUES ('pemasukan', 9200000, 1, 1, 'Gaji', 1759300000, 1759300000, 1759300000)");

    final db = AppDatabase(schema.newConnection());
    final balances = await db.walletsDao.watchBalances().first;
    expect(balances.single.balance, 10200000);
    final tx = (await db.transactionsDao.watchRecent().first).single.tx;
    expect(tx.recurringId, isNull);

    await db.recurringDao.add(
      kind: TxKind.pemasukan,
      amount: 9200000,
      walletId: 1,
      categoryId: 1,
      note: 'Gaji',
      repeat: BillRepeat.bulanan,
      firstRun: DateTime(2026, 10, 25),
    );
    expect(await db.recurringDao.runDue(DateTime(2026, 10, 25, 9)), 1);
    await db.close();
  });

  test('v2 → v8: skema hasil migrasi sama dengan skema baru', () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    await db.close();
  });

  test('v2 → v3: budget lama tetap berlaku untuk semua bulan', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute("INSERT INTO categories (id, name, kind, icon, keywords, sort_order, archived) "
          "VALUES (1, 'Makan', 'pengeluaran', 'food', 'makan', 0, 0)")
      ..execute('INSERT INTO budgets (category_id, limit_amount, created_at) VALUES (NULL, 3000000, 1759000000)')
      ..execute('INSERT INTO budgets (category_id, limit_amount, created_at) VALUES (1, 500000, 1759000000)');

    final db = AppDatabase(schema.newConnection());
    for (final month in [DateTime(2024, 1), DateTime(2026, 10)]) {
      final b = await db.budgetsDao.effective(month);
      expect({for (final x in b) x.categoryId: x.limitAmount}, {null: 3000000, 1: 500000});
    }
    await db.close();
  });

  test('v3 → v4: kategori bawaan dapat warna & sub-kategori, dompet dapat warna', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, sort_order, archived, created_at) "
          "VALUES (1, 'BCA', 'bank', 0, 'bank', 0, 0, 1759000000), (2, 'GoPay', 'ewallet', 0, 'ewallet', 1, 0, 1759000000)")
      ..execute("INSERT INTO categories (id, name, kind, icon, keywords, sort_order, archived) "
          "VALUES (1, 'Makan & Minum', 'pengeluaran', 'food', 'makan', 0, 0), (2, 'Kucing', 'pengeluaran', 'fun', '', 1, 0)");
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    final cats = {for (final c in await db.select(db.categories).get()) c.name: c};
    expect((cats['Makan & Minum']!.color, cats['Makan & Minum']!.subs), (0, 'Kopi,Makan siang,Jajan'));
    expect((cats['Kucing']!.color, cats['Kucing']!.subs), (0, ''));
    final wallets = await (db.select(db.wallets)..orderBy([(w) => OrderingTerm(expression: w.sortOrder)])).get();
    expect([for (final w in wallets) w.color], [0, 2]);
    await db.close();
  });

  test('v4 → v5: tagihan lama jadi tagihan biasa, cicilan & utang-piutang langsung bisa dipakai', () async {
    final schema = await verifier.schemaAt(4);
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, color, sort_order, archived, created_at) "
          "VALUES (1, 'Tunai', 'tunai', 500000, 'cash', 0, 0, 0, 1759000000)")
      ..execute("INSERT INTO bills (id, name, amount, wallet_id, next_due, repeat, anchor_day, remind_days_before, active, created_at) "
          "VALUES (1, 'Kos', 1000000, 1, 1761955200, 'bulanan', 1, 1, 1, 1759000000)")
      ..execute("INSERT INTO transactions (kind, amount, wallet_id, note, sub, occurred_at, created_at, updated_at) "
          "VALUES ('pengeluaran', 25000, 1, 'Kopi', '', 1759300000, 1759300000, 1759300000)");

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    final Bill kos = (await db.select(db.bills).get()).single;
    expect((kos.installmentTotal, kos.installmentPaid), (null, 0));
    expect((await db.walletsDao.watchBalances().first).single.balance, 475000);

    await db.debtsDao.add(
        direction: DebtDirection.piutang, name: 'Budi', amount: 200000, occurredAt: DateTime(2026, 10, 5), walletId: 1);
    expect((await db.walletsDao.watchBalances().first).single.balance, 275000);
    await db.close();
  });

  test('v5 → v6: data lama utuh, target tabungan langsung bisa dipakai tanpa mengubah saldo', () async {
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, color, sort_order, archived, created_at) "
          "VALUES (1, 'BCA', 'bank', 2000000, 'bank', 0, 0, 0, 1759000000)")
      ..execute("INSERT INTO debts (id, direction, name, amount, wallet_id, occurred_at, note, created_at) "
          "VALUES (1, 'piutang', 'Budi', 200000, 1, 1759300000, '', 1759300000)");

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    expect((await db.debtsDao.watchAll().first).single.debt.name, 'Budi');
    final int id = await db.goalsDao.add(name: 'Dana darurat', target: 1000000);
    await db.goalsDao.deposit(id, amount: 300000, at: DateTime(2026, 10, 20), walletId: 1);
    expect((await db.goalsDao.byId(id))!.deposits.single.amount, 300000);
    expect((await db.walletsDao.watchBalances().first).single.balance, 2000000);
    await db.close();
  });

  test('v6 → v7: utang & transaksi lama utuh, patungan langsung bisa dipakai', () async {
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, color, sort_order, archived, created_at) "
          "VALUES (1, 'BCA', 'bank', 1000000, 'bank', 0, 0, 0, 1759000000)")
      ..execute("INSERT INTO debts (id, direction, name, amount, wallet_id, occurred_at, note, created_at) "
          "VALUES (1, 'piutang', 'Budi', 200000, 1, 1759300000, '', 1759300000)")
      ..execute("INSERT INTO transactions (kind, amount, wallet_id, note, sub, occurred_at, created_at, updated_at, debt_id) "
          "VALUES ('utangKeluar', 200000, 1, 'Dipinjamkan ke Budi', '', 1759300000, 1759300000, 1759300000, 1)");

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    expect((await db.debtsDao.watchAll().first).single.debt.splitId, isNull);
    expect((await db.walletsDao.watchBalances().first).single.balance, 800000);
    await db.splitsDao.save(
      title: 'Makan',
      mode: SplitMode.rata,
      total: 100000,
      walletId: 1,
      occurredAt: DateTime(2026, 10, 21),
      members: [
        (name: 'Aku', isMe: true, payer: true, share: 50000),
        (name: 'Sinta', isMe: false, payer: false, share: 50000),
      ],
    );
    expect((await db.walletsDao.watchBalances().first).single.balance, 700000);
    await db.close();
  });

  test('v7 → v8: pembayaran tagihan lama tetap ada, jatuh temponya kosong', () async {
    final schema = await verifier.schemaAt(7);
    schema.rawDatabase
      ..execute("INSERT INTO wallets (id, name, type, initial_balance, icon, color, sort_order, archived, created_at) "
          "VALUES (1, 'BCA', 'bank', 1000000, 'bank', 0, 0, 0, 1759000000)")
      ..execute("INSERT INTO transactions (kind, amount, wallet_id, note, sub, occurred_at, created_at, updated_at) "
          "VALUES ('pengeluaran', 350000, 1, 'Internet', '', 1759300000, 1759300000, 1759300000)");
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    final tx = (await db.select(db.transactions).get()).single;
    expect((tx.amount, tx.billDue), (350000, null));
    await db.close();
  });
}
