"""Membangun font ikon HitungIn dari ikon garis Claude Design.

Ikon desain = path SVG 24×24 bergaris (stroke 1.8, ujung bulat). Skrip ini
mengubah garis menjadi bidang (picosvg + skia-pathops), lalu menyusunnya jadi
font TTF supaya bisa dipakai seperti `Icons.*` (IconData) di seluruh app.

Jalankan:
  python3 -m venv .venv && .venv/bin/pip install fonttools picosvg skia-pathops
  .venv/bin/python tool/icons/build_icons.py

Keluaran: assets/fonts/HitungInIcons.ttf dan lib/core/widgets/hi_icons.dart.
Ikon bertanda (desain) diambil persis dari kanvas; sisanya digambar dengan
gaya yang sama untuk kebutuhan app yang belum ada di desain.
"""
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path
from picosvg.svg import SVG
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# nama: (path, tebal garis, dari desain?)
G = {
    # Navigasi & aksi (desain)
    'back': ('M15 6l-6 6 6 6', 2.0, True),
    'forward': ('M9 6l6 6-6 6', 2.0, True),
    'close': ('M6 6l12 12M18 6 6 18', 2.0, True),
    'check': ('M5 12l5 5 9-10', 2.2, True),
    'plus': ('M12 5v14M5 12h14', 2.2, True),
    'minus': ('M5 12h14', 2.2, False),
    'arrowRight': ('M4 12h14M13 6l6 6-6 6', 2.0, True),
    'home': ('M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z', 1.8, True),
    'report': ('M12 3v9h9M21 12a9 9 0 1 1-9-9', 1.8, True),
    'target': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8z', 1.8, True),
    'grid': ('M5 5h5v5H5zM14 5h5v5h-5zM5 14h5v5H5zM14 14h5v5h-5z', 1.8, True),
    'shield': ('M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6zM9 12l2 2 4-4', 1.8, True),
    'sparkle': ('M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z', 1.8, True),
    'eye': ('M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 1.8, True),
    'eyeOff': ('M3 3l18 18M10.6 6.1A10 10 0 0 1 12 6c6.5 0 10 6 10 6a17 17 0 0 1-3.2 3.8M6.6 7.6C3.8 9.3 2 12 2 12'
               's3.5 6 10 6c1.7 0 3.2-.4 4.5-1M9.9 9.9a3 3 0 0 0 4.2 4.2', 1.8, True),
    'lock': ('M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3M12 15v2', 1.8, True),
    'info': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM12 11v5M12 8h.01', 1.8, True),
    'warning': ('M12 9v4M12 17h.01M10.3 3.9 2.4 18a2 2 0 0 0 1.7 3h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z', 1.8, True),
    'fingerprint': ('M6.5 7.5a7 7 0 0 1 11 2.5M5 12a7 7 0 0 1 .3-2M8.5 19.5c.6-1.4 1-3 1-4.5v-2a2.5 2.5 0 0 1 5 0v1'
                    'M12 13v2c0 2.5-.6 4.6-1.6 6.3M15.5 16.5c-.2 1.5-.6 2.8-1.2 4M17.8 13.5c.1.6.2 1.2.2 1.8', 1.8, True),
    'filter': ('M4 6h16M7 12h10M10 18h4', 1.8, True),
    'camera': ('M4 8h3l2-3h6l2 3h3v11H4zM12 16a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 1.8, True),
    'search': ('M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4', 2.0, True),
    'swap': ('M4 8h14M14 4l4 4-4 4M20 16H6M10 12l-4 4 4 4', 1.8, True),
    'bell': ('M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21h4', 1.8, True),
    'calendar': ('M4 6h16v14H4zM4 10h16M8 3v4M16 3v4', 1.8, True),
    'download': ('M12 4v11M7 10l5 5 5-5M5 20h14', 1.8, True),
    'upload': ('M12 20V9M7 14l5-5 5 5M5 4h14', 1.8, True),
    'palette': ('M12 21a9 9 0 1 1 9-9c0 2-1.5 3-3 3h-2a2 2 0 0 0-1 3.7A2 2 0 0 1 12 21zM7.5 11h.01M12 7.5h.01M16.5 11h.01', 1.8, True),
    'document': ('M6 3h9l4 4v14H6zM9 12h7M9 16h5', 1.8, True),
    'fileCheck': ('M6 3h8l4 4v14H6zM14 3v4h4M9 14l2 2 4-4', 1.8, True),
    'star': ('M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z', 1.8, True),
    'noAds': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM5.6 5.6l12.8 12.8', 1.8, True),
    'music': ('M9 18V6l11-2v12M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM20 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z', 1.8, True),
    'wifi': ('M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01', 1.8, True),
    # Dompet (desain)
    'wallet': ('M4 7h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4zM4 7l11-3v3M16 13h.01', 1.8, True),
    'cash': ('M3 7h18v10H3zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z', 1.8, True),
    'bank': ('M3 10l9-5 9 5M5 10v7M9 10v7M15 10v7M19 10v7M3 19h18', 1.8, True),
    'phone': ('M7 3h10v18H7zM11 18h2', 1.8, True),
    # Kategori (desain)
    'food': ('M4 8h12v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM16 9h2a2 2 0 0 1 0 4h-2M8 3v2M12 3v2', 1.8, True),
    'shopping': ('M6 7h12l-1 13H7zM9 7a3 3 0 0 1 6 0', 1.8, True),
    'bolt': ('M13 2 4 14h7l-1 8 9-12h-7z', 1.8, True),
    'bus': ('M6 16V7a3 3 0 0 1 3-3h6a3 3 0 0 1 3 3v9zM6 11h12M8 19v1M16 19v1M9 14h.01M15 14h.01', 1.8, True),
    'film': ('M4 5h16v14H4zM8 5v14M16 5v14M4 12h16', 1.8, True),
    'heart': ('M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z', 1.8, True),
    'education': ('M3 9l9-5 9 5-9 5zM7 11v5c3 2 7 2 10 0v-5', 1.8, True),
    'gift': ('M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-2-3-5-3-5-1s5 1 5 1zM12 7c2-3 5-3 5-1s-5 1-5 1z', 1.8, True),
    'briefcase': ('M4 8h16v11H4zM9 8V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2', 1.8, True),
    'laptop': ('M4 6h16v10H4zM2 19h20', 1.8, True),
    'trendUp': ('M4 18l5-6 4 3 7-8M15 7h5v5', 1.8, True),
    # Gaya sama, untuk kebutuhan app yang belum ada di desain
    'dots': ('M6 12h.01M12 12h.01M18 12h.01', 3.0, False),
    'store': ('M4 10v10h16V10M3 4h18l-1 6H4zM9 20v-6h6v6', 1.8, False),
    'backspace': ('M9 5h11v14H9l-6-7zM13 10l4 4M17 10l-4 4', 1.8, False),
    'edit': ('M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4', 1.8, False),
    'trash': ('M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3', 1.8, False),
    'copy': ('M8 8h12v12H8zM4 16V4h12', 1.8, False),
    'repeat': ('M4 12a8 8 0 0 1 14-5.3M20 12a8 8 0 0 1-14 5.3M18 3v4h-4M6 21v-4h4', 1.8, False),
    'user': ('M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0', 1.8, False),
    'history': ('M3 12a9 9 0 1 0 3-6.7M3 4v5h5M12 8v4l3 2', 1.8, False),
    'restore': ('M3 12a9 9 0 1 0 3-6.7M3 4v5h5M12 9v4M12 16h.01', 1.8, False),
    'today': ('M4 6h16v14H4zM4 10h16M8 3v4M16 3v4M12 15h.01', 1.8, False),
    'pin': ('M3 7h18v10H3zM7.5 12h.01M12 12h.01M16.5 12h.01', 1.8, False),
    'table': ('M4 5h16v14H4zM4 10h16M4 15h16M10 5v14', 1.8, False),
    'hourglass': ('M6 3h12M6 21h12M7 3v2a5 5 0 0 0 10 0V3M7 21v-2a5 5 0 0 1 10 0v2', 1.8, False),
    'play': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM10 8.5v7l6-3.5z', 1.8, False),
    'receipt': ('M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6M9 16h4', 1.8, False),
    'bars': ('M5 20v-8M12 20V5M19 20v-11', 2.0, False),
    'checkCircle': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM8 12l3 3 5-6', 1.8, False),
    'error': ('M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18zM12 8v5M12 16h.01', 1.8, False),
    'gradient': ('M4 4h16v16H4zM4 20 20 4M9 20 20 9', 1.8, False),
    'jar': ('M7 8h10v11a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2zM8 4h8v4H8zM12 12v5M10 14.5h4', 1.8, False),
    'chevronDown': ('M6 9l6 6 6-6', 2.0, False),
}

UPM = 960
SCALE = UPM / 24


def fill_path(d, width):
    svg = SVG.fromstring(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        f'<path d="{d}" fill="none" stroke="#000" stroke-width="{width}" '
        f'stroke-linecap="round" stroke-linejoin="round"/></svg>'
    )
    pico = svg.topicosvg()
    return ' '.join(p.d for p in pico.shapes())


def glyph(d):
    pen = TTGlyphPen(None)
    # Koordinat SVG (y ke bawah) → font (y ke atas), baseline di bawah kotak 24.
    tpen = TransformPen(Cu2QuPen(pen, max_err=1.0, reverse_direction=True), (SCALE, 0, 0, -SCALE, 0, UPM * 0.84))
    parse_path(d, tpen)
    return pen.glyph()


names = list(G)
order = ['.notdef'] + names
cmap = {0xE000 + i: n for i, n in enumerate(names)}
glyphs = {'.notdef': TTGlyphPen(None).glyph()}
for n in names:
    path, width, _ = G[n]
    glyphs[n] = glyph(fill_path(path, width))

fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder(order)
fb.setupCharacterMap(cmap)
fb.setupGlyf(glyphs)
fb.setupHorizontalMetrics({n: (UPM, 0) for n in order})
fb.setupHorizontalHeader(ascent=int(UPM * 0.84), descent=-int(UPM * 0.16))
fb.setupNameTable({'familyName': 'HitungInIcons', 'styleName': 'Regular'})
fb.setupOS2(sTypoAscender=int(UPM * 0.84), sTypoDescender=-int(UPM * 0.16), usWinAscent=int(UPM * 0.84), usWinDescent=int(UPM * 0.16))
fb.setupPost()
fb.save(os.path.join(ROOT, 'assets/fonts/HitungInIcons.ttf'))

lines = [
    "import 'package:flutter/widgets.dart';",
    '',
    '// DIBUAT OTOMATIS oleh tool/icons/build_icons.py — jangan diubah manual.',
    '',
    '/// Ikon garis HitungIn (dari Claude Design), dipakai seperti `Icons.*`.',
    'abstract final class HiIcons {',
    "  static const String _family = 'HitungInIcons';",
    '',
]
for i, n in enumerate(names):
    src = 'desain' if G[n][2] else 'gaya desain'
    lines.append(f'  /// {n} ({src}).')
    lines.append(f'  static const IconData {n} = IconData(0x{0xE000 + i:x}, fontFamily: _family);')
lines.append('')
lines.append('  /// Semua ikon (galeri desain).')
lines.append('  static const Map<String, IconData> all = {')
for n in names:
    lines.append(f"    '{n}': {n},")
lines.append('  };')
lines.append('}')
lines.append('')
open(os.path.join(ROOT, 'lib/core/widgets/hi_icons.dart'), 'w').write('\n'.join(lines))
print(f'{len(names)} ikon')
