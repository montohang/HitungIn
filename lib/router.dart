import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/db/data_providers.dart';
import 'core/db/app_database.dart';
import 'core/utils/date_format.dart';
import 'features/debts/debts_screen.dart';
import 'features/goals/goal_achieved_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/rapor/rapor_screen.dart';
import 'features/splits/split_form_screen.dart';
import 'features/splits/splits_screen.dart';
import 'features/recap/recap_screen.dart';
import 'features/widgets/widget_settings_screen.dart';
import 'features/home/home_layout_screen.dart';
import 'features/backup/backup_screen.dart';
import 'features/bills/bills_screen.dart';
import 'features/budget/atur_budget_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/budget/template_budget_screen.dart';
import 'features/export/data/export_report.dart' show ExportFormat;
import 'features/export/export_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/dev/design_gallery_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/first_wallet_screen.dart';
import 'features/onboarding/pin_setup_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/premium/data/pro_limits.dart';
import 'features/premium/premium_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reports/laporan_screen.dart';
import 'features/security/app_gate.dart';
import 'features/security/lock_screen.dart';
import 'features/security/security_screen.dart';
import 'features/settings/appearance_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/networth/networth_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/transactions/catat_screen.dart';
import 'features/transactions/riwayat_screen.dart';
import 'features/transactions/tx_detail_screen.dart';
import 'features/wallets/wallets_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Router aplikasi. Setiap perubahan [appGateProvider] (PIN dibuat,
/// onboarding selesai, terkunci/terbuka) memicu `gateRedirect` lagi.
final routerProvider = Provider<GoRouter>((ref) {
  final ValueNotifier<GateState> gate = ValueNotifier(ref.read(appGateProvider));
  ref.listen(appGateProvider, (_, next) => gate.value = next);

  final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: gate,
    redirect: (context, state) => gateRedirect(gate.value, state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: Routes.setupPin, builder: (_, __) => const PinSetupScreen()),
      GoRoute(path: Routes.setupWallet, builder: (_, __) => const FirstWalletScreen()),
      GoRoute(path: Routes.lock, builder: (_, __) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          // Urutan tab = desain: Beranda · Laporan · [+] · Budget · Lainnya.
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.laporan, builder: (_, __) => const LaporanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.budget, builder: (_, __) => const BudgetScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.lainnya, builder: (_, __) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: Routes.catat,
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: CatatScreen(
            initialText: state.uri.queryParameters['text'],
            editId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
            copyId: int.tryParse(state.uri.queryParameters['copy'] ?? ''),
            transfer: state.uri.queryParameters['kind'] == 'transfer',
            income: state.uri.queryParameters['kind'] == 'pemasukan',
            scan: state.uri.queryParameters['scan'] == '1',
          ),
        ),
      ),
      // Riwayat bukan tab lagi: dibuka dari "Lihat semua" / Laporan, dengan tombol kembali.
      GoRoute(
        path: Routes.riwayat,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RiwayatScreen(
          initialMonth: DateFmt.parseMonthKey(state.uri.queryParameters['month']),
          categoryId: int.tryParse(state.uri.queryParameters['category'] ?? ''),
          walletId: int.tryParse(state.uri.queryParameters['wallet'] ?? ''),
          kind: TxKind.values.where((k) => k.name == state.uri.queryParameters['kind']).firstOrNull,
        ),
      ),
      GoRoute(path: Routes.pengaturan, redirect: (_, __) => Routes.lainnya),
      GoRoute(
        path: Routes.aturBudget,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => AturBudgetScreen(
          month: DateFmt.parseMonthKey(state.uri.queryParameters['month']) ??
              ProviderScope.containerOf(context).read(currentMonthProvider),
          suggest: state.uri.queryParameters['saran'] == '1',
          preset: state.extra is BudgetPreset ? state.extra! as BudgetPreset : null,
        ),
      ),
      GoRoute(
        path: Routes.export,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ExportScreen(
          format: ExportFormat.values.where((f) => f.name == state.uri.queryParameters['format']).firstOrNull ?? ExportFormat.pdf,
        ),
      ),
      GoRoute(
        path: Routes.templateBudget,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => TemplateBudgetScreen(
          month: DateFmt.parseMonthKey(state.uri.queryParameters['month']) ??
              ProviderScope.containerOf(context).read(currentMonthProvider),
        ),
      ),
      GoRoute(
        path: Routes.premium,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => PremiumScreen(reason: ProReason.parse(state.uri.queryParameters['from'])),
      ),
      GoRoute(
        path: Routes.widget,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => WidgetSettingsScreen(initialId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
      ),
      GoRoute(
        path: Routes.rekap,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RecapScreen(initialOffset: int.tryParse(state.uri.queryParameters['minggu'] ?? '') ?? 0),
      ),
      GoRoute(
        path: Routes.rapor,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => RaporScreen(month: DateFmt.parseMonthKey(state.uri.queryParameters['bulan'])),
        routes: [
          GoRoute(path: 'arsip', parentNavigatorKey: _rootKey, builder: (_, __) => const RaporArchiveScreen()),
        ],
      ),
      GoRoute(
        path: Routes.kekayaan,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NetWorthScreen(),
      ),
      GoRoute(
        path: Routes.patungan,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SplitsScreen(),
        routes: [
          GoRoute(
            path: 'baru',
            parentNavigatorKey: _rootKey,
            builder: (_, __) => const SplitFormScreen(),
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => SplitDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'ubah',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => SplitFormScreen(editId: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.target,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => GoalsScreen(
          draft: goalDraftFrom(state.uri.queryParameters),
          openNew: state.uri.queryParameters['baru'] == '1',
        ),
        routes: [
          GoRoute(
            path: ':id',
            parentNavigatorKey: _rootKey,
            builder: (_, state) => GoalDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'tercapai',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => GoalAchievedScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.utang,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => DebtsScreen(
          openId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
          draft: debtDraftFrom(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: '/tx/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => TxDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      for (final (String path, Widget screen) in const [
        (Routes.dompet, WalletsScreen()),
        (Routes.kategori, CategoriesScreen()),
        (Routes.tagihan, BillsScreen()),
        (Routes.keamanan, SecurityScreen()),
        (Routes.gantiPin, ChangePinScreen()),
        (Routes.cadangan, BackupScreen()),
        (Routes.tampilan, AppearanceScreen()),
        (Routes.berulang, RecurringScreen()),
        (Routes.aturBeranda, HomeLayoutScreen()),
      ])
        GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (_, __) => screen),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, __) => const DesignGalleryScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
