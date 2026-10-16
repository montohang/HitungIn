import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../premium/data/pro_limits.dart';
import '../../premium/pro_controller.dart';
import '../../premium/widgets/pro_teaser.dart';
import 'settings_tile.dart';

/// Ikon di dalam aplikasi (P2b): gaya set ikon, wadah, tombol Catat & label tab.
class IconLookPicker extends ConsumerWidget {
  const IconLookPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final ThemeSettings s = ref.watch(themeControllerProvider);
    final ThemeController ctl = ref.read(themeControllerProvider.notifier);
    final bool isPro = ref.watch(isProProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Gaya ikon'),
        Row(
          children: [
            for (final (int i, HiIconStyle st) in HiIconStyle.values.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.x8),
              Expanded(
                child: _StyleOption(
                  style: st,
                  selected: s.iconStyle == st,
                  locked: st.pro && !isPro,
                  onTap: () => st.pro && !isPro ? openPremium(context, ProReason.personalisasi) : ctl.setIconStyle(st),
                ),
              ),
            ],
          ],
        ),
        const FieldLabel('Wadah ikon'),
        AppSegmentedControl<IconWrap>(
          options: IconWrap.values,
          selected: s.iconWrap,
          labelOf: (v) => v.label,
          onChanged: ctl.setIconWrap,
        ),
        const FieldLabel('Tombol Catat & tab bawah'),
        Container(
          padding: const EdgeInsets.all(AppSpace.x12),
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text('Bentuk', style: t.item.copyWith(fontSize: 14))),
                for (final FabShape v in FabShape.values) ...[
                  const SizedBox(width: AppSpace.x4),
                  AppChip(label: v.label, selected: s.fabShape == v, onTap: () => ctl.setFabShape(v)),
                ],
              ]),
              const SizedBox(height: AppSpace.x8),
              Row(children: [
                Expanded(child: Text('Ikon tombol', style: t.item.copyWith(fontSize: 14))),
                for (final FabIcon v in FabIcon.values) ...[
                  const SizedBox(width: AppSpace.x4),
                  Pressable(
                    onTap: () => ctl.setFabIcon(v),
                    semanticLabel: 'Ikon tombol ${v.label}',
                    child: Container(
                      width: 44,
                      height: 36,
                      decoration: BoxDecoration(
                        color: s.fabIcon == v ? c.accent : c.chip,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(v.icon, size: 20, color: s.fabIcon == v ? c.onAccent : c.sub2),
                    ),
                  ),
                ],
              ]),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: s.tabLabels,
                activeTrackColor: c.accent,
                title: Text('Tampilkan label tab', style: t.item.copyWith(fontSize: 14)),
                onChanged: ctl.setTabLabels,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({required this.style, required this.selected, required this.locked, required this.onTap});

  final HiIconStyle style;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Color ink = selected ? c.accentText : c.ink;
    // Contoh glyph digambar dengan font gaya itu sendiri, bukan gaya aktif.
    final Widget sample = style == HiIconStyle.duotone
        ? Stack(alignment: Alignment.center, children: [
            Icon(HiIcons.shopping.solid, size: 26, color: ink.withValues(alpha: 0.28)),
            Icon(HiIcons.shopping.line, size: 26, color: ink),
          ])
        : Icon(IconData(HiIcons.shopping.codePoint, fontFamily: style.family), size: 26, color: ink);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Gaya ikon ${style.label}${locked ? ', Pro' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: selected ? c.accent : c.line, width: 2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(children: [
                sample,
                const SizedBox(height: AppSpace.x4),
                Text(style.label, style: t.label.copyWith(color: c.sub2)),
              ]),
            ),
            if (locked) const Positioned(top: -4, right: 2, child: AppBadge.pro()),
          ],
        ),
      ),
    );
  }
}
