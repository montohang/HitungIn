import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../settings/data/settings_dao.dart';
import 'pin_service.dart';

/// Status "pintu masuk" aplikasi yang menentukan layar mana yang boleh dibuka.
@immutable
class GateState {
  const GateState({this.onboardingDone = false, this.hasPin = false, this.unlocked = false});

  final bool onboardingDone;
  final bool hasPin;

  /// Hanya di memori — setiap aplikasi dibuka mulai terkunci.
  final bool unlocked;

  bool get locked => hasPin && !unlocked;

  GateState copyWith({bool? onboardingDone, bool? hasPin, bool? unlocked}) => GateState(
        onboardingDone: onboardingDone ?? this.onboardingDone,
        hasPin: hasPin ?? this.hasPin,
        unlocked: unlocked ?? this.unlocked,
      );

  @override
  bool operator ==(Object other) =>
      other is GateState && other.onboardingDone == onboardingDone && other.hasPin == hasPin && other.unlocked == unlocked;

  @override
  int get hashCode => Object.hash(onboardingDone, hasPin, unlocked);

  @override
  String toString() => 'GateState(onboarding: $onboardingDone, pin: $hasPin, unlocked: $unlocked)';
}

Future<GateState> loadGateState(SettingsDao settings, PinService pin) async => GateState(
      onboardingDone: await settings.read(SettingKeys.onboardingDone) == 'true',
      hasPin: await pin.hasPin(),
    );

/// Dibaca sebelum `runApp` (lihat main.dart). Di tes dibiarkan default.
final initialGateProvider = Provider<GateState>((ref) => const GateState());

class AppGate extends Notifier<GateState> {
  @override
  GateState build() => ref.read(initialGateProvider);

  /// PIN baru dibuat saat onboarding — langsung dianggap terbuka.
  void pinCreated() => state = state.copyWith(hasPin: true, unlocked: true);

  Future<void> completeOnboarding() async {
    await ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.onboardingDone, 'true');
    state = state.copyWith(onboardingDone: true);
  }

  void unlock() => state = state.copyWith(unlocked: true);

  void lock() {
    if (state.hasPin) state = state.copyWith(unlocked: false);
  }
}

final appGateProvider = NotifierProvider<AppGate, GateState>(AppGate.new);

/// True selama dialog sistem tampil (sidik jari, pemilih berkas), supaya
/// kunci otomatis tidak terpicu oleh jeda lifecycle dari dialog itu sendiri.
final autoLockPausedProvider = StateProvider<bool>((ref) => false);

/// Jalankan [action] (yang membuka dialog sistem) tanpa memicu kunci otomatis.
Future<T> withAutoLockPaused<T>(WidgetRef ref, Future<T> Function() action) async {
  final notifier = ref.read(autoLockPausedProvider.notifier);
  notifier.state = true;
  try {
    return await action();
  } finally {
    notifier.state = false;
  }
}

abstract final class Routes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String setupPin = '/setup/pin';
  static const String setupBiometric = '/setup/biometric';
  static const String setupWallet = '/setup/wallet';
  static const String lock = '/lock';
  static const String home = '/home';
  static const String riwayat = '/riwayat';
  static const String laporan = '/laporan';
  static const String budget = '/budget';

  /// `?text=` (isi Catat Cepat) atau `?id=` (ubah transaksi).
  static const String catat = '/catat';
  static String tx(int id) => '/tx/$id';

  static const String pengaturan = '/pengaturan';
  static const String dompet = '/pengaturan/dompet';
  static const String kategori = '/pengaturan/kategori';
  static const String tagihan = '/tagihan';
  static const String keamanan = '/pengaturan/keamanan';
  static const String gantiPin = '/pengaturan/keamanan/ganti-pin';
  static const String cadangan = '/pengaturan/cadangan';
  static const String tampilan = '/pengaturan/tampilan';
  static const String gallery = '/dev/gallery';

  static const Set<String> setup = {welcome, setupPin, setupBiometric, setupWallet};
}

/// Aturan redirect router, dipisah sebagai fungsi murni supaya mudah dites.
String? gateRedirect(GateState s, Uri uri) {
  final String path = uri.path;
  if (path == Routes.splash) return null;

  if (s.locked) {
    if (path == Routes.lock) return null;
    return Uri(path: Routes.lock, queryParameters: {'from': uri.toString()}).toString();
  }

  if (!s.onboardingDone) {
    if (Routes.setup.contains(path)) {
      // PIN sudah ada (mis. aplikasi ditutup di tengah onboarding) → lanjut ke dompet.
      return s.hasPin && path == Routes.welcome ? Routes.setupWallet : null;
    }
    return s.hasPin ? Routes.setupWallet : Routes.welcome;
  }

  if (path == Routes.lock) {
    final String? from = uri.queryParameters['from'];
    final bool valid = from != null &&
        from.startsWith('/') &&
        !from.startsWith(Routes.lock) &&
        !Routes.setup.contains(Uri.parse(from).path);
    return valid ? from : Routes.home;
  }
  if (Routes.setup.contains(path)) return Routes.home;
  return null;
}
