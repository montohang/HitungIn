import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'pressable.dart';

/// Chip pil yang bisa dipilih (kategori, filter).
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color fg = selected ? c.onAccent : c.sub2;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          height: 38,
          padding: EdgeInsets.fromLTRB(icon == null ? AppSpace.x16 : AppSpace.x12, 0, AppSpace.x16, 0),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.chip,
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpace.x8),
              ],
              Text(label, style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lencana kecil, mis. "PRO", "3 hari lagi".
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.background, this.foreground});

  /// Lencana PRO emas.
  const AppBadge.pro({super.key})
      : label = 'PRO',
        background = const Color(0xFFF6D27A),
        foreground = const Color(0xFF7A5A06);

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: background ?? c.chip, borderRadius: AppRadius.pillAll),
      child: Text(
        label,
        maxLines: 1,
        style: context.text.label.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
          color: foreground ?? c.sub,
        ),
      ),
    );
  }
}
