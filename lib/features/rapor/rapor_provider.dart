import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../budget/data/budgets_dao.dart';
import '../debts/data/debts_dao.dart';
import '../debts/debts_provider.dart';
import '../goals/data/goals_dao.dart';
import '../goals/goals_provider.dart';
import '../settings/data/settings_dao.dart';
import '../wallets/data/wallets_dao.dart';
import 'data/rapor.dart';

final _allTxProvider = StreamProvider<List<Txn>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.transactions).watch();
});

final _allBillsProvider = StreamProvider<List<Bill>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.bills).watch();
});

final _allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.categories).watch();
});

final _allBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.budgets).watch();
});

final _recurringProvider = StreamProvider<List<RecurringTx>>(
  (ref) => ref.watch(appDatabaseProvider).recurringDao.watchAll(),
);

/// Pengeluaran berulang disetarakan per bulan.
int monthlyEquivalent(int amount, BillRepeat repeat) => switch (repeat) {
      BillRepeat.mingguan => (amount * 52 / 12).round(),
      BillRepeat.tahunan => (amount / 12).round(),
      _ => amount,
    };

/// Semua data rapor. Null selama belum termuat.
final raporInputProvider = FutureProvider<RaporInput?>((ref) async {
  final List<Txn>? txs = ref.watch(_allTxProvider).valueOrNull;
  final List<Bill>? bills = ref.watch(_allBillsProvider).valueOrNull;
  final List<Category>? cats = ref.watch(_allCategoriesProvider).valueOrNull;
  final List<WalletBalance>? wallets = ref.watch(walletBalancesProvider).valueOrNull;
  final List<DebtWithPayments>? debts = ref.watch(debtsProvider).valueOrNull;
  final List<GoalWithDeposits>? goals = ref.watch(goalsProvider).valueOrNull;
  final List<RecurringTx>? rec = ref.watch(_recurringProvider).valueOrNull;
  ref.watch(_allBudgetsProvider);
  ref.watch(currentDayProvider);
  if (txs == null || bills == null || cats == null || wallets == null || debts == null || goals == null || rec == null) {
    return null;
  }
  final DateTime now = ref.read(clockProvider)();
  final BudgetsDao budgetsDao = ref.read(appDatabaseProvider).budgetsDao;
  final List<RaporTx> raporTxs = [
    for (final t in txs)
      (
        kind: t.kind,
        amount: t.amount,
        categoryId: t.categoryId,
        at: t.occurredAt,
        billId: t.billId,
        billDue: t.billDue,
        auto: t.recurringId != null,
        note: t.note,
      ),
  ];
  // Budget per bulan: 13 bulan terakhir cukup untuk arsip + bulan berjalan.
  final Map<DateTime, List<RaporBudget>> budgets = {};
  for (int k = 0; k <= 13; k++) {
    final DateTime m = DateTime(now.year, now.month - k);
    // Batas sesudah penyesuaian bulan itu (sisa dibawa, pindah batas).
    budgets[m] = [for (final e in (await budgetsDao.limitsFor(m)).entries) (categoryId: e.key, limit: e.value)];
  }
  return RaporInput(
    txs: raporTxs,
    categoryNames: {for (final c in cats) c.id: c.name},
    bills: [
      for (final b in bills)
        (id: b.id, name: b.name, amount: b.amount, installment: b.installmentTotal != null, nextDue: b.nextDue, active: b.active),
    ],
    budgets: budgets,
    balanceNow: wallets.fold(0, (a, w) => a + w.balance),
    now: now,
    utangDue: [
      for (final d in debts)
        if (d.debt.direction == DebtDirection.utang && d.debt.dueDate != null) (amount: d.debt.amount, due: d.debt.dueDate!),
    ],
    recurringMonthly: [
      for (final r in rec)
        if (r.active && r.kind == TxKind.pengeluaran) monthlyEquivalent(r.amount, r.repeat),
    ],
    goalMoves: [
      for (final g in goals)
        for (final d in g.deposits) (name: g.goal.name, amount: d.amount, at: d.at, percentNow: g.percent),
    ],
    piutangLeft: debts.where((d) => d.debt.direction == DebtDirection.piutang).fold(0, (a, d) => a + d.left),
    piutangPeople: {
      for (final d in debts)
        if (d.debt.direction == DebtDirection.piutang && d.left > 0) d.debt.name.toLowerCase(),
    }.length,
  );
});

/// Rapor bulan [month] (tanggal 1). Null selama data belum termuat.
final raporProvider = Provider.family<Rapor?, DateTime>((ref, month) {
  final RaporInput? input = ref.watch(raporInputProvider).valueOrNull;
  return input == null ? null : computeRapor(input, month);
});

/// Bulan yang punya rapor, terbaru dulu.
final raporMonthsProvider = Provider<List<DateTime>>((ref) {
  final RaporInput? input = ref.watch(raporInputProvider).valueOrNull;
  return input == null ? const [] : raporMonths(input);
});

final raporMonthlyProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.raporMonthly).map((v) => v != 'false'),
);

final raporDismissedProvider = StreamProvider<String?>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.raporDismissed),
);

/// Prakiraan bulan berjalan (null = tidak ada yang perlu diperhatikan).
final forecastProvider = Provider<Forecast?>((ref) {
  final DateTime month = ref.watch(currentMonthProvider);
  final List<BudgetProgress>? budgets = ref.watch(budgetProgressProvider(month)).valueOrNull;
  final int? summary = ref.watch(_monthExpenseProvider(month)).valueOrNull;
  if (budgets == null || summary == null) return null;
  final BudgetProgress? total = budgets.where((b) => b.category == null).firstOrNull;
  return computeForecast(
    now: ref.read(clockProvider)(),
    spent: summary,
    totalLimit: total == null || total.budget.limitAmount <= 0 ? null : total.budget.limitAmount,
    categories: [
      for (final b in budgets)
        if (b.category != null) (name: b.category!.name, spent: b.spent, limit: b.budget.limitAmount),
    ],
  );
});


final _monthExpenseProvider = StreamProvider.family<int, DateTime>((ref, month) {
  final DateTime to = DateTime(month.year, month.month + 1);
  return ref.watch(appDatabaseProvider).transactionsDao.watchSummary(month, to).map((s) => s.expense);
});
