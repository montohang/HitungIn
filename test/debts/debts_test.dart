import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/debts/data/debts.dart';
import 'package:hitungin/features/debts/data/debts_dao.dart';

void main() {
  late AppDatabase db;
  late int tunai;
  final DateTime oct = DateTime(2026, 10, 5, 9);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    tunai = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 1000000);
  });
  tearDown(() => db.close());

  Future<int> balance() async => (await db.walletsDao.watchBalances().first).single.balance;
  Future<DebtWithPayments> load(int id) async => (await db.debtsDao.byId(id))!;

  group('status & ringkasan (logika murni)', () {
    DebtFacts f(DebtDirection dir, int amount, int paid, [DateTime? due]) =>
        (direction: dir, amount: amount, paid: paid, dueDate: due);

    test('Belum lunas → Dicicil → Lunas; sisa tidak pernah minus', () {
      expect(debtStatus(f(DebtDirection.piutang, 200000, 0)), DebtStatus.belumLunas);
      expect(debtStatus(f(DebtDirection.piutang, 200000, 100000)), DebtStatus.dicicil);
      expect(debtStatus(f(DebtDirection.piutang, 200000, 200000)), DebtStatus.lunas);
      expect(debtLeft(f(DebtDirection.piutang, 200000, 250000)), 0);
    });

    test('lewat jatuh tempo hanya bila belum lunas dan tanggalnya sudah lewat', () {
      final now = DateTime(2026, 10, 16, 8);
      expect(debtOverdue(f(DebtDirection.piutang, 500000, 0, DateTime(2026, 10, 15)), now), isTrue);
      expect(debtOverdue(f(DebtDirection.piutang, 500000, 0, DateTime(2026, 10, 16)), now), isFalse, reason: 'hari ini belum lewat');
      expect(debtOverdue(f(DebtDirection.piutang, 500000, 500000, DateTime(2026, 10, 1)), now), isFalse);
      expect(debtOverdue(f(DebtDirection.utang, 300000, 0), now), isFalse);
    });

    test('ringkasan dua arah, yang lunas tidak dihitung', () {
      final t = debtTotals([
        f(DebtDirection.piutang, 200000, 0),
        f(DebtDirection.piutang, 500000, 200000, DateTime(2026, 10, 15)),
        f(DebtDirection.piutang, 100000, 100000),
        f(DebtDirection.utang, 300000, 0),
      ], DateTime(2026, 10, 19));
      expect(t, (owedToMe: 500000, owedToMeCount: 2, iOwe: 300000, iOweCount: 1, overdue: 1));
    });

    test('arah uang & teks di Riwayat', () {
      expect(debtTxKind(DebtDirection.piutang, payment: false), TxKind.utangKeluar);
      expect(debtTxKind(DebtDirection.piutang, payment: true), TxKind.utangMasuk);
      expect(debtTxKind(DebtDirection.utang, payment: false), TxKind.utangMasuk);
      expect(debtTxKind(DebtDirection.utang, payment: true), TxKind.utangKeluar);
      expect(debtTxNote(DebtDirection.piutang, 'Budi', payment: true), 'Dibayar Budi');
    });
  });

  test('pinjamkan Rp200rb dari Tunai → saldo turun, laporan pengeluaran tidak berubah', () async {
    await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 200000, occurredAt: oct, walletId: tunai);
    expect(await balance(), 800000);
    final summary = await db.transactionsDao.watchSummary(DateTime(2026, 10), DateTime(2026, 11)).first;
    expect(summary, (income: 0, expense: 0));
    final months = await db.transactionsDao.watchMonthlyTotals(DateTime(2026, 10), months: 1).first;
    expect((months.single.income, months.single.expense), (0, 0));
    expect(await db.transactionsDao.watchDailyExpense(DateTime(2026, 10), DateTime(2026, 11)).first, isEmpty);
    final tx = (await db.transactionsDao.watchRecent().first).single.tx;
    expect((tx.kind, tx.note), (TxKind.utangKeluar, 'Dipinjamkan ke Budi'));
  });

  test('dibayar Rp100rb → Dicicil, sisa Rp100rb; dibayar lagi Rp100rb → Lunas', () async {
    final id = await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 200000, occurredAt: oct, walletId: tunai);
    await db.debtsDao.pay(id, amount: 100000, paidAt: DateTime(2026, 10, 10), walletId: tunai);
    var d = await load(id);
    expect((d.status, d.left), (DebtStatus.dicicil, 100000));
    expect(await balance(), 900000);
    expect(() => db.debtsDao.pay(id, amount: 150000, paidAt: DateTime(2026, 10, 11)), throwsArgumentError, reason: 'melebihi sisa');
    await db.debtsDao.pay(id, amount: 100000, paidAt: DateTime(2026, 10, 12), walletId: tunai);
    d = await load(id);
    expect((d.status, d.left, d.payments.length), (DebtStatus.lunas, 0, 2));
    expect(await balance(), 1000000);
  });

  test('utangku: meminjam menambah saldo, membayar mengurangi; tanpa dompet saldo tetap', () async {
    final id = await db.debtsDao.add(direction: DebtDirection.utang, name: 'Kak Sinta', amount: 300000, occurredAt: oct, walletId: tunai);
    expect(await balance(), 1300000);
    await db.debtsDao.pay(id, amount: 100000, paidAt: DateTime(2026, 10, 20), walletId: tunai);
    expect(await balance(), 1200000);
    await db.debtsDao.pay(id, amount: 50000, paidAt: DateTime(2026, 10, 21));
    expect(await balance(), 1200000);
    expect((await load(id)).left, 150000);
  });

  test('ubah nominal/dompet menyesuaikan transaksi awal; hapus catatan mengembalikan saldo', () async {
    final id = await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 200000, occurredAt: oct);
    expect(await balance(), 1000000);
    var d = (await load(id)).debt;
    await db.debtsDao.edit(d.copyWith(amount: 250000, walletId: Value(tunai)));
    expect(await balance(), 750000);
    d = (await load(id)).debt;
    await db.debtsDao.edit(d.copyWith(name: 'Budi S', amount: 150000));
    expect(await balance(), 850000);
    expect((await db.transactionsDao.watchRecent().first).single.tx.note, 'Dipinjamkan ke Budi S');
    await db.debtsDao.pay(id, amount: 50000, paidAt: DateTime(2026, 10, 8), walletId: tunai);
    expect(await balance(), 900000);
    await db.debtsDao.remove(id);
    expect(await balance(), 1000000);
    expect(await db.transactionsDao.watchRecent().first, isEmpty);
    expect(await db.select(db.debtPayments).get(), isEmpty);
  });

  test('hapus satu pembayaran ikut menghapus transaksinya', () async {
    final id = await db.debtsDao.add(direction: DebtDirection.piutang, name: 'Budi', amount: 200000, occurredAt: oct, walletId: tunai);
    final p = await db.debtsDao.pay(id, amount: 100000, paidAt: DateTime(2026, 10, 10), walletId: tunai);
    await db.debtsDao.removePayment(p);
    expect(await balance(), 800000);
    expect((await load(id)).status, DebtStatus.belumLunas);
  });
}
