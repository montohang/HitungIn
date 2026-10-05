import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'transactions_dao.g.dart';

/// Transaksi beserta kategori & dompetnya, siap ditampilkan di daftar.
typedef TxDetail = ({Txn tx, Category? category, Wallet wallet, Wallet? toWallet});

/// Ringkasan pemasukan/pengeluaran satu periode (transfer tidak dihitung).
typedef PeriodSummary = ({int income, int expense});

/// Total pengeluaran/pemasukan per kategori.
typedef CategoryTotal = ({Category category, int total});

/// Pemasukan & pengeluaran satu bulan (kunci = tanggal 1).
typedef MonthTotal = ({DateTime month, int income, int expense});

@DriftAccessor(tables: [Transactions, Categories, Wallets])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  late final $WalletsTable _toWallets = alias(wallets, 'to_w');

  Future<int> add({
    required TxKind kind,
    required int amount,
    required int walletId,
    int? toWalletId,
    int? categoryId,
    String note = '',
    required DateTime occurredAt,
    int? billId,
  }) {
    _validate(kind: kind, amount: amount, walletId: walletId, toWalletId: toWalletId, categoryId: categoryId);
    return into(transactions).insert(TransactionsCompanion.insert(
      kind: kind,
      amount: amount,
      walletId: walletId,
      toWalletId: Value(kind == TxKind.transfer ? toWalletId : null),
      categoryId: Value(kind == TxKind.transfer ? null : categoryId),
      note: Value(note.trim()),
      occurredAt: occurredAt,
      billId: Value(billId),
    ));
  }

  Future<void> edit(Txn tx) {
    _validate(kind: tx.kind, amount: tx.amount, walletId: tx.walletId, toWalletId: tx.toWalletId, categoryId: tx.categoryId);
    return update(transactions).replace(tx.copyWith(note: tx.note.trim(), updatedAt: DateTime.now()));
  }

  /// Kembalikan transaksi yang baru dihapus ("Urungkan"). Memakai id lama
  /// bila masih kosong, selain itu id baru.
  Future<int> restore(Txn tx) async {
    final bool taken = await byId(tx.id) != null;
    final TransactionsCompanion row = tx.toCompanion(true);
    return into(transactions).insert(taken ? row.copyWith(id: const Value.absent()) : row);
  }

  Future<void> remove(int id) => (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<Txn?> byId(int id) => (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Riwayat dalam rentang [from] (inklusif) – [to] (eksklusif), terbaru dulu.
  /// [search] mencocokkan catatan atau nama kategori.
  Stream<List<TxDetail>> watchBetween(
    DateTime from,
    DateTime to, {
    int? walletId,
    int? categoryId,
    TxKind? kind,
    String? search,
  }) {
    final q = _detailQuery()
      ..where(transactions.occurredAt.isBiggerOrEqualValue(from) & transactions.occurredAt.isSmallerThanValue(to));
    if (walletId != null) {
      q.where(transactions.walletId.equals(walletId) | transactions.toWalletId.equals(walletId));
    }
    if (categoryId != null) q.where(transactions.categoryId.equals(categoryId));
    if (kind != null) q.where(transactions.kind.equalsValue(kind));
    final String term = search?.trim() ?? '';
    if (term.isNotEmpty) {
      q.where(transactions.note.like('%$term%') | categories.name.like('%$term%'));
    }
    return q.watch().map(_mapDetails);
  }

  /// Semua transaksi (terbaru dulu), untuk ekspor.
  Future<List<TxDetail>> allDetails() => _detailQuery().get().then(_mapDetails);

  /// Satu transaksi beserta relasinya; null bila sudah dihapus.
  Stream<TxDetail?> watchDetail(int id) =>
      (_detailQuery()..where(transactions.id.equals(id))).watch().map((rows) => rows.isEmpty ? null : _mapDetails(rows).single);

  Stream<List<TxDetail>> watchRecent({int limit = 5}) => (_detailQuery()..limit(limit)).watch().map(_mapDetails);

  /// [walletId] membatasi ke satu dompet (transfer tidak dihitung).
  Stream<PeriodSummary> watchSummary(DateTime from, DateTime to, {int? walletId}) {
    final Expression<int> income = _sumWhen(TxKind.pemasukan);
    final Expression<int> expense = _sumWhen(TxKind.pengeluaran);
    final q = selectOnly(transactions)
      ..addColumns([income, expense])
      ..where(transactions.occurredAt.isBiggerOrEqualValue(from) & transactions.occurredAt.isSmallerThanValue(to));
    if (walletId != null) q.where(transactions.walletId.equals(walletId));
    return q.map((r) => (income: r.read(income) ?? 0, expense: r.read(expense) ?? 0)).watchSingle();
  }

  /// Total per kategori untuk [kind], terbesar dulu.
  Stream<List<CategoryTotal>> watchCategoryTotals(
    DateTime from,
    DateTime to, {
    TxKind kind = TxKind.pengeluaran,
    int? walletId,
  }) {
    final Expression<int> total = transactions.amount.sum();
    final q = select(transactions).join([innerJoin(categories, categories.id.equalsExp(transactions.categoryId))])
      ..addColumns([total])
      ..where(transactions.kind.equalsValue(kind) &
          transactions.occurredAt.isBiggerOrEqualValue(from) &
          transactions.occurredAt.isSmallerThanValue(to))
      ..groupBy([categories.id])
      ..orderBy([OrderingTerm.desc(total)]);
    if (walletId != null) q.where(transactions.walletId.equals(walletId));
    return q.watch().map((rows) => [
          for (final r in rows) (category: r.readTable(categories), total: r.read(total) ?? 0),
        ]);
  }

  /// Pengeluaran per hari (kunci = tanggal 00.00) untuk grafik laporan.
  Stream<Map<DateTime, int>> watchDailyExpense(DateTime from, DateTime to, {int? walletId}) {
    final q = selectOnly(transactions)
      ..addColumns([transactions.occurredAt, transactions.amount])
      ..where(transactions.kind.equalsValue(TxKind.pengeluaran) &
          transactions.occurredAt.isBiggerOrEqualValue(from) &
          transactions.occurredAt.isSmallerThanValue(to));
    if (walletId != null) q.where(transactions.walletId.equals(walletId));
    return q.watch().map((rows) {
      final Map<DateTime, int> out = {};
      for (final r in rows) {
        final DateTime at = r.read(transactions.occurredAt)!;
        final DateTime day = DateTime(at.year, at.month, at.day);
        out[day] = (out[day] ?? 0) + r.read(transactions.amount)!;
      }
      return out;
    });
  }

  /// Tren: [months] bulan terakhir sampai [lastMonth] (inklusif), urut lama → baru.
  /// Bulan tanpa transaksi tetap muncul dengan nilai 0.
  Stream<List<MonthTotal>> watchMonthlyTotals(DateTime lastMonth, {int months = 6, int? walletId}) {
    final DateTime first = DateTime(lastMonth.year, lastMonth.month - months + 1);
    final DateTime end = DateTime(lastMonth.year, lastMonth.month + 1);
    final q = selectOnly(transactions)
      ..addColumns([transactions.kind, transactions.amount, transactions.occurredAt])
      ..where(transactions.kind.isNotValue(TxKind.transfer.name) &
          transactions.occurredAt.isBiggerOrEqualValue(first) &
          transactions.occurredAt.isSmallerThanValue(end));
    if (walletId != null) q.where(transactions.walletId.equals(walletId));
    return q.watch().map((rows) {
      final Map<DateTime, (int, int)> acc = {
        for (int i = 0; i < months; i++) DateTime(first.year, first.month + i): (0, 0),
      };
      for (final r in rows) {
        final DateTime at = r.read(transactions.occurredAt)!;
        final DateTime key = DateTime(at.year, at.month);
        final int amount = r.read(transactions.amount)!;
        final (int inc, int exp) = acc[key]!;
        acc[key] = r.read(transactions.kind) == TxKind.pemasukan.name ? (inc + amount, exp) : (inc, exp + amount);
      }
      return [for (final e in acc.entries) (month: e.key, income: e.value.$1, expense: e.value.$2)];
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _detailQuery() => select(transactions).join([
        innerJoin(wallets, wallets.id.equalsExp(transactions.walletId)),
        leftOuterJoin(_toWallets, _toWallets.id.equalsExp(transactions.toWalletId)),
        leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      ])
        ..orderBy([OrderingTerm.desc(transactions.occurredAt), OrderingTerm.desc(transactions.id)]);

  List<TxDetail> _mapDetails(List<TypedResult> rows) => [
        for (final r in rows)
          (
            tx: r.readTable(transactions),
            category: r.readTableOrNull(categories),
            wallet: r.readTable(wallets),
            toWallet: r.readTableOrNull(_toWallets),
          ),
      ];

  Expression<int> _sumWhen(TxKind kind) => CaseWhenExpression<int>(
        cases: [CaseWhen(transactions.kind.equalsValue(kind), then: transactions.amount)],
        orElse: const Constant(0),
      ).sum();

  static void _validate({
    required TxKind kind,
    required int amount,
    required int walletId,
    int? toWalletId,
    int? categoryId,
  }) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
    if (kind == TxKind.transfer) {
      if (toWalletId == null) throw ArgumentError('Transfer butuh dompet tujuan');
      if (toWalletId == walletId) throw ArgumentError('Dompet asal dan tujuan tidak boleh sama');
    }
  }
}
