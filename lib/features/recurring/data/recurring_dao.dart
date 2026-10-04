import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [RecurringTxs, Transactions])
class RecurringDao extends DatabaseAccessor<AppDatabase> with _$RecurringDaoMixin {
  RecurringDao(super.attachedDatabase);

  /// Batas susulan per jadwal sekali jalan (mis. aplikasi lama tidak dibuka).
  static const int maxCatchUp = 36;

  /// Jam pencatatan otomatis.
  static const int runHour = 8;

  Stream<List<RecurringTx>> watchAll() => (select(recurringTxs)
        ..orderBy([
          (r) => OrderingTerm.desc(r.active),
          (r) => OrderingTerm(expression: r.nextRun),
        ]))
      .watch();

  Future<int> add({
    required TxKind kind,
    required int amount,
    required int walletId,
    int? toWalletId,
    int? categoryId,
    String note = '',
    required BillRepeat repeat,
    required DateTime firstRun,
  }) {
    _validate(kind, amount, walletId, toWalletId, repeat);
    final DateTime start = Dates.day(firstRun);
    return into(recurringTxs).insert(RecurringTxsCompanion.insert(
      kind: kind,
      amount: amount,
      walletId: walletId,
      toWalletId: Value(kind == TxKind.transfer ? toWalletId : null),
      categoryId: Value(kind == TxKind.transfer ? null : categoryId),
      note: Value(note.trim()),
      repeat: repeat,
      anchorDay: start.day,
      nextRun: start,
    ));
  }

  Future<void> edit(RecurringTx r) {
    _validate(r.kind, r.amount, r.walletId, r.toWalletId, r.repeat);
    final DateTime next = Dates.day(r.nextRun);
    return update(recurringTxs).replace(r.copyWith(nextRun: next, note: r.note.trim()));
  }

  Future<void> setActive(int id, bool active) =>
      (update(recurringTxs)..where((r) => r.id.equals(id))).write(RecurringTxsCompanion(active: Value(active)));

  /// Transaksi yang sudah tercatat tetap ada (recurring_id jadi kosong).
  Future<void> remove(int id) => (delete(recurringTxs)..where((r) => r.id.equals(id))).go();

  /// Catat semua jadwal aktif yang sudah jatuh tempo sampai [now] (termasuk
  /// susulan), lalu majukan jadwalnya. Aman dipanggil berkali-kali.
  /// Mengembalikan jumlah transaksi yang dibuat.
  Future<int> runDue(DateTime now) => transaction(() async {
        final DateTime today = Dates.day(now);
        final List<RecurringTx> due = await (select(recurringTxs)
              ..where((r) => r.active.equals(true) & r.nextRun.isSmallerOrEqualValue(today)))
            .get();
        int created = 0;
        for (final RecurringTx r in due) {
          DateTime next = r.nextRun;
          int n = 0;
          while (!next.isAfter(today) && n < maxCatchUp) {
            await into(transactions).insert(TransactionsCompanion.insert(
              kind: r.kind,
              amount: r.amount,
              walletId: r.walletId,
              toWalletId: Value(r.toWalletId),
              categoryId: Value(r.categoryId),
              note: Value(r.note),
              occurredAt: DateTime(next.year, next.month, next.day, runHour),
              recurringId: Value(r.id),
            ));
            next = Dates.nextDue(next, r.repeat, anchorDay: r.anchorDay)!;
            n++;
          }
          // Lewat batas susulan → lompat ke jadwal berikutnya setelah hari ini.
          while (!next.isAfter(today)) {
            next = Dates.nextDue(next, r.repeat, anchorDay: r.anchorDay)!;
          }
          await (update(recurringTxs)..where((x) => x.id.equals(r.id))).write(RecurringTxsCompanion(nextRun: Value(next)));
          created += n;
        }
        return created;
      });

  static void _validate(TxKind kind, int amount, int walletId, int? toWalletId, BillRepeat repeat) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
    if (repeat == BillRepeat.sekali) throw ArgumentError('Transaksi berulang harus mingguan, bulanan, atau tahunan');
    if (kind == TxKind.transfer && (toWalletId == null || toWalletId == walletId)) {
      throw ArgumentError('Transfer butuh dompet tujuan yang berbeda');
    }
  }
}
