import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'hi_icons.dart';
import 'pressable.dart';

/// Pilihan warna bulat 34 px (Claude Design › Kategori › Warna).
class ColorSwatches extends StatelessWidget {
  const ColorSwatches({super.key, required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.x12,
      runSpacing: AppSpace.x12,
      children: [
        for (int i = 0; i < AppPalette.length; i++)
          Semantics(
            selected: i == selected,
            child: Pressable(
              onTap: () => onChanged(i),
              semanticLabel: 'Warna ${AppPalette.entries[i].$1}',
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.of(context, i),
                  shape: BoxShape.circle,
                  border: Border.all(color: i == selected ? context.colors.ink : Colors.transparent, width: 2.5),
                ),
                child: i == selected ? const Icon(HiIcons.check, size: 16, color: Colors.white) : null,
              ),
            ),
          ),
      ],
    );
  }
}
