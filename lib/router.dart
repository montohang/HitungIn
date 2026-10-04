import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/date_format.dart';
import 'features/backup/backup_screen.dart';
import 'features/bills/bills_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/dev/design_gallery_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/biometric_setup_screen.dart';
import 'features/onboarding/first_wallet_screen.dart';
import 'features/onboarding/pin_setup_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/reports/laporan_screen.dart';
import 'features/security/app_gate.dart';
import 'features/security/lock_screen.dart';
import 'features/security/security_screen.dart';
import 'features/settings/appearance_screen.dart';
import 'features/settings/settings_screen.dart';
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
      GoRoute(path: Routes.setupBiometric, builder: (_, __) => const BiometricSetupScreen()),
      GoRoute(path: Routes.setupWallet, builder: (_, __) => const FirstWalletScreen()),
      GoRoute(path: Routes.lock, builder: (_, __) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.riwayat,
              builder: (_, state) => RiwayatScreen(
                initialMonth: DateFmt.parseMonthKey(state.uri.queryParameters['month']),
                categoryId: int.tryParse(state.uri.queryParameters['category'] ?? ''),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.laporan, builder: (_, __) => const LaporanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.budget, builder: (_, __) => const BudgetScreen())]),
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
          ),
        ),
      ),
      GoRoute(
        path: '/tx/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => TxDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      for (final (String path, Widget screen) in const [
        (Routes.pengaturan, SettingsScreen()),
        (Routes.dompet, WalletsScreen()),
        (Routes.kategori, CategoriesScreen()),
        (Routes.tagihan, BillsScreen()),
        (Routes.keamanan, SecurityScreen()),
        (Routes.gantiPin, ChangePinScreen()),
        (Routes.cadangan, BackupScreen()),
        (Routes.tampilan, AppearanceScreen()),
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
