import 'dart:ui' show Color;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/providers.dart';
import 'package:hitungin/core/theme/accent_color.dart';
import 'package:hitungin/core/theme/app_tokens.dart';
import 'package:hitungin/core/theme/theme_controller.dart';

void main() {
  test('warna terlalu terang digelapkan sampai teks putih terbaca (≥ 4,5:1)', () {
    const yellow = Color(0xFFF2C14E);
    expect(contrastOnWhite(yellow), lessThan(4.5));
    final safe = ensureWhiteContrast(yellow);
    expect(contrastOnWhite(safe), greaterThanOrEqualTo(4.5));
    expect(HSL.of(safe).hue, closeTo(HSL.of(yellow).hue, 2), reason: 'ronanya tetap');
    expect(ensureWhiteContrast(AccentPreset.indigo.light), AccentPreset.indigo.light, reason: 'yang sudah terbaca tidak diubah');
  });

  test('warna dari foto: rona menonjol dulu, abu-abu diabaikan, semuanya terbaca', () {
    Uint8List px(List<List<int>> rgb) => Uint8List.fromList([for (final c in rgb) ...c, 255]);
    final List<List<int>> pixels = [
      for (int i = 0; i < 6; i++) [220, 60, 60], // merah dominan
      for (int i = 0; i < 3; i++) [40, 90, 200], // biru
      for (int i = 0; i < 5; i++) [128, 128, 128], // abu-abu → diabaikan
    ];
    final List<Color> p = paletteFromRgba(Uint8List.fromList([for (final c in pixels) ...px([c])]));
    expect(p, hasLength(2));
    expect(HSL.of(p.first).hue, lessThan(30));
    expect(HSL.of(p.last).hue, inInclusiveRange(200, 240));
    for (final c in p) {
      expect(contrastOnWhite(c), greaterThanOrEqualTo(4.5));
    }
  });

  group('sumber aksen', () {
    test('preset / wallpaper / bebas → warna akhir; wallpaper tak tersedia → preset', () {
      const base = ThemeSettings(accent: AccentPreset.teal);
      expect(base.accentLight, AccentPreset.teal.light);
      final wall = base.copyWith(source: AccentSource.wallpaper);
      expect((wall.accentLight, wall.accentLabel), (AccentPreset.teal.light, 'Teal'), reason: 'HP tanpa Material You');
      final withWall = wall.copyWith(wallpaper: const Color(0xFF3B6EA8));
      expect(withWall.accentLabel, 'Wallpaper');
      expect(contrastOnWhite(withWall.accentLight), greaterThanOrEqualTo(4.5));
      final free = base.copyWith(source: AccentSource.custom, custom: const Color(0xFF8B2E5A));
      expect((free.accentLight, free.accentLabel), (const Color(0xFF8B2E5A), 'Warna bebas'));
      expect(free.accentDark, isNot(free.accentLight));
    });

    test('tersimpan & terbaca lagi; warna bebas dibuat terbaca saat disimpan', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
      container.read(themeControllerProvider.notifier).setCustomAccent(const Color(0xFFF2C14E));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = await loadThemeSettings(db.settingsDao);
      expect(loaded.source, AccentSource.custom);
      expect(contrastOnWhite(loaded.accentLight), greaterThanOrEqualTo(4.5));
      container.read(themeControllerProvider.notifier).setAccent(AccentPreset.mawar);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final again = await loadThemeSettings(db.settingsDao);
      expect((again.source, again.accentLight), (AccentSource.preset, AccentPreset.mawar.light));
      container.dispose();
      await db.close();
    });
  });
}
