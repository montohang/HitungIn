import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_dao.dart';
import '../db/providers.dart';
import 'app_tokens.dart';

/// Pilihan mode tampilan di layar Tema & Warna.
enum AppThemeMode {
  gelap('Gelap'),
  terang('Terang'),
  amoled('AMOLED'),
  sistem('Sistem');

  const AppThemeMode(this.label);
  final String label;
}

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = AppThemeMode.gelap,
    this.accent = AccentPreset.indigo,
    this.gradientBalanceCard = false,
  });

  /// Default HitungIn: GELAP.
  final AppThemeMode mode;
  final AccentPreset accent;

  /// Kartu saldo bergradien halus (opsional).
  final bool gradientBalanceCard;

  ThemeMode get flutterMode => switch (mode) {
        AppThemeMode.terang => ThemeMode.light,
        AppThemeMode.sistem => ThemeMode.system,
        AppThemeMode.gelap || AppThemeMode.amoled => ThemeMode.dark,
      };

  bool get isAmoled => mode == AppThemeMode.amoled;

  ThemeSettings copyWith({AppThemeMode? mode, AccentPreset? accent, bool? gradientBalanceCard}) => ThemeSettings(
        mode: mode ?? this.mode,
        accent: accent ?? this.accent,
        gradientBalanceCard: gradientBalanceCard ?? this.gradientBalanceCard,
      );
}

/// Pilihan tema yang dibaca dari database sebelum `runApp`, supaya
/// layar pertama langsung tampil dengan tema yang benar (tanpa kedip).
/// Di tes dibiarkan default.
final initialThemeSettingsProvider = Provider<ThemeSettings>((ref) => const ThemeSettings());

/// Menyimpan pilihan tema ke tabel pengaturan.
class ThemeController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => ref.read(initialThemeSettingsProvider);

  void setMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    _save(SettingKeys.themeMode, mode.name);
  }

  void setAccent(AccentPreset accent) {
    state = state.copyWith(accent: accent);
    _save(SettingKeys.themeAccent, accent.name);
  }

  void setGradientBalanceCard(bool value) {
    state = state.copyWith(gradientBalanceCard: value);
    _save(SettingKeys.themeGradientCard, '$value');
  }

  void _save(String key, String value) => ref.read(appDatabaseProvider).settingsDao.write(key, value);
}

/// Membaca pilihan tema tersimpan. Nilai yang tidak dikenal diabaikan.
Future<ThemeSettings> loadThemeSettings(SettingsDao dao) async {
  final Map<String, String> all = await dao.readAll();
  T? byName<T extends Enum>(List<T> values, String? name) {
    for (final T v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  return ThemeSettings(
    mode: byName(AppThemeMode.values, all[SettingKeys.themeMode]) ?? AppThemeMode.gelap,
    accent: byName(AccentPreset.values, all[SettingKeys.themeAccent]) ?? AccentPreset.indigo,
    gradientBalanceCard: all[SettingKeys.themeGradientCard] == 'true',
  );
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
