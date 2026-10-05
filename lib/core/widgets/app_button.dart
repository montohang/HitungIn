import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'pressable.dart';

enum AppButtonVariant {
  /// Aksi utama — latar aksen.
  primary,

  /// Aksi kedua — latar aksen lembut.
  soft,

  /// Aksi netral — permukaan + garis.
  outline,

  /// Aksi berbahaya — Hapus.
  danger,

  /// Konfirmasi berbahaya — latar merah penuh (lembar "Hapus transaksi ini?").
  dangerSolid,
}

/// Tombol standar HitungIn: tinggi 52 (atau 56 untuk [large]), radius 16.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.large = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool large;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg, Color? border) = switch (variant) {
      AppButtonVariant.primary => (c.accent, c.onAccent, null),
      AppButtonVariant.soft => (c.accentSoft, c.accentText, null),
      AppButtonVariant.outline => (c.surface, c.ink, c.line),
      AppButtonVariant.danger => (c.dangerSoft, c.danger, Color.lerp(c.dangerSoft, c.danger, 0.2)),
      AppButtonVariant.dangerSolid => (c.dangerBar, Colors.white, null),
    };
    final bool disabled = onPressed == null;

    final Widget content = AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: AppMotion.press,
      child: Container(
        height: large ? 56 : 52,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdAll,
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: AppSpace.x8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.title.copyWith(
                  color: fg,
                  fontSize: large ? 16 : 15,
                  fontWeight: variant == AppButtonVariant.primary ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Pressable(onTap: onPressed, semanticLabel: label, child: content);
  }
}
