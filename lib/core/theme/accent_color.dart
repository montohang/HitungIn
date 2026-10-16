import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

/// Rasio kontras WCAG antara [c] dan teks putih.
double contrastOnWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

/// Warna aksen harus terbaca di bawah teks/ikon putih (tombol, chip aktif):
/// bila kontras < 4,5:1, kecerahannya diturunkan sedikit demi sedikit.
Color ensureWhiteContrast(Color c, {double min = 4.5}) {
  HSL hsl = HSL.of(c);
  Color out = c;
  for (int i = 0; i < 40 && contrastOnWhite(out) < min; i++) {
    hsl = hsl.withLightness(math.max(0, hsl.lightness - 0.02));
    out = hsl.toColor(c.a);
  }
  return out;
}

/// Varian aksen untuk mode gelap: sedikit lebih terang (seperti preset), tetap
/// terbaca dengan teks putih (≥ 3:1 untuk teks tebal).
Color darkVariant(Color light) {
  final Color lifted = Color.lerp(light, const Color(0xFFFFFFFF), 0.14)!;
  return contrastOnWhite(lifted) >= 3 ? lifted : light;
}

/// 2–[n] warna aksen yang menonjol dari piksel RGBA foto kecil (mis. 16×16):
/// dikelompokkan per rona, abaikan piksel pucat/terlalu gelap/terang, lalu
/// dibuat terbaca dengan teks putih.
List<Color> paletteFromRgba(Uint8List rgba, {int n = 4}) {
  final List<({double count, double r, double g, double b})> bins =
      List.filled(12, (count: 0.0, r: 0.0, g: 0.0, b: 0.0));
  for (int i = 0; i + 3 < rgba.length; i += 4) {
    final Color px = Color.fromARGB(255, rgba[i], rgba[i + 1], rgba[i + 2]);
    final HSL h = HSL.of(px);
    if (h.saturation < 0.25 || h.lightness < 0.15 || h.lightness > 0.85) continue;
    final int k = (h.hue / 30).floor() % 12;
    final b = bins[k];
    bins[k] = (count: b.count + 1, r: b.r + rgba[i], g: b.g + rgba[i + 1], b: b.b + rgba[i + 2]);
  }
  final List<int> order = List.generate(12, (i) => i)..sort((a, b) => bins[b].count.compareTo(bins[a].count));
  final List<Color> out = [];
  for (final int k in order) {
    final b = bins[k];
    if (b.count == 0 || out.length >= n) break;
    out.add(ensureWhiteContrast(
        Color.fromARGB(255, (b.r / b.count).round(), (b.g / b.count).round(), (b.b / b.count).round())));
  }
  return out;
}

/// HSL kecil (tanpa Flutter material) supaya bisa dipakai di lapisan data.
class HSL {
  const HSL(this.hue, this.saturation, this.lightness);

  final double hue, saturation, lightness;

  factory HSL.of(Color c) {
    final double r = c.r, g = c.g, b = c.b;
    final double mx = math.max(r, math.max(g, b)), mn = math.min(r, math.min(g, b));
    final double l = (mx + mn) / 2;
    if (mx == mn) return HSL(0, 0, l);
    final double d = mx - mn;
    final double s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn);
    double h;
    if (mx == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (mx == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return HSL(h * 60, s, l);
  }

  HSL withLightness(double l) => HSL(hue, saturation, l.clamp(0, 1));

  Color toColor([double alpha = 1]) {
    final double c = (1 - (2 * lightness - 1).abs()) * saturation;
    final double x = c * (1 - ((hue / 60) % 2 - 1).abs());
    final double m = lightness - c / 2;
    final (double r, double g, double b) = switch (hue) {
      < 60 => (c, x, 0.0),
      < 120 => (x, c, 0.0),
      < 180 => (0.0, c, x),
      < 240 => (0.0, x, c),
      < 300 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    int ch(double v) => ((v + m) * 255).round().clamp(0, 255);
    return Color.fromARGB((alpha * 255).round(), ch(r), ch(g), ch(b));
  }
}

/// Warna dari rona [hue] 0–360 untuk pemilih "warna bebas".
Color colorFromHue(double hue, {double saturation = 0.72, double lightness = 0.5}) =>
    HSL(hue % 360, saturation, lightness).toColor();
