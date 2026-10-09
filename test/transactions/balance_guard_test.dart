import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/transactions/data/balance_guard.dart';

Txn _tx(TxKind kind, int amount, {int wallet = 1, int? to}) => Txn(
      id: 9,
      kind: kind,
      amount: amount,
      walletId: wallet,
      toWalletId: to,
      categoryId: null,
      sub: '',
      note: '',
      occurredAt: DateTime(2026, 10, 9),
      createdAt: DateTime(2026, 10, 9),
      updatedAt: DateTime(2026, 10, 9),
    );

void main() {
  group('peringatan saldo minus', () {
    test('pengeluaran membuat saldo >= 0 jadi minus -> diperingatkan', () {
      final c = negativeBalanceCheck(current: 20000, walletId: 1, kind: TxKind.pengeluaran, amount: 25000);
      expect((c.before, c.after, c.warn), (20000, -5000, true));
    });

    test('saldo 0 lalu pengeluaran -> diperingatkan; cukup -> tidak', () {
      expect(negativeBalanceCheck(current: 0, walletId: 1, kind: TxKind.pengeluaran, amount: 1).warn, isTrue);
      expect(negativeBalanceCheck(current: 30000, walletId: 1, kind: TxKind.pengeluaran, amount: 30000).warn, isFalse);
    });

    test('pindah saldo dari dompet yang kurang -> diperingatkan', () {
      final c = negativeBalanceCheck(current: 10000, walletId: 1, kind: TxKind.transfer, amount: 50000, toWalletId: 2);
      expect((c.after, c.warn), (-40000, true));
    });

    test('pemasukan tidak pernah diperingatkan', () {
      expect(negativeBalanceCheck(current: -5000, walletId: 1, kind: TxKind.pemasukan, amount: 1000).warn, isFalse);
    });

    test('dompet yang sudah minus tidak ditanya berulang', () {
      expect(negativeBalanceCheck(current: -5000, walletId: 1, kind: TxKind.pengeluaran, amount: 1000).warn, isFalse);
    });

    test('edit: nominal lama dikembalikan dulu sebelum dihitung', () {
      // Saldo 5.000 sudah termasuk pengeluaran lama 20.000 -> sebelum transaksi ini 25.000.
      final edit = _tx(TxKind.pengeluaran, 20000);
      expect(negativeBalanceCheck(current: 5000, walletId: 1, kind: TxKind.pengeluaran, amount: 25000, editing: edit).warn,
          isFalse);
      final c = negativeBalanceCheck(current: 5000, walletId: 1, kind: TxKind.pengeluaran, amount: 30000, editing: edit);
      expect((c.before, c.after, c.warn), (25000, -5000, true));
    });

    test('pengaruh transaksi per dompet', () {
      expect(txEffectOn(1, kind: TxKind.transfer, amount: 100, fromWallet: 1, toWallet: 2), -100);
      expect(txEffectOn(2, kind: TxKind.transfer, amount: 100, fromWallet: 1, toWallet: 2), 100);
      expect(txEffectOn(3, kind: TxKind.pengeluaran, amount: 100, fromWallet: 1), 0);
    });
  });

  test('Sesuaikan saldo: saldo awal digeser, riwayat tetap', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final id = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet, initialBalance: 10000);
    final cat = (await db.categoriesDao.active()).firstWhere((c) => c.kind == TxKind.pengeluaran);
    await db.transactionsDao.add(
        kind: TxKind.pengeluaran, amount: 25000, walletId: id, categoryId: cat.id, occurredAt: DateTime(2026, 10, 9));
    await db.walletsDao.setBalance(id, 80000);
    final wb = (await db.walletsDao.watchBalances().first).single;
    expect(wb.balance, 80000);
    expect(wb.wallet.initialBalance, 105000);
    expect(await db.transactionsDao.watchBetween(DateTime(2026, 10), DateTime(2026, 11)).first, hasLength(1));
    await db.close();
  });
}
