import 'package:flutter/material.dart';

/// Dua keluarga huruf HitungIn, dibundel di assets/fonts.
abstract final class AppFonts {
  /// Sapaan & judul halaman.
  static const String display = 'BricolageGrotesque';

  /// Semua UI dan angka.
  static const String body = 'PlusJakartaSans';

  /// Angka sejajar (tabular) agar nominal tidak "melompat".
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

/// Skala teks. Gunakan lewat `context.text.<nama>`.
@immutable
class AppText extends ThemeExtension<AppText> {
  const AppText({required this.ink});

  final Color ink;

  TextStyle _b(double size, FontWeight w, {double? height, double? spacing}) => TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: spacing,
        color: ink,
      );

  /// Sapaan "Selamat pagi, Rina" — Bricolage 28/700.
  TextStyle get greeting => TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.56,
        color: ink,
      );

  /// Judul halaman ("Laporan", "Budget") — Bricolage 30/700.
  TextStyle get pageTitle => greeting.copyWith(fontSize: 30, height: 1.0, letterSpacing: -0.6);

  /// Judul sub-halaman di header — Bricolage 22/700.
  TextStyle get screenTitle => greeting.copyWith(fontSize: 22, height: 1.2, letterSpacing: -0.44);

  /// Saldo besar — Jakarta 34/700, tabular.
  TextStyle get amountXL =>
      _b(34, FontWeight.w700, height: 1.15, spacing: -0.68).copyWith(fontFeatures: AppFonts.tabular);

  /// Nominal sedang (kartu, total) — 26/800.
  TextStyle get amountL =>
      _b(26, FontWeight.w800, height: 1.2, spacing: -0.52).copyWith(fontFeatures: AppFonts.tabular);

  /// Judul seksi — 17/700.
  TextStyle get section => _b(17, FontWeight.w700, height: 1.3);

  /// Judul kartu / label kuat — 15/700.
  TextStyle get title => _b(15, FontWeight.w700, height: 1.35);

  /// Isi baris daftar — 15/600.
  TextStyle get item => _b(15, FontWeight.w600, height: 1.35);

  /// Isi paragraf — 15/400.
  TextStyle get body => _b(15, FontWeight.w400, height: 1.55);

  /// Keterangan — 13/500.
  TextStyle get caption => _b(13, FontWeight.w500, height: 1.45);

  /// Label kecil — 12/600.
  TextStyle get label => _b(12, FontWeight.w600, height: 1.3);

  /// Angka di baris daftar — 15/700, tabular.
  TextStyle get number => _b(15, FontWeight.w700, height: 1.35).copyWith(fontFeatures: AppFonts.tabular);

  @override
  AppText copyWith({Color? ink}) => AppText(ink: ink ?? this.ink);

  @override
  AppText lerp(ThemeExtension<AppText>? other, double t) {
    if (other is! AppText) return this;
    return AppText(ink: Color.lerp(ink, other.ink, t)!);
  }
}
