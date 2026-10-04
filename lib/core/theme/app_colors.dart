import 'package:flutter/material.dart';

/// Token warna HitungIn. Semua widget mengambil warna dari sini
/// (`context.colors`), tidak pernah menulis kode hex langsung.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.seg,
    required this.ink,
    required this.muted,
    required this.sub,
    required this.sub2,
    required this.line,
    required this.line2,
    required this.track,
    required this.chip,
    required this.goodSoft,
    required this.goodInk,
    required this.good,
    required this.warnSoft,
    required this.warnInk,
    required this.warnBar,
    required this.dangerSoft,
    required this.danger,
    required this.dangerBar,
    required this.card,
    required this.onCard,
    required this.onCardMuted,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.onAccent,
    required this.gold,
  });

  /// Latar layar.
  final Color bg;

  /// Kartu, input, nav bar.
  final Color surface;

  /// Alas segmented control.
  final Color seg;

  /// Teks & angka utama.
  final Color ink;

  /// Teks keterangan (kontras ≥ 4.5:1).
  final Color muted;

  /// Teks pendukung.
  final Color sub;
  final Color sub2;

  /// Garis pembatas & garis input.
  final Color line;
  final Color line2;

  /// Rel progress bar.
  final Color track;

  /// Chip tidak terpilih.
  final Color chip;

  /// Pemasukan & status baik.
  final Color goodSoft;
  final Color goodInk;
  final Color good;

  /// Peringatan (budget ≥ 80%).
  final Color warnSoft;
  final Color warnInk;
  final Color warnBar;

  /// Bahaya (lewat batas, hapus).
  final Color dangerSoft;
  final Color danger;
  final Color dangerBar;

  /// Kartu saldo gelap & teks di atasnya.
  final Color card;
  final Color onCard;
  final Color onCardMuted;

  /// Warna aksen pilihan pengguna.
  final Color accent;

  /// Aksen untuk teks/link (lebih terang di mode gelap).
  final Color accentText;

  /// Latar lembut berbasis aksen (tile ikon, chip sekunder).
  final Color accentSoft;
  final Color onAccent;

  /// Emas koin — konstan di semua tema.
  final Color gold;

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  factory AppColors.light(Color accent) => AppColors(
        bg: const Color(0xFFF7F6FB),
        surface: const Color(0xFFFFFFFF),
        seg: const Color(0xFFECEAF3),
        ink: const Color(0xFF17152B),
        muted: const Color(0xFF6B6782),
        sub: const Color(0xFF5E5A75),
        sub2: const Color(0xFF3A3652),
        line: const Color(0xFFECEAF3),
        line2: const Color(0xFFDCD9E8),
        track: const Color(0xFFEFEDF5),
        chip: const Color(0xFFF1F0F6),
        goodSoft: const Color(0xFFE6F4EE),
        goodInk: const Color(0xFF11694B),
        good: const Color(0xFF157F5B),
        warnSoft: const Color(0xFFFDF1E3),
        warnInk: const Color(0xFFB45309),
        warnBar: const Color(0xFFD97706),
        dangerSoft: const Color(0xFFFDF3F2),
        danger: const Color(0xFFB42318),
        dangerBar: const Color(0xFFB42318),
        card: const Color(0xFF1A1733),
        onCard: const Color(0xFFFFFFFF),
        onCardMuted: const Color(0xFFC9C4E6),
        accent: accent,
        accentText: accent,
        accentSoft: accent.withAlpha(0x1F),
        onAccent: const Color(0xFFFFFFFF),
        gold: const Color(0xFFF2C14E),
      );

  /// Mode gelap (default HitungIn).
  factory AppColors.dark(Color accent, {bool amoled = false}) => AppColors(
        bg: amoled ? const Color(0xFF000000) : const Color(0xFF0F0D1F),
        surface: amoled ? const Color(0xFF0E0C1A) : const Color(0xFF1A1730),
        seg: const Color(0xFF0B0918),
        ink: const Color(0xFFF3F1FA),
        muted: const Color(0xFFA5A0C0),
        sub: const Color(0xFFC3BFD9),
        sub2: const Color(0xFFD6D2E8),
        line: const Color(0xFF2A2645),
        line2: const Color(0xFF3A3558),
        track: const Color(0xFF2A2645),
        chip: const Color(0xFF25213D),
        goodSoft: const Color(0xFF123A2D),
        goodInk: const Color(0xFF7FE0B5),
        good: const Color(0xFF4CC79A),
        warnSoft: const Color(0xFF3A2A12),
        warnInk: const Color(0xFFF0B35A),
        warnBar: const Color(0xFFE59A2F),
        dangerSoft: const Color(0xFF3A1A1A),
        danger: const Color(0xFFF08A80),
        dangerBar: const Color(0xFFE5554A),
        card: amoled ? const Color(0xFF15122A) : const Color(0xFF24203F),
        onCard: const Color(0xFFFFFFFF),
        onCardMuted: const Color(0xFFC9C4E6),
        accent: accent,
        accentText: _mix(accent, const Color(0xFFFFFFFF), 0.4),
        accentSoft: accent.withAlpha(0x33),
        onAccent: const Color(0xFFFFFFFF),
        gold: const Color(0xFFF2C14E),
      );

  @override
  AppColors copyWith({Color? accent}) {
    if (accent == null) return this;
    final bool isDark = bg.computeLuminance() < 0.2;
    return isDark ? AppColors.dark(accent) : AppColors.light(accent);
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      seg: l(seg, other.seg),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      sub: l(sub, other.sub),
      sub2: l(sub2, other.sub2),
      line: l(line, other.line),
      line2: l(line2, other.line2),
      track: l(track, other.track),
      chip: l(chip, other.chip),
      goodSoft: l(goodSoft, other.goodSoft),
      goodInk: l(goodInk, other.goodInk),
      good: l(good, other.good),
      warnSoft: l(warnSoft, other.warnSoft),
      warnInk: l(warnInk, other.warnInk),
      warnBar: l(warnBar, other.warnBar),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      danger: l(danger, other.danger),
      dangerBar: l(dangerBar, other.dangerBar),
      card: l(card, other.card),
      onCard: l(onCard, other.onCard),
      onCardMuted: l(onCardMuted, other.onCardMuted),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      gold: l(gold, other.gold),
    );
  }
}
