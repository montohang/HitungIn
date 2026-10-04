import 'package:drift/drift.dart';

import '../../features/bills/data/bills_dao.dart';
import '../../features/budget/data/budgets_dao.dart';
import '../../features/categories/data/categories_dao.dart';
import '../../features/settings/data/settings_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/wallets/data/wallets_dao.dart';
import 'default_data.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, Budgets, Bills, Settings],
  daos: [WalletsDao, CategoriesDao, TransactionsDao, BudgetsDao, BillsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] dari `openEncryptedConnection()` di aplikasi, atau
  /// `NativeDatabase.memory()` di tes.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaults(this);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
