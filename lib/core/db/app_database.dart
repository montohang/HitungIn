import 'package:drift/drift.dart';

import '../../features/bills/data/bills_dao.dart';
import '../../features/budget/data/budgets_dao.dart';
import '../../features/categories/data/categories_dao.dart';
import '../../features/debts/data/debts_dao.dart';
import '../../features/goals/data/goals_dao.dart';
import '../../features/splits/data/splits_dao.dart';
import '../../features/recurring/data/recurring_dao.dart';
import '../../features/settings/data/settings_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/wallets/data/wallets_dao.dart';
import 'default_data.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Categories, Transactions, Budgets, Bills, Settings, RecurringTxs, Debts, DebtPayments, Goals, GoalDeposits, Splits, SplitMembers, SplitItems],
  daos: [WalletsDao, CategoriesDao, TransactionsDao, BudgetsDao, BillsDao, SettingsDao, RecurringDao, DebtsDao, GoalsDao, SplitsDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] dari `openEncryptedConnection()` di aplikasi, atau
  /// `NativeDatabase.memory()` di tes.
  AppDatabase(super.executor);

  @override
  /// v1: skema awal. v2: transaksi berulang (tabel recurring_txs +
  /// transactions.recurring_id). v3: budget per bulan (budgets.from_month,
  /// batas 0 = dihapus mulai bulan itu). v4: warna dompet & kategori,
  /// sub-kategori (categories.subs, transactions.sub). v5: cicilan di tagihan
  /// (bills.installment_*), utang-piutang (debts, debt_payments,
  /// transactions.debt_id/debt_payment_id). v6: target tabungan (goals,
  /// goal_deposits). v7: patungan (splits, split_members, split_items,
  /// transactions.split_id, debts.split_id). v8: transactions.bill_due
  /// (jatuh tempo tagihan yang dibayar, untuk Rapor).
  int get schemaVersion => 8;

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
          if (from < 4) {
            await m.addColumn(wallets, wallets.color);
            await m.addColumn(categories, categories.color);
            await m.addColumn(categories, categories.subs);
            await m.addColumn(transactions, transactions.sub);
            await applyDefaultStyles(this);
          }
          if (from < 5) {
            await m.addColumn(bills, bills.installmentTotal);
            await m.addColumn(bills, bills.installmentPaid);
            await m.createTable(debts);
            await m.createTable(debtPayments);
            await m.addColumn(transactions, transactions.debtId);
            await m.addColumn(transactions, transactions.debtPaymentId);
          }
          if (from < 6) {
            await m.createTable(goals);
            await m.createTable(goalDeposits);
          }
          if (from < 7) {
            await m.createTable(splits);
            await m.createTable(splitMembers);
            await m.createTable(splitItems);
            await m.addColumn(transactions, transactions.splitId);
            // Dari < v5 tabel debts baru saja dibuat lengkap (sudah ada split_id).
            if (from >= 5) await m.addColumn(debts, debts.splitId);
          }
          if (from < 8) {
            await m.addColumn(transactions, transactions.billDue);
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
