import 'package:flutter/painting.dart';

/// Varian ikon peluncur. [key] dipakai di Android (nama komponen & berkas
/// mipmap) — jangan diubah setelah rilis.
enum AppIconVariant {
  standar('standar', 'Standar', bg: Color(0xFF5B4BDB), fg: Color(0xFFFFFFFF), coin: Color(0xFFF2C14E), ring: Color(0xFFD9A21F)),
  gelap('gelap', 'Gelap', bg: Color(0xFF1A1733), fg: Color(0xFFFFFFFF), coin: Color(0xFFF2C14E), ring: Color(0xFFD9A21F), pro: true),
  emas('emas', 'Emas', bg: Color(0xFFF2C14E), fg: Color(0xFF1A1733), coin: Color(0xFFFFFFFF), ring: Color(0xFFD9A21F), pro: true),
  terang('terang', 'Terang', bg: Color(0xFFFFFFFF), fg: Color(0xFF5B4BDB), coin: Color(0xFFF2C14E), ring: Color(0xFFD9A21F), pro: true);

  const AppIconVariant(this.key, this.label, {required this.bg, required this.fg, required this.coin, required this.ring, this.pro = false});

  final String key;
  final String label;
  final Color bg;
  final Color fg;
  final Color coin;
  final Color ring;

  /// Hanya untuk pengguna Pro.
  final bool pro;

  /// Nama berkas mipmap: `ic_launcher` untuk standar, `ic_launcher_<key>` lainnya.
  String get mipmap => this == standar ? 'ic_launcher' : 'ic_launcher_$key';

  static AppIconVariant parse(String? key) => values.where((v) => v.key == key).firstOrNull ?? standar;
}
