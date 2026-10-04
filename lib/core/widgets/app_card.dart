import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'pressable.dart';

/// Kartu permukaan standar: radius 24, padding 16, garis halus.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.card),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.line),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable.card(onTap: onTap, child: box);
  }
}

/// Kotak ikon 44×44 berlatar aksen lembut (baris transaksi, kategori).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.color,
    this.background,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background ?? c.accentSoft, borderRadius: AppRadius.smAll),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: color ?? c.accentText),
    );
  }
}
