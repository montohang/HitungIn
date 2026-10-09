import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/transactions/data/kind_lock.dart';

Txn _tx(TxKind kind, {int? bill, int? recurring}) => Txn(
      id: 1,
      kind: kind,
      amount: 10000,
      walletId: 1,
      toWalletId: kind == TxKind.transfer ? 2 : null,
      categoryId: kind == TxKind.transfer ? null : 3,
      sub: '',
      note: '',
      billId: bill,
      recurringId: recurring,
      occurredAt: DateTime(2026, 10, 9),
      createdAt: DateTime(2026, 10, 9),
      updatedAt: DateTime(2026, 10, 9),
    );

void main() {
  test('Pengeluaran ↔ Pemasukan boleh (memperbaiki salah catat)', () {
    expect(kindLockReason(_tx(TxKind.pengeluaran), TxKind.pemasukan), isNull);
    expect(kindLockReason(_tx(TxKind.pemasukan), TxKind.pengeluaran), isNull);
    expect(kindLockReason(_tx(TxKind.pengeluaran), TxKind.pengeluaran), isNull);
  });

  test('tidak bisa diubah jadi Pindah saldo', () {
    expect(kindLockReason(_tx(TxKind.pengeluaran), TxKind.transfer), contains('Pindah saldo'));
  });

  test('Pindah saldo terkunci', () {
    expect(kindLockReason(_tx(TxKind.transfer), TxKind.pengeluaran), contains('Pindah saldo tidak bisa'));
    expect(kindLockReason(_tx(TxKind.transfer), TxKind.transfer), isNull);
  });

  test('dari tagihan / transaksi berulang terkunci', () {
    expect(kindLockReason(_tx(TxKind.pengeluaran, bill: 4), TxKind.pemasukan), contains('tagihan'));
    expect(kindLockReason(_tx(TxKind.pemasukan, recurring: 5), TxKind.pengeluaran), contains('berulang'));
  });
}
