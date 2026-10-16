import 'dart:convert';
import 'dart:ui' show Color;

/// Latar widget layar utama (P2b).
enum WidgetBg {
  tema('Ikut tema'),
  aksen('Aksen'),
  gradien('Gradien'),
  foto('Foto');

  const WidgetBg(this.label);
  final String label;
}

enum WidgetCorner {
  kotak('Kotak', 10),
  membulat('Membulat', 24),
  bulat('Bulat penuh', 40);

  const WidgetCorner(this.label, this.radiusDp);
  final String label;
  final int radiusDp;
}

enum WidgetText {
  otomatis('Otomatis'),
  terang('Terang'),
  gelap('Gelap');

  const WidgetText(this.label);
  final String label;
}

/// Pilihan gradien (nama untuk aksesibilitas); warnanya diturunkan dari aksen.
const List<String> widgetGradientNames = ['Senja', 'Laut', 'Lembut'];

/// Gaya satu widget, disimpan per `appWidgetId` (pengaturan `widget.styles`).
class WidgetStyle {
  const WidgetStyle({
    this.bg = WidgetBg.tema,
    this.gradient = 0,
    this.photoPath,
    this.photoLuma = 0.5,
    this.focusY = 0.5,
    this.scrim = 35,
    this.transparency = 0,
    this.corner = WidgetCorner.membulat,
    this.text = WidgetText.otomatis,
    this.hideAmounts = false,
  });

  final WidgetBg bg;

  /// Indeks [widgetGradientNames].
  final int gradient;

  /// Salinan foto di penyimpanan internal aplikasi (bukan galeri).
  final String? photoPath;

  /// Kecerahan rata-rata foto 0–1, untuk memilih warna teks otomatis.
  final double photoLuma;

  /// Bagian foto yang tampil secara vertikal: 0 = atas, 1 = bawah.
  final double focusY;

  /// Lapisan gelap/terang di atas foto, 0–60 (%).
  final int scrim;

  /// Transparansi seluruh widget, 0–80 (%).
  final int transparency;
  final WidgetCorner corner;
  final WidgetText text;

  /// Samarkan nominal di widget ini saja.
  final bool hideAmounts;

  WidgetStyle copyWith({
    WidgetBg? bg,
    int? gradient,
    String? photoPath,
    bool clearPhoto = false,
    double? photoLuma,
    double? focusY,
    int? scrim,
    int? transparency,
    WidgetCorner? corner,
    WidgetText? text,
    bool? hideAmounts,
  }) =>
      WidgetStyle(
        bg: bg ?? this.bg,
        gradient: gradient ?? this.gradient,
        photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
        photoLuma: photoLuma ?? this.photoLuma,
        focusY: focusY ?? this.focusY,
        scrim: scrim ?? this.scrim,
        transparency: transparency ?? this.transparency,
        corner: corner ?? this.corner,
        text: text ?? this.text,
        hideAmounts: hideAmounts ?? this.hideAmounts,
      );

  Map<String, Object?> toJson() => {
        'bg': bg.name,
        'gradient': gradient,
        if (photoPath != null) 'photo': photoPath,
        'luma': photoLuma,
        'focusY': focusY,
        'scrim': scrim,
        'transparency': transparency,
        'corner': corner.name,
        'text': text.name,
        'hide': hideAmounts,
      };

  static WidgetStyle fromJson(Object? j) {
    if (j is! Map) return const WidgetStyle();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    double num01(Object? v, double d) => v is num ? v.toDouble().clamp(0, 1) : d;
    int intIn(Object? v, int d, int min, int max) => v is num ? v.toInt().clamp(min, max) : d;
    return WidgetStyle(
      bg: pick(WidgetBg.values, j['bg'], WidgetBg.tema),
      gradient: intIn(j['gradient'], 0, 0, widgetGradientNames.length - 1),
      photoPath: j['photo'] is String ? j['photo'] as String : null,
      photoLuma: num01(j['luma'], 0.5),
      focusY: num01(j['focusY'], 0.5),
      scrim: intIn(j['scrim'], 35, 0, 60),
      transparency: intIn(j['transparency'], 0, 0, 80),
      corner: pick(WidgetCorner.values, j['corner'], WidgetCorner.membulat),
      text: pick(WidgetText.values, j['text'], WidgetText.otomatis),
      hideAmounts: j['hide'] == true,
    );
  }

  @override
  bool operator ==(Object other) => other is WidgetStyle && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// `{"12": {...}, "15": {...}}` → gaya per id widget.
Map<int, WidgetStyle> decodeWidgetStyles(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final Object? m = jsonDecode(raw);
    if (m is! Map) return const {};
    return {
      for (final MapEntry<dynamic, dynamic> e in m.entries)
        if (int.tryParse('${e.key}') != null) int.parse('${e.key}'): WidgetStyle.fromJson(e.value),
    };
  } on FormatException {
    return const {};
  }
}

String encodeWidgetStyles(Map<int, WidgetStyle> styles) =>
    jsonEncode({for (final e in styles.entries) '${e.key}': e.value.toJson()});

/// Tampilan akhir satu widget yang digambar Android (warna ARGB). Dihitung di
/// Dart supaya bisa dites; Kotlin tinggal menggambar.
class WidgetLook {
  const WidgetLook({
    required this.colors,
    required this.photoPath,
    required this.focusY,
    required this.scrim,
    required this.alpha,
    required this.radiusDp,
    required this.ink,
    required this.muted,
    required this.chip,
    required this.track,
    required this.button,
    required this.buttonIcon,
    required this.bar,
    required this.warn,
    required this.hideAmounts,
  });

