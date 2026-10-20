import 'package:flutter/services.dart';

/// Menu Bagikan Android untuk teks (mis. "Tagih lewat WhatsApp"). Tanpa
/// izin dan tanpa membaca kontak; pengguna memilih aplikasinya sendiri.
abstract final class ShareText {
  static const MethodChannel _channel = MethodChannel('com.capt.hitungin/share');

  /// Selesai saat pengguna kembali ke HitungIn. False bila menu Bagikan tidak
  /// tersedia (tes / platform lain) — teks lalu disalin ke papan klip.
  static Future<bool> send(String text, {String title = 'Kirim lewat'}) async {
    try {
      await _channel.invokeMethod<void>('text', {'text': text, 'title': title});
      return true;
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }

  /// Bagikan gambar PNG [path] (harus di folder cache `share/`). False bila
  /// menu Bagikan tidak tersedia (tes / platform lain).
  static Future<bool> image(String path, {String? text, String title = 'Bagikan lewat'}) async {
    try {
      await _channel.invokeMethod<void>('image', {'path': path, 'text': text, 'title': title});
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
