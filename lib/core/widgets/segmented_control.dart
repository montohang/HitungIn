import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'pressable.dart';

/// Pilihan bersegmen (Pengeluaran / Pemasukan / Pindah Saldo, mode tema, dll).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.onSurface = false,
    this.isLocked,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;

  /// Di atas latar `surface` (mis. layar Catat): wadah memakai warna chip.
  final bool onSurface;

  /// Pilihan yang dikunci tampil redup; ketukan tetap diteruskan ke
  /// [onChanged] supaya layar bisa menjelaskan alasannya.
  final bool Function(T)? isLocked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color on = onSurface && dark ? Color.lerp(c.chip, Colors.white, 0.06)! : c.surface;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x4),
      decoration: BoxDecoration(color: onSurface ? c.chip : c.seg, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          for (final T o in options)
            Expanded(
              child: Semantics(
                selected: o == selected,
                child: Pressable(
                  onTap: () => onChanged(o),
                  semanticLabel: labelOf(o),
                  child: AnimatedContainer(
                    duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o == selected ? on : Colors.transparent,
                      borderRadius: AppRadius.smAll,
                      boxShadow: o == selected && !dark
                          ? const [BoxShadow(color: Color(0x1417152B), blurRadius: 8, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Text(
                      labelOf(o),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: o == selected
                            ? c.ink
                            : (isLocked?.call(o) ?? false)
                                ? c.muted.withAlpha(0x66)
                                : c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
