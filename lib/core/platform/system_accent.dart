import 'package:flutter/services.dart';

/// Warna utama wallpaper layar utama (Android 8.1+), untuk aksen "Wallpaper".
/// Null bila tidak didukung atau di tes.
abstract final class SystemAccent {
  static const MethodChannel _channel = MethodChannel('com.capt.hitungin/theme');

  static Future<Color?> read() async {
    try {
      final int? argb = await _channel.invokeMethod<int>('systemAccent');
      return argb == null ? null : Color(argb);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
