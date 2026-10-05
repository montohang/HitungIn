import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/budget/data/budgets_dao.dart';
import '../../features/settings/data/settings_dao.dart';
import '../../features/transactions/data/transactions_dao.dart';
import '../../features/wallets/data/wallets_dao.dart';
import '../security/secure_store.dart';
import '../utils/dates.dart';
import 'app_database.dart';
import 'providers.dart';

/// Provider baca (stream) yang dipakai banyak layar. Semua otomatis
/// diperbarui saat tabel terkait berubah.

final walletBalancesProvider = StreamProvider<List<WalletBalance>>(
  (ref) => ref.watch(appDatabaseProvider).walletsDao.watchBalances(),
);

final activeCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(appDatabaseProvider).categoriesDao.watchActive(),
);

/// Waktu cadangan terakhir (milik perangkat ini).
final lastBackupProvider = StreamProvider<DateTime?>((ref) => ref
    .watch(appDatabaseProvider)
    .settingsDao
    .watch(SettingKeys.lastBackupAt)
    .map((v) => v == null ? null : DateTime.tryParse(v)));

/// Tombol mata di Beranda: sembunyikan nominal.
/// Peringatan budget 80% aktif (default ya).
final budgetWarnProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.budgetWarn80).map((v) => v != 'false'),
);

final hideBalanceProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.hideBalance).map((v) => v == 'true'),
);

final userNameProvider = StreamProvider<String?>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.userName),
);

final recentTxProvider = StreamProvider<List<TxDetail>>(
  (ref) => ref.watch(appDatabaseProvider).transactionsDao.watchRecent(limit: 5),
);

final txDetailProvider = StreamProvider.family<TxDetail?, int>(
  (ref, id) => ref.watch(appDatabaseProvider).transactionsDao.watchDetail(id),
);

/// Ringkasan satu bulan (kunci = tanggal 1 bulan itu).
final monthSummaryProvider = StreamProvider.family<PeriodSummary, DateTime>((ref, month) {
  final (DateTime from, DateTime to) = Dates.monthRange(month);
  return ref.watch(appDatabaseProvider).transactionsDao.watchSummary(from, to);
});

/// Laporan dengan filter dompet opsional (null = semua dompet).
typedef ReportKey = ({DateTime month, int? walletId});

final reportSummaryProvider = StreamProvider.family<PeriodSummary, ReportKey>((ref, k) {
  final (DateTime from, DateTime to) = Dates.monthRange(k.month);
  return ref.watch(appDatabaseProvider).transactionsDao.watchSummary(from, to, walletId: k.walletId);
});

final categoryTotalsProvider = StreamProvider.family<List<CategoryTotal>, ({DateTime month, TxKind kind, int? walletId})>((ref, k) {
  final (DateTime from, DateTime to) = Dates.monthRange(k.month);
  return ref.watch(appDatabaseProvider).transactionsDao.watchCategoryTotals(from, to, kind: k.kind, walletId: k.walletId);
});

final dailyExpenseProvider = StreamProvider.family<Map<DateTime, int>, ReportKey>((ref, k) {
  final (DateTime from, DateTime to) = Dates.monthRange(k.month);
  return ref.watch(appDatabaseProvider).transactionsDao.watchDailyExpense(from, to, walletId: k.walletId);
});

final monthlyTotalsProvider = StreamProvider.family<List<MonthTotal>, ({DateTime lastMonth, int months, int? walletId})>(
  (ref, k) => ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchMonthlyTotals(k.lastMonth, months: k.months, walletId: k.walletId),
);

final budgetProgressProvider = StreamProvider.family<List<BudgetProgress>, DateTime>(
  (ref, month) => ref.watch(appDatabaseProvider).budgetsDao.watchProgress(month),
);

/// Filter riwayat. Record → kesetaraan otomatis untuk kunci family.
typedef TxQuery = ({DateTime month, TxKind? kind, int? categoryId, String search});

final txListProvider = StreamProvider.family<List<TxDetail>, TxQuery>((ref, q) {
  final (DateTime from, DateTime to) = Dates.monthRange(q.month);
  return ref.watch(appDatabaseProvider).transactionsDao.watchBetween(
        from,
        to,
        kind: q.kind,
        categoryId: q.categoryId,
        search: q.search,
      );
});

/// Bulan berjalan (tanggal 1). Dipisah supaya bisa diganti di tes.
final currentMonthProvider = Provider<DateTime>((ref) {
  final DateTime now = ref.watch(clockProvider)();
  return DateTime(now.year, now.month);
});
