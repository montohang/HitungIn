import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

/// Ilustrasi sapaan — SVG diambil apa adanya dari Claude Design
/// ("HitungIn — UI Design v1" › Onboarding), warna diisi dari tema.
/// Halaman 4 (nama panggilan) digambar dengan gaya yang sama.
enum WelcomeArt { privasi, catatCepat, rencana, nama }

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

String welcomeSvg(WelcomeArt art, AppColors c) {
  final String ink = _hex(c.ink), line2 = _hex(c.line2), card = _hex(c.card), track = _hex(c.track);
  final String accent = _hex(c.accent);
  // accentSoft di desain = aksen dengan alfa 0x1F di atas latar.
  final String accentSoft = _hex(Color.alphaBlend(c.accent.withAlpha(0x1F), c.bg));
  const String shadow = 'fill="#17152B" fill-opacity="0.08"';
  return switch (art) {
    WelcomeArt.privasi => '''
<svg width="240" height="200" viewBox="0 0 200 166" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="156" rx="64" ry="6" $shadow/>
  <rect x="58" y="14" width="84" height="138" rx="16" fill="#FFFFFF" stroke="$ink" stroke-width="3"/>
  <rect x="88" y="22" width="24" height="4" rx="2" fill="$line2"/>
  <rect x="70" y="40" width="60" height="26" rx="8" fill="$card"/>
  <rect x="76" y="48" width="30" height="5" rx="2.5" fill="#C9C4E6"/>
  <rect x="70" y="74" width="60" height="8" rx="4" fill="$track"/>
  <rect x="70" y="88" width="44" height="8" rx="4" fill="$track"/>
  <path d="M150 74l26 9v20c0 15-11 26-26 30-15-4-26-15-26-30V83z" fill="$accent"/>
  <path d="M139 103l8 8 15-17" stroke="#FFFFFF" stroke-width="4.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M34 50l3 7 7 3-7 3-3 7-3-7-7-3 7-3z" fill="#F2C14E"/>
  <circle cx="40" cy="118" r="5" fill="#2FA37A"/>
  <path d="M28 96h18M28 104h12" stroke="$line2" stroke-width="3" stroke-linecap="round"/>
</svg>''',
    WelcomeArt.catatCepat => '''
<svg width="250" height="200" viewBox="0 0 210 166" xmlns="http://www.w3.org/2000/svg">
  <rect x="16" y="22" width="150" height="40" rx="20" fill="#FFFFFF" stroke="$line2" stroke-width="2"/>
  <text x="34" y="48" font-family="PlusJakartaSans" font-size="13.5" font-weight="600" fill="#17152B">kopi 25rb gopay</text>
  <rect x="150" y="30" width="24" height="24" rx="8" fill="$accent"/>
  <path d="M156 42h12M164 37l5 5-5 5" stroke="#FFFFFF" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M100 70v18" stroke="$line2" stroke-width="3" stroke-dasharray="3 5" stroke-linecap="round"/>
  <rect x="30" y="96" width="160" height="56" rx="16" fill="#FFFFFF"/>
  <rect x="42" y="108" width="32" height="32" rx="10" fill="$accentSoft"/>
  <path d="M50 120h12v4a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5zM62 121h2a2 2 0 0 1 0 4h-2" stroke="$accent" stroke-width="2" fill="none" stroke-linecap="round"/>
  <rect x="84" y="112" width="52" height="8" rx="4" fill="#17152B"/>
  <rect x="84" y="126" width="72" height="6" rx="3" fill="#DCD9E8"/>
  <rect x="146" y="112" width="34" height="8" rx="4" fill="#17152B"/>
  <circle cx="186" cy="96" r="12" fill="#2FA37A"/>
  <path d="M180 96l4 4 8-8" stroke="#FFFFFF" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
    WelcomeArt.rencana => '''
<svg width="240" height="200" viewBox="0 0 200 166" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="156" rx="70" ry="6" $shadow/>
  <rect x="30" y="112" width="30" height="40" rx="8" fill="#F6D27A"/>
  <rect x="70" y="88" width="30" height="64" rx="8" fill="#F2C14E"/>
  <rect x="110" y="62" width="30" height="90" rx="8" fill="$accent"/>
  <rect x="150" y="36" width="30" height="116" rx="8" fill="$card"/>
  <path d="M26 96 L84 64 L124 48 L168 18" stroke="#2FA37A" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-dasharray="1 9"/>
  <circle cx="168" cy="18" r="10" fill="#F2C14E"/>
  <path d="M168 12v12M162 18h12" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>
</svg>''',
    // Baru (halaman 4): kartu sapaan beranda + gelembung "Hai!".
    WelcomeArt.nama => '''
<svg width="240" height="200" viewBox="0 0 200 166" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="156" rx="64" ry="6" $shadow/>
  <rect x="40" y="30" width="120" height="118" rx="18" fill="#FFFFFF" stroke="$ink" stroke-width="3"/>
  <circle cx="100" cy="70" r="22" fill="$accent"/>
  <circle cx="100" cy="64" r="7" fill="#FFFFFF"/>
  <path d="M87 82c3-7 8-10 13-10s10 3 13 10" stroke="#FFFFFF" stroke-width="4" fill="none" stroke-linecap="round"/>
  <rect x="68" y="104" width="64" height="9" rx="4.5" fill="#17152B"/>
  <rect x="78" y="120" width="44" height="6" rx="3" fill="$line2"/>
  <rect x="132" y="8" width="54" height="30" rx="12" fill="#F2C14E"/>
  <path d="M146 37l-6 9 12-8z" fill="#F2C14E"/>
  <text x="143" y="28" font-family="PlusJakartaSans" font-size="13" font-weight="800" fill="#17152B">Hai!</text>
  <path d="M26 54l3 7 7 3-7 3-3 7-3-7-7-3 7-3z" fill="#F2C14E"/>
  <circle cx="30" cy="120" r="5" fill="#2FA37A"/>
</svg>''',
  };
}

/// Ilustrasi dalam lingkaran 300 px berwarna aksen lembut (seperti desain).
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, required this.art, required this.colors});

  final WelcomeArt art;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double d = box.maxHeight.isFinite ? box.maxHeight.clamp(200.0, 300.0) : 300;
        return Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: colors.accentSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: SvgPicture.string(welcomeSvg(art, colors), width: d * 0.8, excludeFromSemantics: true),
        );
      },
    );
  }
}
