import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';
import 'debts.dart';

part 'debts_dao.g.dart';

/// Catatan utang-piutang beserta pembayarannya.
typedef DebtWithPayments = ({Debt debt, List<DebtPayment> payments});

extension DebtWithPaymentsX on DebtWithPayments {
  int get paid => payments.fold(0, (sum, p) => sum + p.amount);
  DebtFacts get facts => (direction: debt.direction, amount: debt.amount, paid: paid, dueDate: debt.dueDate);
  int get left => debtLeft(facts);
  DebtStatus get status => debtStatus(facts);
}

@DriftAccessor(tables: [Debts, DebtPayments, Transactions])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.attachedDatabase);

  /// Semua catatan, terbaru dulu, dengan pembayarannya (lama → baru).
  Stream<List<DebtWithPayments>> watchAll() {
    final q = select(debts).join([leftOuterJoin(debtPayments, debtPayments.debtId.equalsExp(debts.id))])
      ..orderBy([
        OrderingTerm.desc(debts.occurredAt),
        OrderingTerm.desc(debts.id),
        OrderingTerm(expression: debtPayments.paidAt),
        OrderingTerm(expression: debtPayments.id),
      ]);
    return q.watch().map((rows) {
      final Map<int, (Debt, List<DebtPayment>)> acc = {};
      for (final TypedResult r in rows) {
        final Debt d = r.readTable(debts);
        final (Debt, List<DebtPayment>) entry = acc.putIfAbsent(d.id, () => (d, []));
        final DebtPayment? p = r.readTableOrNull(debtPayments);
        if (p != null) entry.$2.add(p);
      }
      return [for (final (Debt d, List<DebtPayment> ps) in acc.values) (debt: d, payments: ps)];
    });
  }

  Future<DebtWithPayments?> byId(int id) async {
    final Debt? d = await (select(debts)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (d == null) return null;
    final List<DebtPayment> ps = await (select(debtPayments)
          ..where((p) => p.debtId.equals(id))
          ..orderBy([(p) => OrderingTerm(expression: p.paidAt), (p) => OrderingTerm(expression: p.id)]))
        .get();
    return (debt: d, payments: ps);
  }

  /// Catat utang-piutang baru. Bila [walletId] diisi, saldo dompet ikut
  /// berubah lewat transaksi utangKeluar/utangMasuk (tidak masuk laporan).
  Future<int> add({
    required DebtDirection direction,
    required String name,
    required int amount,
    required DateTime occurredAt,
    int? walletId,
    DateTime? dueDate,
    String note = '',
  }) =>
      transaction(() async {
        _validate(name, amount);
        final int id = await into(debts).insert(DebtsCompanion.insert(
          direction: direction,
          name: name.trim(),
          amount: amount,
          walletId: Value(walletId),
          occurredAt: occurredAt,
          dueDate: Value(dueDate == null ? null : Dates.day(dueDate)),
          note: Value(note.trim()),
        ));
        if (walletId != null) {
          await _insertTx(direction, name.trim(), amount, walletId, occurredAt, debtId: id);
        }
        return id;
      });

  /// Ubah catatan; transaksi pinjaman awal ikut disesuaikan (dibuat,
  /// diubah, atau dihapus bila dompet dikosongkan).
  Future<void> edit(Debt d) => transaction(() async {
        _validate(d.name, d.amount);
        final Debt clean = d.copyWith(name: d.name.trim(), note: d.note.trim(), dueDate: Value(d.dueDate == null ? null : Dates.day(d.dueDate!)));
        await update(debts).replace(clean);
        final Txn? opening = await (select(transactions)
              ..where((t) => t.debtId.equals(d.id) & t.debtPaymentId.isNull()))
            .getSingleOrNull();
        if (clean.walletId == null) {
          if (opening != null) await (delete(transactions)..where((t) => t.id.equals(opening.id))).go();
        } else if (opening == null) {
          await _insertTx(clean.direction, clean.name, clean.amount, clean.walletId!, clean.occurredAt, debtId: clean.id);
        } else {
          await update(transactions).replace(opening.copyWith(
            kind: debtTxKind(clean.direction, payment: false),
            amount: clean.amount,
            walletId: clean.walletId!,
            occurredAt: clean.occurredAt,
            note: debtTxNote(clean.direction, clean.name, payment: false),
            updatedAt: DateTime.now(),
          ));
        }
      });

  /// Hapus catatan beserta pembayaran & transaksinya (saldo kembali).
  Future<void> remove(int id) => (delete(debts)..where((d) => d.id.equals(id))).go();

  /// Catat pembayaran (sebagian). Nominal tidak boleh melebihi sisa.
  Future<int> pay(int debtId, {required int amount, required DateTime paidAt, int? walletId}) => transaction(() async {
        final DebtWithPayments? d = await byId(debtId);
        if (d == null) throw StateError('Catatan utang tidak ditemukan');
        if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
        if (amount > d.left) throw ArgumentError.value(amount, 'amount', 'Melebihi sisa');
        final int id = await into(debtPayments).insert(DebtPaymentsCompanion.insert(
          debtId: debtId,
          amount: amount,
          walletId: Value(walletId),
          paidAt: paidAt,
        ));
        if (walletId != null) {
          await _insertTx(d.debt.direction, d.debt.name, amount, walletId, paidAt, debtId: debtId, paymentId: id);
        }
        return id;
      });

  /// Hapus satu pembayaran (dan transaksinya).
  Future<void> removePayment(int id) => (delete(debtPayments)..where((p) => p.id.equals(id))).go();

  Future<int> _insertTx(DebtDirection dir, String name, int amount, int walletId, DateTime at,
          {required int debtId, int? paymentId}) =>
      into(transactions).insert(TransactionsCompanion.insert(
        kind: debtTxKind(dir, payment: paymentId != null),
        amount: amount,
        walletId: walletId,
        note: Value(debtTxNote(dir, name, payment: paymentId != null)),
        occurredAt: at,
        debtId: Value(debtId),
        debtPaymentId: Value(paymentId),
      ));

  static void _validate(String name, int amount) {
    if (name.trim().isEmpty) throw ArgumentError('Nama wajib diisi');
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
  }
}
