import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/default_data.dart' show walletColorCycle;

part 'wallets_dao.g.dart';

/// Dompet beserta saldo berjalannya.
typedef WalletBalance = ({Wallet wallet, int balance});

@DriftAccessor(tables: [Wallets, Transactions])
class WalletsDao extends DatabaseAccessor<AppDatabase> with _$WalletsDaoMixin {
  WalletsDao(super.attachedDatabase);

  /// Saldo = saldo awal + pemasukan − pengeluaran − transfer keluar + transfer masuk.
  static const String _balanceSql = '''
    w.initial_balance
    + COALESCE((SELECT SUM(CASE t.kind WHEN 'pemasukan' THEN t.amount ELSE -t.amount END)
                FROM transactions t WHERE t.wallet_id = w.id), 0)
    + COALESCE((SELECT SUM(t.amount) FROM transactions t WHERE t.to_wallet_id = w.id), 0)
  ''';

  Stream<List<WalletBalance>> watchBalances({bool includeArchived = false}) {
    return customSelect(
      'SELECT w.*, $_balanceSql AS balance FROM wallets w '
      '${includeArchived ? '' : 'WHERE w.archived = 0 '}'
      'ORDER BY w.sort_order, w.id',
      readsFrom: {wallets, transactions},
    ).watch().map((rows) => [
          for (final row in rows) (wallet: wallets.map(row.data), balance: row.read<int>('balance')),
        ]);
  }

  /// Total saldo semua dompet aktif.
  Stream<int> watchTotalBalance() =>
      watchBalances().map((list) => list.fold(0, (sum, w) => sum + w.balance));

  Future<List<Wallet>> active() =>
      (select(wallets)..where((w) => w.archived.equals(false))..orderBy([(w) => OrderingTerm(expression: w.sortOrder)])).get();

  /// Semua dompet termasuk yang diarsipkan (cek nama kembar).
  Future<List<Wallet>> all() => select(wallets).get();

  Future<int> add({required String name, required WalletType type, int initialBalance = 0, String? icon, int? color}) async {
    final int order = await _nextSortOrder();
    return into(wallets).insert(WalletsCompanion.insert(
      name: name.trim(),
      type: type,
      initialBalance: Value(initialBalance),
      icon: Value(icon ?? _defaultIcon(type)),
      // Bawaan: warna berikutnya dalam urutan, supaya bar porsi saldo mudah dibedakan.
      color: Value(color ?? walletColorCycle[order % walletColorCycle.length]),
      sortOrder: Value(order),
    ));
  }

  /// Hitung jumlah transaksi tiap dompet dalam rentang (keluar/masuk/transfer).
  Future<Map<int, int>> txCounts(DateTime from, DateTime to) async {
    final rows = await customSelect(
      '''
      SELECT w.id AS id, (SELECT COUNT(*) FROM transactions t
        WHERE (t.wallet_id = w.id OR t.to_wallet_id = w.id) AND t.occurred_at >= ?1 AND t.occurred_at < ?2) AS n
      FROM wallets w
      ''',
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {wallets, transactions},
    ).get();
    return {for (final r in rows) r.read<int>('id'): r.read<int>('n')};
  }

  Future<void> edit(Wallet wallet) => update(wallets).replace(wallet);

  /// Samakan saldo dompet dengan [target] ("Sesuaikan saldo"): saldo awalnya
  /// digeser, riwayat transaksi tidak diubah.
  Future<void> setBalance(int walletId, int target) async {
    final WalletBalance wb = (await watchBalances(includeArchived: true).first).firstWhere((b) => b.wallet.id == walletId);
    await edit(wb.wallet.copyWith(initialBalance: wb.wallet.initialBalance + (target - wb.balance)));
  }

  Future<void> setArchived(int id, bool archived) =>
      (update(wallets)..where((w) => w.id.equals(id))).write(WalletsCompanion(archived: Value(archived)));

  /// Menghapus hanya bila belum punya transaksi; selain itu arsipkan saja.
  Future<bool> deleteIfUnused(int id) => transaction(() async {
        final Expression<int> count = transactions.id.count();
        final int used = await (selectOnly(transactions)
              ..addColumns([count])
              ..where(transactions.walletId.equals(id) | transactions.toWalletId.equals(id)))
            .map((r) => r.read(count)!)
            .getSingle();
        if (used > 0) return false;
        await (delete(wallets)..where((w) => w.id.equals(id))).go();
        return true;
      });

  Future<void> reorder(List<int> idsInOrder) => batch((b) {
        for (final (int i, int id) in idsInOrder.indexed) {
          b.update(wallets, WalletsCompanion(sortOrder: Value(i)), where: (w) => w.id.equals(id));
        }
      });

  Future<int> _nextSortOrder() async {
    final Expression<int> max = wallets.sortOrder.max();
    final int? current = await (selectOnly(wallets)..addColumns([max])).map((r) => r.read(max)).getSingle();
    return (current ?? -1) + 1;
  }

  static String _defaultIcon(WalletType type) => switch (type) {
        WalletType.tunai => 'cash',
        WalletType.bank => 'bank',
        WalletType.ewallet => 'ewallet',
        WalletType.lainnya => 'wallet',
      };
}
