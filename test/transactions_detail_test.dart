import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/budget/data/budgets_dao.dart';
import 'package:hitungin/features/transactions/tx_detail_screen.dart';

import 'helpers/fakes.dart';

Txn _tx({TxKind kind = TxKind.pengeluaran, int? categoryId = 1, int? billId, int? recurringId}) => Txn(
      id: 1,
      kind: kind,
      amount: 25000,
      walletId: 1,
      categoryId: categoryId,
      note: '',
      billId: billId,
      recurringId: recurringId,
      occurredAt: DateTime(2026, 10, 19),
      createdAt: DateTime(2026, 10, 19),
      updatedAt: DateTime(2026, 10, 19),
    );

BudgetProgress _b(int? categoryId) => (
      budget: Budget(id: categoryId ?? 0, categoryId: categoryId, limitAmount: 500000, fromMonth: DateTime(2000), createdAt: DateTime(2026)),
      category: categoryId == null
          ? null
          : Category(
              id: categoryId, name: 'K$categoryId', kind: TxKind.pengeluaran, icon: 'x', keywords: '', sortOrder: 0, archived: false),
      spent: 100000,
    );

void main() {
  test('asal transaksi', () {
    expect(txOrigin(_tx()), 'dicatat manual');
    expect(txOrigin(_tx(billId: 3)), 'dari tagihan');
    expect(txOrigin(_tx(recurringId: 2)), 'dicatat otomatis');
  });

  test('budget terdampak: kategori dulu, lalu total; pemasukan tidak', () {
    expect(impactedBudget(_tx(), [_b(null), _b(1)])!.category!.id, 1);
    expect(impactedBudget(_tx(categoryId: 7), [_b(null), _b(1)])!.category, isNull);
    expect(impactedBudget(_tx(categoryId: 7), [_b(1)]), isNull);
    expect(impactedBudget(_tx(kind: TxKind.pemasukan), [_b(null), _b(1)]), isNull);
  });

  test('restore mengembalikan transaksi terhapus dengan id lama', () async {
    final env = TestEnv();
    final db = env.db;
    final int w = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 100000);
    final int id = await db.transactionsDao
        .add(kind: TxKind.pengeluaran, amount: 30000, walletId: w, note: 'Bakso', occurredAt: DateTime(2026, 10, 2));
    final Txn tx = (await db.transactionsDao.byId(id))!;
    await db.transactionsDao.remove(id);
    expect(await db.transactionsDao.byId(id), isNull);

    expect(await db.transactionsDao.restore(tx), id);
    expect((await db.transactionsDao.byId(id))!.note, 'Bakso');

    // Id sudah terpakai → disimpan dengan id baru.
    final int other = await db.transactionsDao.restore(tx.copyWith(note: 'Salinan', billId: const Value(null)));
    expect(other, isNot(id));
    await db.close();
  });
}
