import 'dart:ui' show Brightness, Color, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/theme/theme_controller.dart';
import '../premium/pro_controller.dart';
import '../settings/data/settings_dao.dart';
import 'data/widget_style.dart';

/// Gaya tersimpan per id widget.
final widgetStylesProvider = StreamProvider<Map<int, WidgetStyle>>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.widgetStyles).map(decodeWidgetStyles),
);

/// Aksen & gelap/terang tema aplikasi saat ini (untuk widget & pratinjau).
final widgetThemeProvider = Provider<({Color accent, bool dark})>((ref) {
  final ThemeSettings t = ref.watch(themeControllerProvider);
  final bool dark = switch (t.mode) {
    AppThemeMode.gelap || AppThemeMode.amoled => true,
    AppThemeMode.terang => false,
    AppThemeMode.sistem => PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  };
  return (accent: dark ? t.accentDark : t.accentLight, dark: dark);
});

/// Tampilan akhir: bawaan (widget yang belum diatur) + per id.
final widgetLooksProvider = Provider<({WidgetLook fallback, Map<int, WidgetLook> byId})>((ref) {
  final ({Color accent, bool dark}) theme = ref.watch(widgetThemeProvider);
  final bool isPro = ref.watch(isProProvider);
  final Map<int, WidgetStyle> styles = ref.watch(widgetStylesProvider).valueOrNull ?? const {};
  WidgetLook look(WidgetStyle s) => resolveWidgetLook(s, accent: theme.accent, dark: theme.dark, isPro: isPro);
  return (
    fallback: look(const WidgetStyle()),
    byId: {for (final e in styles.entries) e.key: look(e.value)},
  );
});

Future<void> saveWidgetStyle(SettingsDao dao, Map<int, WidgetStyle> current, int id, WidgetStyle style) =>
    dao.write(SettingKeys.widgetStyles, encodeWidgetStyles({...current, id: style}));
