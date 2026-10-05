import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/bills_screen.dart';

import '../helpers/fakes.dart';

void main() {
  test('30 hari ke depan: termasuk yang terlambat, tidak termasuk > 30 hari', () async {
    final env = TestEnv();
    final db = env.db;
    await db.billsDao.add(name: 'Kos', amount: 1500000, dueDate: DateTime(2026, 10, 15), repeat: BillRepeat.bulanan);
    await db.billsDao.add(name: 'Listrik', amount: 450000, dueDate: DateTime(2026, 11, 18), repeat: BillRepeat.bulanan);
    await db.billsDao.add(name: 'Asuransi', amount: 900000, dueDate: DateTime(2026, 12, 1), repeat: BillRepeat.bulanan);
    final bills = await db.billsDao.watchActive().first;
    expect(upcomingBills(bills, DateTime(2026, 10, 19, 9)), (total: 1950000, count: 2));
    await db.close();
  });

  test('Sudah dicatat bulan ini = pembayaran tagihan di bulan itu saja', () async {
    final env = TestEnv();
    final db = env.db;
    final int w = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 5000000);
    await db.billsDao.add(name: 'Kos', amount: 1500000, dueDate: DateTime(2026, 10, 5), repeat: BillRepeat.bulanan, walletId: w);
    final Bill kos = (await db.billsDao.watchActive().first).single;
    await db.billsDao.pay(kos, paidAt: DateTime(2026, 10, 6, 10));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 20000, walletId: w, occurredAt: DateTime(2026, 10, 7));

    final paid = await db.transactionsDao.watchBillPayments(DateTime(2026, 10), DateTime(2026, 11)).first;
    expect(paid.map((d) => d.tx.amount), [1500000]);
    expect(await db.transactionsDao.watchBillPayments(DateTime(2026, 11), DateTime(2026, 12)).first, isEmpty);
    await db.close();
  });
}
