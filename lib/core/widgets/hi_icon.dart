import 'package:flutter/widgets.dart';

import 'hi_icons.dart';

/// Ikon yang mengikuti gaya Duotone (P2b): glyph Isi transparan di bawah
/// glyph Garis. Gaya lain = `Icon` biasa (fontnya sudah mengikuti gaya).
class HiIcon extends StatelessWidget {
  const HiIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final IconData i = icon;
    if (HiIcons.style != HiIconStyle.duotone || i is! HiIconData) return Icon(i, size: size, color: color);
    final Color c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(i.solid, size: size, color: c.withValues(alpha: 0.28)),
        Icon(i.line, size: size, color: c),
      ],
    );
  }
}
