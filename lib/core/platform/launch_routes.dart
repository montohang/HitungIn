import 'package:flutter/services.dart';

/// Layar yang boleh dibuka dari luar aplikasi (widget, tile Quick Settings,
/// pintasan ikon). Selain itu diabaikan, supaya intent dari aplikasi lain tidak
/// bisa membuka layar sembarangan.
bool isAllowedLaunchRoute(String route) {
  final Uri? u = Uri.tryParse(route);
  if (u == null || u.hasScheme || u.hasAuthority) return false;
  return const {'/catat', '/riwayat', '/home'}.contains(u.path);
}

/// Route dari widget/tile/pintasan (P1-2). Android mengirim route saat
/// aplikasi dibuka (`initialRoute`) atau saat sudah berjalan (`route`).
abstract final class LaunchRoutes {
  static const MethodChannel _channel = MethodChannel('com.capt.hitungin/launch');
  static bool _ready = false;

  static Future<void> init(void Function(String route) onRoute) async {
    if (_ready) return;
    _ready = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'route' && call.arguments is String) onRoute(call.arguments as String);
    });
    try {
      final String? initial = await _channel.invokeMethod<String>('initialRoute');
      if (initial != null) onRoute(initial);
    } on MissingPluginException {
      // Tes / platform tanpa kode Android.
    } on PlatformException {
      // Abaikan: aplikasi tetap terbuka di Beranda.
    }
  }
}
