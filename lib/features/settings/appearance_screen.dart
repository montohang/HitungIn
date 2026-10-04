import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/segmented_control.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import 'widgets/settings_tile.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final ThemeSettings s = ref.watch(themeControllerProvider);
    final ThemeController ctl = ref.read(themeControllerProvider.notifier);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Tema & warna', style: t.screenTitle)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8),
        children: [
          const FieldLabel('Mode tampilan'),
          AppSegmentedControl<AppThemeMode>(
            options: AppThemeMode.values,
            selected: s.mode,
            labelOf: (m) => m.label,
            onChanged: ctl.setMode,
          ),
          const SizedBox(height: AppSpace.x16),
          const FieldLabel('Warna aksen'),
          Wrap(
            spacing: AppSpace.x12,
            runSpacing: AppSpace.x12,
            children: [
              for (final a in AccentPreset.values)
                Semantics(
                  selected: a == s.accent,
                  child: Pressable(
                    onTap: () => a.pro && !isPro ? openPremium(context, ProReason.tema) : ctl.setAccent(a),
                    semanticLabel: 'Aksen ${a.label}',
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: context.reduceMotion ? Duration.zero : AppMotion.press,
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(AppSpace.x4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: a == s.accent ? (dark ? a.dark : a.light) : Colors.transparent, width: 2),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: dark ? a.dark : a.light, shape: BoxShape.circle),
                            child: a == s.accent
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : a.pro && !isPro
                                    ? const Icon(Icons.lock_outline, color: Colors.white, size: 18)
                                    : null,
                          ),
                        ),
                        const SizedBox(height: AppSpace.x4),
                        Text(a.pro ? '${a.label} · Pro' : a.label, style: t.label.copyWith(color: c.sub)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x24),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.gradient,
                title: 'Kartu saldo bergradien',
                subtitle: 'Gradien halus dari warna aksen',
                trailing: Switch.adaptive(value: s.gradientBalanceCard, activeTrackColor: c.accent, onChanged: ctl.setGradientBalanceCard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
