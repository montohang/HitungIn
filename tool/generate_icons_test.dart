// Membuat semua ikon peluncur Android & ikon Play Store dari LogoMark.
// Jalankan setelah logo atau varian berubah:
//
//   flutter test tool/generate_icons_test.dart
//
// Hasil: android/app/src/main/res/mipmap-*/…, mipmap-anydpi-v26/…,
// values/ic_launcher_colors.xml, branding/play_store_icon_512.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/branding/app_icon_variants.dart';
import 'package:hitungin/core/widgets/logo_mark.dart';

const String res = 'android/app/src/main/res';

/// Kepadatan Android → faktor skala dari dp.
const Map<String, double> densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4};

/// Konten logo (24..76 × 22..78 dari 100) harus muat di lingkaran aman 66dp
/// dari kanvas 108dp → skala 0.78.
const double adaptiveScale = 0.78;

Future<void> _png(String path, int px, LogoPainter painter) async {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  painter.paint(Canvas(rec), Size(px.toDouble(), px.toDouble()));
  final ui.Image img = await rec.endRecording().toImage(px, px);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

LogoPainter _logo(AppIconVariant v, {required bool withBg, double scale = 1, double radius = 0.28}) => LogoPainter(
      bg: withBg ? v.bg : const Color(0x00000000),
      fg: v.fg,
      coin: v.coin,
      ring: v.ring,
      radiusFactor: radius,
      scale: scale,
      coinOffset: 0,
    );

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buat ikon peluncur', () async {
    final StringBuffer colors = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Dibuat oleh tool/generate_icons_test.dart — jangan diedit manual. -->\n<resources>\n');

    for (final AppIconVariant v in AppIconVariant.values) {
      colors.writeln('    <color name="${v.mipmap}_bg">${_hex(v.bg)}</color>');
      for (final MapEntry<String, double> d in densities.entries) {
        // Lapisan depan ikon adaptif (108dp, latar transparan).
        await _png('$res/mipmap-${d.key}/${v.mipmap}_fg.png', (108 * d.value).round(), _logo(v, withBg: false, scale: adaptiveScale));
        // Ikon lama Android 7 (48dp, kotak membulat dengan sedikit jarak tepi).
        await _png('$res/mipmap-${d.key}/${v.mipmap}.png', (48 * d.value).round(), _logo(v, withBg: true, scale: 0.92));
      }
      File('$res/mipmap-anydpi-v26/${v.mipmap}.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<!-- Dibuat oleh tool/generate_icons_test.dart -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/${v.mipmap}_bg" />
    <foreground android:drawable="@mipmap/${v.mipmap}_fg" />
    <monochrome android:drawable="@mipmap/ic_launcher_mono" />
</adaptive-icon>
''');
    }
    colors.writeln('</resources>');
    File('$res/values/ic_launcher_colors.xml').writeAsStringSync(colors.toString());

    // Ikon bertema Android 13+: satu warna, sistem yang mewarnai.
    for (final MapEntry<String, double> d in densities.entries) {
      await _png(
        '$res/mipmap-${d.key}/ic_launcher_mono.png',
        (108 * d.value).round(),
        LogoPainter(
          bg: const Color(0x00000000),
          fg: const Color(0xFFFFFFFF),
          coin: const Color(0xFFFFFFFF),
          ring: const Color(0x00000000),
          radiusFactor: 0,
          scale: adaptiveScale,
          coinOffset: 0,
        ),
      );
    }

    // Play Store: 512×512 tanpa sudut membulat (Play yang membulatkan).
    await _png('branding/play_store_icon_512.png', 512, _logo(AppIconVariant.standar, withBg: true, radius: 0));
  });
}
