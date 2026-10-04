import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/theme/app_colors.dart';
import 'package:hitungin/core/theme/app_theme.dart';
import 'package:hitungin/core/theme/app_tokens.dart';
import 'package:hitungin/core/theme/theme_controller.dart';
import 'package:hitungin/features/dev/design_gallery_screen.dart';

double _contrast(Color a, Color b) {
  final double l1 = a.computeLuminance();
  final double l2 = b.computeLuminance();
  final double hi = l1 > l2 ? l1 : l2;
  final double lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('tema default HitungIn adalah gelap', () {
    const s = ThemeSettings();
    expect(s.mode, AppThemeMode.gelap);
    expect(s.flutterMode, ThemeMode.dark);
  });

  for (final preset in AccentPreset.values) {
    test('kontras teks memenuhi WCAG AA — ${preset.label}', () {
      for (final AppColors c in [AppColors.light(preset.light), AppColors.dark(preset.dark)]) {
        expect(_contrast(c.ink, c.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(c.muted, c.surface), greaterThanOrEqualTo(4.5));
        // Teks putih tebal 15–16 px di atas tombol aksen: minimal 3:1 (teks besar/tebal).
        expect(_contrast(c.onAccent, c.accent), greaterThanOrEqualTo(3.0));
      }
    });
  }

  Future<void> pumpGallery(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: theme, home: const DesignGalleryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('galeri tampil tanpa error di mode gelap', (tester) async {
    await pumpGallery(tester, AppTheme.dark(AccentPreset.indigo));
    expect(find.text('HitungIn'), findsOneWidget);
    expect(find.text('Rp8.450.000'), findsOneWidget);
  });

  testWidgets('galeri tampil tanpa error di mode terang', (tester) async {
    await pumpGallery(tester, AppTheme.light(AccentPreset.teal));
    expect(find.text('Selamat pagi, Rina'), findsOneWidget);
  });
}
