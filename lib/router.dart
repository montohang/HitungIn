import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dev/design_gallery_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/biometric_setup_screen.dart';
import 'features/onboarding/first_wallet_screen.dart';
import 'features/onboarding/pin_setup_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/security/app_gate.dart';
import 'features/security/lock_screen.dart';

/// Router aplikasi. Setiap perubahan [appGateProvider] (PIN dibuat,
/// onboarding selesai, terkunci/terbuka) memicu `gateRedirect` lagi.
final routerProvider = Provider<GoRouter>((ref) {
  final ValueNotifier<GateState> gate = ValueNotifier(ref.read(appGateProvider));
  ref.listen(appGateProvider, (_, next) => gate.value = next);

  final GoRouter router = GoRouter(
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
      GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
      if (kDebugMode) GoRoute(path: Routes.gallery, builder: (_, __) => const DesignGalleryScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});
