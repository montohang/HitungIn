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
    int? installmentTotal,
    int installmentPaid = 0,
  }) {
    final DateTime due = Dates.day(dueDate);
    _validateInstallment(installmentTotal, installmentPaid);
    return into(bills).insert(BillsCompanion.insert(
      name: name.trim(),
      amount: amount,
      nextDue: due,
      repeat: repeat,
      anchorDay: due.day,
      categoryId: Value(categoryId),
      walletId: Value(walletId),
      remindDaysBefore: Value(remindDaysBefore),
      installmentTotal: Value(installmentTotal),
      installmentPaid: Value(installmentPaid),
    ));
  }

  Future<void> edit(Bill bill) {
    _validateInstallment(bill.installmentTotal, bill.installmentPaid);
    return update(bills).replace(bill.copyWith(nextDue: Dates.day(bill.nextDue)));
  }

  static void _validateInstallment(int? total, int paid) {
    if (total == null) return;
    if (total < 2 || total > 60) throw ArgumentError.value(total, 'installmentTotal', 'Tenor 2–60 bulan');
    if (paid < 0 || paid >= total) throw ArgumentError.value(paid, 'installmentPaid', 'Harus kurang dari tenor');
  }

  Future<void> remove(int id) => (delete(bills)..where((b) => b.id.equals(id))).go();

  /// Mencatat pembayaran sebagai pengeluaran lalu memajukan jatuh tempo.
  /// Tagihan sekali bayar dinonaktifkan. Cicilan: hitungan naik satu, dan
  /// cicilan terakhir menyelesaikan tagihan (tidak aktif lagi). Tanpa
  /// kategori, cicilan masuk kategori bawaan Tagihan. Mengembalikan id transaksi.
  Future<int> pay(Bill bill, {int? walletId, int? amount, DateTime? paidAt}) => transaction(() async {
        final int? wallet = walletId ?? bill.walletId;
        if (wallet == null) throw ArgumentError('Pilih dompet untuk membayar tagihan');
        final int? total = bill.installmentTotal;
        final int paid = bill.installmentPaid + 1;
        final int? categoryId = bill.categoryId ?? (total == null ? null : await _billsCategory());
        final int txId = await attachedDatabase.transactionsDao.add(
          kind: TxKind.pengeluaran,
          amount: amount ?? bill.amount,
          walletId: wallet,
          categoryId: categoryId,
          note: total == null ? bill.name : '${bill.name} · cicilan $paid/$total',
          occurredAt: paidAt ?? DateTime.now(),
          billId: bill.id,
        );
        final bool finished = total != null && paid >= total;
        final DateTime? next = finished ? null : Dates.nextDue(bill.nextDue, bill.repeat, anchorDay: bill.anchorDay);
        await (update(bills)..where((b) => b.id.equals(bill.id))).write(BillsCompanion(
          active: next == null ? const Value(false) : const Value.absent(),
          nextDue: next == null ? const Value.absent() : Value(next),
          installmentPaid: total == null ? const Value.absent() : Value(paid),
        ));
        return txId;
      });

  Future<int?> _billsCategory() async {
    final Category? c = await (attachedDatabase.select(attachedDatabase.categories)
          ..where((c) => c.name.equals('Tagihan') & c.kind.equalsValue(TxKind.pengeluaran) & c.archived.equals(false))
          ..limit(1))
        .getSingleOrNull();
    return c?.id;
  }
}
