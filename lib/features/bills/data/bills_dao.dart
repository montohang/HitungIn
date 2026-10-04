import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';

part 'bills_dao.g.dart';

@DriftAccessor(tables: [Bills, Transactions])
class BillsDao extends DatabaseAccessor<AppDatabase> with _$BillsDaoMixin {
  BillsDao(super.attachedDatabase);

  /// Tagihan aktif, jatuh tempo terdekat dulu.
  Stream<List<Bill>> watchActive() => (select(bills)
        ..where((b) => b.active.equals(true))
        ..orderBy([(b) => OrderingTerm(expression: b.nextDue)]))
      .watch();

  Future<int> add({
    required String name,
    required int amount,
    required DateTime dueDate,
    required BillRepeat repeat,
    int? categoryId,
    int? walletId,
    int remindDaysBefore = 1,
  }) {
    final DateTime due = Dates.day(dueDate);
    return into(bills).insert(BillsCompanion.insert(
      name: name.trim(),
      amount: amount,
      nextDue: due,
      repeat: repeat,
      anchorDay: due.day,
      categoryId: Value(categoryId),
      walletId: Value(walletId),
      remindDaysBefore: Value(remindDaysBefore),
    ));
  }

  Future<void> edit(Bill bill) => update(bills).replace(bill.copyWith(nextDue: Dates.day(bill.nextDue)));

  Future<void> remove(int id) => (delete(bills)..where((b) => b.id.equals(id))).go();

  /// Mencatat pembayaran sebagai pengeluaran lalu memajukan jatuh tempo.
  /// Tagihan sekali bayar dinonaktifkan. Mengembalikan id transaksi.
  Future<int> pay(Bill bill, {int? walletId, int? amount, DateTime? paidAt}) => transaction(() async {
        final int? wallet = walletId ?? bill.walletId;
        if (wallet == null) throw ArgumentError('Pilih dompet untuk membayar tagihan');
        final int txId = await attachedDatabase.transactionsDao.add(
          kind: TxKind.pengeluaran,
          amount: amount ?? bill.amount,
          walletId: wallet,
          categoryId: bill.categoryId,
          note: bill.name,
          occurredAt: paidAt ?? DateTime.now(),
          billId: bill.id,
        );
        final DateTime? next = Dates.nextDue(bill.nextDue, bill.repeat, anchorDay: bill.anchorDay);
        await (update(bills)..where((b) => b.id.equals(bill.id))).write(
          next == null ? const BillsCompanion(active: Value(false)) : BillsCompanion(nextDue: Value(next)),
        );
        return txId;
      });
}
