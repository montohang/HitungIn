import 'package:drift/drift.dart';

import '../../features/bills/data/bills_dao.dart';
import '../../features/budget/data/budgets_dao.dart';
import '../../features/categories/data/categories_dao.dart';
import '../../features/recurring/data/recurring_dao.dart';
import '../../features/settings/data/settings_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/wallets/data/wallets_dao.dart';
import 'default_data.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, Budgets, Bills, Settings, RecurringTxs],
  daos: [WalletsDao, CategoriesDao, TransactionsDao, BudgetsDao, BillsDao, SettingsDao, RecurringDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] dari `openEncryptedConnection()` di aplikasi, atau
  /// `NativeDatabase.memory()` di tes.
  AppDatabase(super.executor);

  @override
  /// v1: skema awal. v2: transaksi berulang (tabel recurring_txs +
  /// transactions.recurring_id). v3: budget per bulan (budgets.from_month,
  /// batas 0 = dihapus mulai bulan itu).
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaults(this);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(recurringTxs);
            await m.addColumn(transactions, transactions.recurringId);
          }
          if (from < 3) {
            // Tabel dibuat ulang: unik (kategori, bulan) menggantikan unik kategori.
            await m.alterTable(TableMigration(budgets, newColumns: [budgets.fromMonth]));
          }
          // Pastikan relasi data tetap utuh sesudah migrasi.
          final List<QueryRow> broken = await customSelect('PRAGMA foreign_key_check').get();
          if (broken.isNotEmpty) throw StateError('Migrasi merusak relasi data: ${broken.length} baris');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
