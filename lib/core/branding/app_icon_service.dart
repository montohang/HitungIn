import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_icon_variants.dart';

/// Ganti ikon peluncur (Android). Implementasinya di MainActivity.kt.
abstract interface class AppIconService {
  Future<AppIconVariant> current();
  Future<void> set(AppIconVariant variant);
}

class AndroidAppIconService implements AppIconService {
  const AndroidAppIconService([this._channel = const MethodChannel('com.capt.hitungin/app_icon')]);

  final MethodChannel _channel;

  @override
  Future<AppIconVariant> current() async {
    try {
      return AppIconVariant.parse(await _channel.invokeMethod<String>('get'));
    } on MissingPluginException {
      return AppIconVariant.standar;
    }
  }

  @override
  Future<void> set(AppIconVariant variant) => _channel.invokeMethod<void>('set', {'key': variant.key});
}

final appIconServiceProvider = Provider<AppIconService>((ref) => const AndroidAppIconService());

final currentAppIconProvider = FutureProvider.autoDispose<AppIconVariant>((ref) => ref.watch(appIconServiceProvider).current());
