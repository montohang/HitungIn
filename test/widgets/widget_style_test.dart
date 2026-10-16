import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/backup/data/backup_service.dart';
import 'package:hitungin/features/home/widget_sync.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';
import 'package:hitungin/features/widgets/data/widget_photo.dart';
import 'package:hitungin/features/widgets/data/widget_style.dart';

void main() {
  const accent = Color(0xFF5B4BDB);
  WidgetLook look(WidgetStyle s, {bool dark = true, bool pro = true}) =>
      resolveWidgetLook(s, accent: accent, dark: dark, isPro: pro);

  group('simpan & baca gaya', () {
    test('JSON bolak-balik utuh; nilai rusak → bawaan yang aman', () {
      const s = WidgetStyle(
          bg: WidgetBg.foto, gradient: 2, photoPath: '/x/w1.png', photoLuma: 0.8, focusY: 0.2, scrim: 40,
          transparency: 30, corner: WidgetCorner.bulat, text: WidgetText.gelap, hideAmounts: true);
      final m = decodeWidgetStyles(encodeWidgetStyles({12: s, 15: const WidgetStyle()}));
      expect(m[12], s);
      expect(m[15], const WidgetStyle());
      expect(decodeWidgetStyles('bukan json'), isEmpty);
      final bad = WidgetStyle.fromJson({'bg': 'neon', 'scrim': 999, 'transparency': -5, 'gradient': 9});
      expect((bad.bg, bad.scrim, bad.transparency, bad.gradient), (WidgetBg.tema, 60, 0, 2));
    });

    test('backup: gaya ikut, foto tidak (widget berfoto kembali ke Ikut tema)', () {
      final raw = encodeWidgetStyles({
        1: const WidgetStyle(bg: WidgetBg.foto, photoPath: '/x/a.png', corner: WidgetCorner.kotak),
        2: const WidgetStyle(bg: WidgetBg.aksen, transparency: 20),
      });
      final m = decodeWidgetStyles(stripWidgetPhotos(raw));
      expect((m[1]!.bg, m[1]!.photoPath, m[1]!.corner), (WidgetBg.tema, null, WidgetCorner.kotak));
      expect((m[2]!.bg, m[2]!.transparency), (WidgetBg.aksen, 20));
    });
  });

  group('tampilan akhir widget', () {
    test('Ikut tema mengikuti gelap/terang aplikasi', () {
      final d = look(const WidgetStyle());
      expect(d.colors, [const Color(0xFF1A1730)]);
      expect((d.textLight, d.button, d.buttonIcon), (true, accent, const Color(0xFFFFFFFF)));
      final l = look(const WidgetStyle(), dark: false);
      expect((l.colors.single, l.textLight), (const Color(0xFFFFFFFF), false));
    });

    test('Aksen: teks putih, tombol putih berikon aksen', () {
      final a = look(const WidgetStyle(bg: WidgetBg.aksen), dark: false);
      expect((a.colors.single, a.textLight, a.button, a.buttonIcon, a.bar), (accent, true, const Color(0xFFFFFFFF), accent, const Color(0xFFFFFFFF)));
    });

    test('Gradien: dua warna dari aksen; "Lembut" memakai teks gelap', () {
      final g = look(const WidgetStyle(bg: WidgetBg.gradien));
      expect(g.colors, hasLength(2));
      expect(g.colors.first, accent);
      expect(look(const WidgetStyle(bg: WidgetBg.gradien, gradient: 2)).textLight, isFalse);
    });

    test('Foto hanya untuk Pro dan hanya bila fotonya ada', () {
      const s = WidgetStyle(bg: WidgetBg.foto, photoPath: '/x/a.png');
      expect(look(s).photoPath, '/x/a.png');
      expect(look(s, pro: false).photoPath, isNull, reason: 'tanpa Pro → ikut tema');
      expect(look(const WidgetStyle(bg: WidgetBg.foto)).photoPath, isNull);
    });

    test('Foto terang tanpa lapisan → teks gelap; lapisan gelap → teks putih', () {
      final bright = look(const WidgetStyle(bg: WidgetBg.foto, photoPath: '/p', photoLuma: 0.85, scrim: 10));
      expect((bright.textLight, bright.scrim.a < 0.05 || bright.scrim.r > 0.9), (false, true));
      final dimmed = look(const WidgetStyle(bg: WidgetBg.foto, photoPath: '/p', photoLuma: 0.85, scrim: 45));
      expect(dimmed.textLight, isTrue);
      expect(dimmed.scrim, const Color(0xFF000000).withAlpha(115));
    });

    test('Warna teks manual menang atas otomatis; transparansi → alfa; sudut', () {
      final w = look(const WidgetStyle(bg: WidgetBg.aksen, text: WidgetText.gelap, transparency: 40, corner: WidgetCorner.kotak));
      expect((w.textLight, w.alpha, w.radiusDp), (false, 153, 10));
    });

    test('kecerahan foto dari piksel', () {
      expect(lumaOfRgba(Uint8List.fromList([255, 255, 255, 255, 0, 0, 0, 255])), closeTo(0.5, 0.001));
      expect(lumaOfRgba(Uint8List(0)), 0.5);
    });
  });

  test('ringkasan widget membawa tampilan per id & teks samaran', () {
    final s = buildWidgetSnapshot(
      now: DateTime(2026, 10, 17, 9),
      allowance: null,
      favorites: const [],
      categories: const [],
      hidden: false,
      fallbackLook: look(const WidgetStyle()),
      looks: {7: look(const WidgetStyle(bg: WidgetBg.aksen, hideAmounts: true))},
    );
    expect((s['look'] as Map)['colors'], [0xFF1A1730]);
    expect(((s['looks'] as Map)['7'] as Map)['hide'], true);
    expect((s['masked'] as Map)['jatah'], 'Rp ••••');
  });

  test('cadangan tidak membawa path foto widget', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    await db.settingsDao.write(
        SettingKeys.widgetStyles, encodeWidgetStyles({3: const WidgetStyle(bg: WidgetBg.foto, photoPath: '/data/w3.png')}));
    final snap = await BackupService(db).snapshot();
    final row = ((snap['tables']! as Map)['settings'] as List).cast<Map>().firstWhere((r) => r['key'] == SettingKeys.widgetStyles);
    expect(row['value'], isNot(contains('w3.png')));
    expect(decodeWidgetStyles(row['value'] as String)[3]!.bg, WidgetBg.tema);
    await db.close();
  });
}
