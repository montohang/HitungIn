import 'package:flutter/widgets.dart';

/// Jarak — selalu kelipatan 4. Jangan memakai angka di luar daftar ini.
abstract final class AppSpace {
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;

  /// Tepi kiri-kanan layar.
  static const double screenH = x20;

  /// Tepi atas layar.
  static const double screenTop = x24;

  /// Jarak antar blok di satu layar.
  static const double block = x16;

  /// Padding kartu standar & kartu saldo.
  static const double card = x16;
  static const double cardHero = x20;

  /// Padding vertikal baris daftar.
  static const double row = x12;

  /// Area sentuh minimal.
  static const double touch = 44;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(screenH, screenTop, screenH, x24);
}

/// Radius sudut.
abstract final class AppRadius {
  /// Tile ikon, tombol kecil.
  static const double sm = 12;

  /// Tombol, input, keypad.
  static const double md = 16;

  /// Kartu.
  static const double lg = 24;

  /// Chip & progress bar.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Durasi & kurva animasi. Semua animasi wajib mati bila
/// `MediaQuery.disableAnimationsOf(context)` bernilai true.
abstract final class AppMotion {
  static const Duration press = Duration(milliseconds: 140);
  static const Duration fill = Duration(milliseconds: 900);
  static const Duration countUp = Duration(milliseconds: 1100);
  static const Duration stagger = Duration(milliseconds: 70);
  static const Duration sheet = Duration(milliseconds: 380);
  static const Curve easeOut = Cubic(0.2, 0.8, 0.2, 1);

  static const double pressScale = 0.96;
  static const double pressScaleCard = 0.98;
}

/// Pilihan warna aksen: 6 preset gratis + 4 khusus Pro.
/// Hijau & merah sengaja tidak dipakai — sudah berarti pemasukan & bahaya.
enum AccentPreset {
  indigo('Indigo', Color(0xFF5B4BDB), Color(0xFF6C5CE7)),
  ungu('Ungu', Color(0xFF7C3AED), Color(0xFF8B5CF6)),
  teal('Teal', Color(0xFF0F766E), Color(0xFF14897C)),
  mawar('Mawar', Color(0xFFBE185D), Color(0xFFD63C74)),
  biru('Biru', Color(0xFF2563EB), Color(0xFF3B74F0)),
  tembaga('Tembaga', Color(0xFFB45309), Color(0xFFC2620F)),
  plum('Plum', Color(0xFF86198F), Color(0xFFA62DAF), pro: true),
  laut('Laut', Color(0xFF075985), Color(0xFF0B76AD), pro: true),
  kopi('Kopi', Color(0xFF6F4E37), Color(0xFF8A6448), pro: true),
  arang('Arang', Color(0xFF334155), Color(0xFF5B6B82), pro: true);

  const AccentPreset(this.label, this.light, this.dark, {this.pro = false});

  final String label;

  /// Hanya bisa dipilih pengguna Pro.
  final bool pro;

  /// Aksen untuk mode terang.
  final Color light;

  /// Aksen untuk mode gelap — sedikit lebih terang agar teks putih
  /// di atas tombol tetap terbaca.
  final Color dark;
}
