import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Ikon kategori/dompet: emoji pilihan pengguna (`e:🍜`) atau ikon HitungIn.
class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.iconKey, {super.key, this.size = 20, this.color});

  final String iconKey;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final String? emoji = AppIcons.emojiOf(iconKey);
    if (emoji == null) return Icon(AppIcons.of(iconKey), size: size, color: color);
    return ExcludeSemantics(
      child: Text(emoji, textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size * 0.95, height: 1)),
    );
  }
}
