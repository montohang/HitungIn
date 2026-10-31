import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../bills/bills_screen.dart' show activeBillsProvider;
import '../debts/data/debts_dao.dart';
import '../debts/debts_provider.dart';
import '../goals/data/goals_dao.dart';
import '../goals/goals_provider.dart';
import '../premium/pro_controller.dart';
import '../wallets/data/wallets_dao.dart';
import 'data/net_worth.dart';

final netItemsProvider = StreamProvider<List<NetItem>>(
  (ref) => ref.watch(appDatabaseProvider).netWorthDao.watchItems(),
);

final netSnapshotsProvider = StreamProvider<List<NetSnapshot>>(
  (ref) => ref.watch(appDatabaseProvider).netWorthDao.watchSnapshots(),
);

/// "10 g × Rp1.350.000 · diperbarui 34 hari lalu".
String netItemHint(NetItem i, DateTime now) {
  final int days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(i.updatedAt.year, i.updatedAt.month, i.updatedAt.day))
      .inDays;
  final String when = days <= 0
      ? 'diperbarui hari ini'
      : days == 1
          ? 'diperbarui kemarin'
          : 'diperbarui $days hari lalu';
  final String what = switch (i.kind) {
    NetItemKind.emas => '${formatGrams(i.milligrams ?? 0)} g × ${_rp(i.pricePerGram ?? 0)}',
    NetItemKind.properti => 'Taksiran',
    NetItemKind.pinjaman => 'Sisa pokok',
    _ => i.kind.label,
  };
  return '$what · $when';
}

String _rp(int v) => 'Rp${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

/// 10500 mg → "10,5".
String formatGrams(int mg) {
  final String s = (mg / 1000).toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

/// "10,5" / "10.5" → 10500 mg; null bila tidak valid.
int? parseGrams(String text) {
  final double? g = double.tryParse(text.trim().replaceAll(',', '.'));
  if (g == null || g < 0) return null;
  return (g * 1000).round();
}

/// Kekayaan bersih saat ini. Versi gratis: hanya komponen otomatis.
final netWorthProvider = Provider<NetWorth?>((ref) {
  final List<WalletBalance>? wallets = ref.watch(walletBalancesProvider).valueOrNull;
  final List<DebtWithPayments>? debts = ref.watch(debtsProvider).valueOrNull;
  final List<Bill>? bills = ref.watch(activeBillsProvider).valueOrNull;
  final List<NetItem>? items = ref.watch(netItemsProvider).valueOrNull;
  if (wallets == null || debts == null || bills == null || items == null) return null;
  final DateTime now = ref.watch(clockProvider)();
  final List<GoalWithDeposits> goals = ref.watch(goalsProvider).valueOrNull ?? const [];
  return computeNetWorth(
    wallets: wallets,
    debts: debts,
    bills: bills,
    items: items,
    includeManual: ref.watch(isProProvider),
    setAside: goals.where((g) => !g.goal.archived).fold(0, (s, g) => s + g.saved),
    hintOf: (i) => netItemHint(i, now),
  );
});

/// Catat kondisi bulan berjalan (dipanggil saat nilainya berubah); catatan
/// terakhir di suatu bulan = kondisi akhir bulan itu.
Future<void> recordNetSnapshot(AppDatabase db, NetWorth w, DateTime now) =>
    db.netWorthDao.saveSnapshot(now, assets: w.totalAssets, liabilities: w.totalLiabilities, now: now);

/// Perubahan dari catatan bulan lalu; null bila belum ada catatan.
int? netWorthDelta(List<NetSnapshot> snaps, NetWorth w, DateTime now) {
  final DateTime prev = DateTime(now.year, now.month - 1);
  final NetSnapshot? last = snaps.where((s) => s.month == prev).firstOrNull;
  return last == null ? null : w.net - (last.assets - last.liabilities);
}