  /// Satu warna = polos; dua warna = gradien diagonal. Diabaikan bila ada foto.
  final List<Color> colors;
  final String? photoPath;
  final double focusY;

  /// Warna lapisan di atas foto (alfa sudah termasuk).
  final Color scrim;

  /// Alfa seluruh latar 0–255 (dari transparansi).
  final int alpha;
  final int radiusDp;
  final Color ink, muted, chip, track, button, buttonIcon, bar, warn;
  final bool hideAmounts;

  bool get textLight => ink.computeLuminance() > 0.5;

  Map<String, Object?> toJson() => {
        'colors': [for (final c in colors) c.toARGB32()],
        if (photoPath != null) 'photo': photoPath,
        'focusY': focusY,
        'scrim': scrim.toARGB32(),
        'alpha': alpha,
        'radius': radiusDp,
        'ink': ink.toARGB32(),
        'muted': muted.toARGB32(),
        'chip': chip.toARGB32(),
        'track': track.toARGB32(),
        'button': button.toARGB32(),
        'buttonIcon': buttonIcon.toARGB32(),
        'bar': bar.toARGB32(),
        'warn': warn.toARGB32(),
        'hide': hideAmounts,
      };
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Dua warna gradien ke-[i] dari [accent].
List<Color> widgetGradient(int i, Color accent) => switch (i) {
      1 => [_mix(accent, const Color(0xFF000000), 0.3), _mix(accent, const Color(0xFF2FA3C4), 0.6)],
      2 => [_mix(accent, const Color(0xFFFFFFFF), 0.75), _mix(accent, const Color(0xFFFFFFFF), 0.45)],
      _ => [accent, _mix(accent, const Color(0xFFF2C14E), 0.55)],
    };

/// Gaya → tampilan akhir. Foto hanya untuk Pro; tanpa Pro / tanpa foto jatuh
/// ke "Ikut tema". [dark] = tema aplikasi sedang gelap.
WidgetLook resolveWidgetLook(WidgetStyle style, {required Color accent, required bool dark, required bool isPro}) {
  WidgetBg bg = style.bg;
  if (bg == WidgetBg.foto && (!isPro || style.photoPath == null)) bg = WidgetBg.tema;

  // Latar terang → teks gelap (otomatis).
  final bool lightBg = switch (bg) {
    WidgetBg.tema => !dark,
    WidgetBg.aksen => false,
    WidgetBg.gradien => style.gradient == 2,
    WidgetBg.foto => style.photoLuma >= 0.6 && style.scrim < 30,
  };
  final bool textLight = switch (style.text) {
    WidgetText.terang => true,
    WidgetText.gelap => false,
    WidgetText.otomatis => !lightBg,
  };
  final bool onAccent = bg == WidgetBg.aksen || (bg == WidgetBg.gradien && style.gradient != 2);
  final bool themed = bg == WidgetBg.tema && style.text == WidgetText.otomatis;

  const Color white = Color(0xFFFFFFFF);
  const Color ink = Color(0xFF17152B);
  final Color fg = textLight ? (themed ? const Color(0xFFF3F1FA) : white) : ink;
  final Color muted = themed
      ? (dark ? const Color(0xFFA5A0C0) : const Color(0xFF6B6782))
      : textLight
          ? const Color(0xCCFFFFFF)
          : const Color(0xFF4A4660);
  final Color chip = themed
      ? (dark ? const Color(0xFF25213D) : const Color(0xFFF1F0F6))
      : textLight
          ? const Color(0x24FFFFFF)
          : const Color(0x1217152B);
  final Color track = themed
      ? (dark ? const Color(0xFF2A2645) : const Color(0xFFEFEDF5))
      : textLight
          ? const Color(0x33FFFFFF)
          : const Color(0x1A17152B);

  final int scrimAlpha = (style.scrim / 100 * 255).round();
  return WidgetLook(
    colors: switch (bg) {
      WidgetBg.tema => [dark ? const Color(0xFF1A1730) : white],
      WidgetBg.aksen => [accent],
      WidgetBg.gradien => widgetGradient(style.gradient, accent),
      WidgetBg.foto => const [Color(0xFF000000)],
    },
    photoPath: bg == WidgetBg.foto ? style.photoPath : null,
    focusY: style.focusY,
    scrim: bg == WidgetBg.foto
        ? (textLight ? const Color(0xFF000000) : white).withAlpha(scrimAlpha)
        : const Color(0x00000000),
    alpha: ((1 - style.transparency / 100) * 255).round(),
    radiusDp: style.corner.radiusDp,
    ink: fg,
    muted: muted,
    chip: chip,
    track: track,
    button: onAccent ? white : accent,
    buttonIcon: onAccent ? accent : white,
    bar: onAccent ? white : accent,
    warn: textLight ? const Color(0xFFF6C77E) : const Color(0xFFB45309),
    hideAmounts: style.hideAmounts,
  );
}

/// Untuk backup (P2b): gaya ikut, foto tidak — widget berfoto kembali ke
/// "Ikut tema" (pilih ulang fotonya setelah dipulihkan).
String stripWidgetPhotos(String raw) => encodeWidgetStyles({
      for (final e in decodeWidgetStyles(raw).entries)
        e.key: e.value.bg == WidgetBg.foto
            ? e.value.copyWith(bg: WidgetBg.tema, clearPhoto: true)
            : e.value.copyWith(clearPhoto: true),
    });
