import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/data/bill_due.dart';
import 'package:hitungin/features/bills/data/bill_reminders.dart';

void main() {
  late AppDatabase db;
  late int bca;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 10000000);
  });
  tearDown(() => db.close());

  Future<Bill> bill(int id) => (db.select(db.bills)..where((b) => b.id.equals(id))).getSingle();

  test('sisa = (tenor − dibayar) × nominal; tanggal lunas = jatuh tempo berikutnya + sisa bulan', () async {
    final id = await db.billsDao.add(
        name: 'SPayLater', amount: 400000, dueDate: DateTime(2026, 10, 31), repeat: BillRepeat.bulanan, walletId: bca, installmentTotal: 12, installmentPaid: 3);
    final i = installmentOf(await bill(id))!;
    expect((i.next, i.remainingCount, i.remainingAmount), (4, 9, 3600000));
    expect(i.lastDue, DateTime(2027, 6, 30), reason: '31 Okt + 8 bulan, Juni hanya 30 hari');
  });

  test('tenor & dibayar divalidasi', () {
    Future<int> add(int total, int paid) => db.billsDao.add(
        name: 'X', amount: 1000, dueDate: DateTime(2026, 10, 1), repeat: BillRepeat.bulanan, installmentTotal: total, installmentPaid: paid);
    expect(() => add(1, 0), throwsArgumentError);
    expect(() => add(61, 0), throwsArgumentError);
    expect(() => add(12, 12), throwsArgumentError);
  });

  test('bayar cicilan: hitungan naik, kategori bawaan Tagihan, catatan bernomor', () async {
    final id = await db.billsDao.add(
        name: 'Kredivo', amount: 412000, dueDate: DateTime(2026, 10, 21), repeat: BillRepeat.bulanan, walletId: bca, installmentTotal: 12, installmentPaid: 3);
    final txId = await db.billsDao.pay(await bill(id), paidAt: DateTime(2026, 10, 21, 9));
    final b = await bill(id);
    expect((b.installmentPaid, b.nextDue, b.active), (4, DateTime(2026, 11, 21), true));
    final tx = (await db.transactionsDao.byId(txId))!;
    final cat = (await db.categoriesDao.active()).firstWhere((c) => c.id == tx.categoryId);
    expect((tx.kind, tx.note, cat.name), (TxKind.pengeluaran, 'Kredivo · cicilan 4/12', 'Tagihan'));
  });

  test('bayar cicilan ke-12 dari 12 → tagihan tidak aktif, tidak ada pengingat berikutnya', () async {
    final id = await db.billsDao.add(
        name: 'Kredivo', amount: 412000, dueDate: DateTime(2026, 10, 21), repeat: BillRepeat.bulanan, walletId: bca, installmentTotal: 12, installmentPaid: 11);
    await db.billsDao.pay(await bill(id), paidAt: DateTime(2026, 10, 21, 9));
    final b = await bill(id);
    expect((b.installmentPaid, b.active), (12, false));
    final active = await db.billsDao.watchActive().first;
    expect(active, isEmpty);
    expect(billsInReminderWindow(active, DateTime(2026, 11, 20)), isEmpty);
  });

  test('ringkasan cicilan berjalan', () async {
    await db.billsDao.add(name: 'A', amount: 400000, dueDate: DateTime(2026, 10, 31), repeat: BillRepeat.bulanan, installmentTotal: 12, installmentPaid: 3);
    await db.billsDao.add(name: 'B', amount: 780000, dueDate: DateTime(2026, 11, 5), repeat: BillRepeat.bulanan, installmentTotal: 24, installmentPaid: 8);
    await db.billsDao.add(name: 'Kos', amount: 1000000, dueDate: DateTime(2026, 11, 1), repeat: BillRepeat.bulanan);
    final s = installmentsSummary(await db.billsDao.watchActive().first);
    expect(s, (amount: 9 * 400000 + 16 * 780000, count: 2));
  });
}
