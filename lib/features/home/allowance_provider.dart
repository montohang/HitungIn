import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../bills/bills_screen.dart' show activeBillsProvider;
import '../bills/data/bill_due.dart';
import '../debts/data/debts_dao.dart';
import '../debts/debts_provider.dart';
import '../goals/data/goals.dart';
import '../goals/data/goals_dao.dart';
import '../goals/goals_provider.dart';
import '../settings/data/settings_dao.dart';
import '../transactions/data/transactions_dao.dart' show TxDetail;
import '../wallets/data/wallets_dao.dart';
import 'data/allowance.dart';

/// "25" → 25; kosong/rusak → 1 (bulan kalender).
int parsePayday(String? v) {
  final int? d = int.tryParse(v ?? '');
  return d != null && d >= 1 && d <= 31 ? d : 1;
}

/// "3,7" → {3, 7}.
Set<int> parseIdSet(String? v) => {
      for (final String p in (v ?? '').split(','))
        if (int.tryParse(p.trim()) != null) int.parse(p.trim()),
    };

String formatIdSet(Set<int> ids) => (ids.toList()..sort()).join(',');

final paydayProvider = StreamProvider<int>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.allowancePayday).map(parsePayday),
);

final allowanceExcludedProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.allowanceExcluded).map(parseIdSet),
);

final _recurringProvider = StreamProvider<List<RecurringTx>>(
  (ref) => ref.watch(appDatabaseProvider).recurringDao.watchAll(),
);

final _todayExpensesProvider = StreamProvider<List<TxDetail>>((ref) {
  final DateTime day = ref.watch(currentDayProvider);
  return ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchBetween(day, day.add(const Duration(days: 1)), kind: TxKind.pengeluaran);
});

/// Tanggal transaksi berulang pemasukan berkategori "Gaji" (saran tanggal gajian).
final suggestedPaydayProvider = Provider<int?>((ref) {
  final List<RecurringTx> rec = ref.watch(_recurringProvider).valueOrNull ?? const [];
  final List<Category> cats = ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
  final Set<int> salary = {for (final c in cats) if (c.kind == TxKind.pemasukan && c.name.toLowerCase() == 'gaji') c.id};
  for (final RecurringTx r in rec) {
    if (r.active && r.kind == TxKind.pemasukan && salary.contains(r.categoryId)) return r.anchorDay;
  }
  return null;
});

/// Jatah hari ini (P1-1). Null selama data belum termuat.
final allowanceProvider = Provider<Allowance?>((ref) {
  final List<WalletBalance>? wallets = ref.watch(walletBalancesProvider).valueOrNull;
  final int? payday = ref.watch(paydayProvider).valueOrNull;
  final Set<int>? excluded = ref.watch(allowanceExcludedProvider).valueOrNull;
  final List<Bill>? bills = ref.watch(activeBillsProvider).valueOrNull;
  final List<RecurringTx>? rec = ref.watch(_recurringProvider).valueOrNull;
  final List<TxDetail>? today = ref.watch(_todayExpensesProvider).valueOrNull;
  final List<DebtWithPayments>? debts = ref.watch(debtsProvider).valueOrNull;
  final List<GoalWithDeposits>? goals = ref.watch(goalsProvider).valueOrNull;
  final DateTime month = ref.watch(currentMonthProvider);
  final budgets = ref.watch(budgetProgressProvider(month)).valueOrNull;
  if (wallets == null || payday == null || excluded == null || bills == null || rec == null || today == null || budgets == null || debts == null || goals == null) {
    return null;
  }
  ref.watch(currentDayProvider);
  final Set<int> counted = {for (final w in wallets) if (!excluded.contains(w.wallet.id)) w.wallet.id};
  final total = budgets.where((b) => b.category == null).firstOrNull;
  // Target yang diarsipkan tidak lagi menahan uangnya.
  final List<GoalWithDeposits> held = [for (final g in goals) if (!g.goal.archived) g];
  return computeAllowance(
    now: ref.read(clockProvider)(),
    payday: payday,
    balance: wallets.where((w) => counted.contains(w.wallet.id)).fold(0, (s, w) => s + w.balance),
    spentToday: today.where((d) => counted.contains(d.tx.walletId)).fold(0, (s, d) => s + d.tx.amount),
    bills: [
      for (final b in bills)
        (name: b.name, amount: b.amount, next: b.nextDue, repeat: b.repeat, anchorDay: b.anchorDay, times: installmentOf(b)?.remainingCount),
    ],
    recurring: [
      for (final r in rec)
        if (r.active && r.kind == TxKind.pengeluaran && counted.contains(r.walletId))
          (name: r.note.isEmpty ? 'Transaksi berulang' : r.note, amount: r.amount, next: r.nextRun, repeat: r.repeat, anchorDay: r.anchorDay, times: null),
    ],
    // Utangku yang punya jatuh tempo: sisanya harus disiapkan sebelum gajian.
    debts: [
      for (final d in debts)
        if (d.debt.direction == DebtDirection.utang && d.debt.dueDate != null && d.left > 0)
          (name: d.debt.name, amount: d.left, next: d.debt.dueDate!, repeat: BillRepeat.sekali, anchorDay: d.debt.dueDate!.day, times: 1),
    ],
    setAside: setAsideFrom(held.map((g) => g.facts), counted),
    setAsideNames: [
      for (final g in held)
        if (setAsideFrom([g.facts], counted) > 0) g.goal.name,
    ],
    budgetLeft: total == null ? null : total.budget.limitAmount - total.spent,
  );
});

Future<void> setPayday(SettingsDao dao, int day) => dao.write(SettingKeys.allowancePayday, '$day');

Future<void> setWalletInAllowance(SettingsDao dao, Set<int> excluded, int walletId, bool counted) {
  final Set<int> next = {...excluded};
  counted ? next.remove(walletId) : next.add(walletId);
  return dao.write(SettingKeys.allowanceExcluded, formatIdSet(next));
}
