import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Membangun [ThemeData] Material 3 dari token HitungIn.
abstract final class AppTheme {
  static ThemeData light(AccentPreset accent) => _build(AppColors.light(accent.light), Brightness.light);

  static ThemeData dark(AccentPreset accent, {bool amoled = false}) =>
      _build(AppColors.dark(accent.dark, amoled: amoled), Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.danger,
      onError: c.onAccent,
      surface: c.surface,
      onSurface: c.ink,
      outline: c.line2,
      outlineVariant: c.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      fontFamily: AppFonts.body,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [c, AppText(ink: c.ink)],
    );

    final isDark = brightness == Brightness.dark;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.muted, fontFamily: AppFonts.body, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        border: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: c.line)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: c.line)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: c.accent, width: 1.5)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        showDragHandle: true,
        dragHandleColor: c.line2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? c.surface : c.ink,
        contentTextStyle: TextStyle(
          color: isDark ? c.ink : c.surface,
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
      ),
    );
  }
}
