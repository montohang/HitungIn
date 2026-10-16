import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_dao.dart';
import '../db/providers.dart';
import 'accent_color.dart';
import 'app_tokens.dart';

/// Asal warna aksen (P2b).
enum AccentSource {
  /// Salah satu [AccentPreset].
  preset,

  /// Material You: warna aksen sistem dari wallpaper (Android 12+).
  wallpaper,

  /// Warna bebas / dari foto (Pro).
  custom,
}

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
    this.gradientBalanceCard = true,
    this.source = AccentSource.preset,
    this.custom,
    this.wallpaper,
  });

  /// Default HitungIn: GELAP.
  final AppThemeMode mode;
  final AccentPreset accent;

  /// Kartu saldo bergradien halus (opsional).
  final bool gradientBalanceCard;

  final AccentSource source;

  /// Warna bebas pilihan pengguna (sudah dibuat terbaca).
  final Color? custom;

  /// Warna aksen sistem (Material You), dibaca saat aplikasi dibuka; null bila
  /// HP tidak mendukung.
  final Color? wallpaper;

  /// Aksen yang benar-benar dipakai. Sumber yang tidak tersedia jatuh ke preset.
  Color get accentLight => switch (source) {
        AccentSource.custom when custom != null => custom!,
        AccentSource.wallpaper when wallpaper != null => ensureWhiteContrast(wallpaper!),
        _ => accent.light,
      };

  Color get accentDark => switch (source) {
        AccentSource.preset => accent.dark,
        _ when accentLight == accent.light => accent.dark,
        _ => darkVariant(accentLight),
      };

  String get accentLabel => switch (source) {
        AccentSource.custom when custom != null => 'Warna bebas',
        AccentSource.wallpaper when wallpaper != null => 'Wallpaper',
        _ => accent.label,
      };

  ThemeMode get flutterMode => switch (mode) {
        AppThemeMode.terang => ThemeMode.light,
        AppThemeMode.sistem => ThemeMode.system,
        AppThemeMode.gelap || AppThemeMode.amoled => ThemeMode.dark,
      };

  bool get isAmoled => mode == AppThemeMode.amoled;

  ThemeSettings copyWith({
    AppThemeMode? mode,
    AccentPreset? accent,
    bool? gradientBalanceCard,
    AccentSource? source,
    Color? custom,
    Color? wallpaper,
  }) =>
      ThemeSettings(
        mode: mode ?? this.mode,
        accent: accent ?? this.accent,
        gradientBalanceCard: gradientBalanceCard ?? this.gradientBalanceCard,
        source: source ?? this.source,
        custom: custom ?? this.custom,
        wallpaper: wallpaper ?? this.wallpaper,
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

  /// Dipakai setelah memulihkan cadangan (sudah tersimpan di database).
  void applyLoaded(ThemeSettings settings) => state = settings;

  void setMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    _save(SettingKeys.themeMode, mode.name);
  }

  void setAccent(AccentPreset accent) {
    state = state.copyWith(accent: accent, source: AccentSource.preset);
    _save(SettingKeys.themeAccent, accent.name);
    _save(SettingKeys.themeAccentSource, AccentSource.preset.name);
  }

  /// Material You (Android 12+).
  void setWallpaperAccent() {
    state = state.copyWith(source: AccentSource.wallpaper);
    _save(SettingKeys.themeAccentSource, AccentSource.wallpaper.name);
  }

  /// Warna bebas / dari foto (Pro); dibuat terbaca dengan teks putih.
  void setCustomAccent(Color color) {
    final Color safe = ensureWhiteContrast(color);
    state = state.copyWith(source: AccentSource.custom, custom: safe);
    _save(SettingKeys.themeAccentSource, AccentSource.custom.name);
    _save(SettingKeys.themeAccentCustom, '${safe.toARGB32()}');
  }

  /// Warna wallpaper terbaru dari sistem (dipanggil saat aplikasi dibuka/kembali).
  void setSystemWallpaper(Color? color) {
    if (color == null || color == state.wallpaper) return;
    state = state.copyWith(wallpaper: color);
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
    source: byName(AccentSource.values, all[SettingKeys.themeAccentSource]) ?? AccentSource.preset,
    custom: switch (int.tryParse(all[SettingKeys.themeAccentCustom] ?? '')) {
      final int v => Color(v),
      null => null,
    },
    // Desain: kartu saldo bergradien secara default.
    gradientBalanceCard: all[SettingKeys.themeGradientCard] != 'false',
  );
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
