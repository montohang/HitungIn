import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/screen_header.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import 'data/home_layout.dart';
import 'home_layout_provider.dart';

IconData _iconOf(HomeCard c) => switch (c) {
      HomeCard.jatah => HiIcons.clock,
      HomeCard.prakiraan => HiIcons.trendLine,
      HomeCard.cepat => HiIcons.sparkleAlt,
      HomeCard.favorit => HiIcons.star,
      HomeCard.budget => HiIcons.target,
      HomeCard.target => HiIcons.piggy,
      HomeCard.tagihan => HiIcons.calendar,
      HomeCard.terbaru => HiIcons.history,
    };

/// Atur Beranda (P2b, Pro; Claude Design › Atur Beranda): seret untuk
/// mengurutkan, sakelar untuk menyembunyikan. Total saldo tetap di atas.
class HomeLayoutScreen extends ConsumerWidget {
  const HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool isPro = ref.watch(isProProvider);
    final HomeLayout layout = ref.watch(savedHomeLayoutProvider).valueOrNull ?? HomeLayout.standard;
    Future<void> save(HomeLayout l) => saveHomeLayout(ref.read(appDatabaseProvider).settingsDao, l);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Atur Beranda',
                large: true,
                trailing: isPro && !layout.isStandard
                    ? TextButton(onPressed: () => save(HomeLayout.standard), child: const Text('Bawaan'))
                    : null,
              ),
              const SizedBox(height: AppSpace.x12),
              Text(
                isPro
                    ? 'Tahan ⠿ lalu geser untuk mengubah urutan. Matikan kartu yang jarang kamu lihat.'
                    : 'Susun Beranda sesukamu dengan HitungIn Pro.',
                style: t.caption.copyWith(color: c.muted, height: 1.5),
              ),
              const SizedBox(height: AppSpace.x12),
              _Row(
                icon: HiIcons.wallet,
                title: 'Total saldo',
                subtitle: 'Selalu paling atas',
                leading: Icon(HiIcons.padlock, size: 16, color: c.muted),
              ),
              const SizedBox(height: AppSpace.x8),
              Expanded(
                child: IgnorePointer(
                  ignoring: !isPro,
                  child: Opacity(
                    opacity: isPro ? 1 : 0.55,
                    child: ReorderableListView(
                      buildDefaultDragHandles: false,
                      onReorder: (from, to) => save(layout.move(from, to > from ? to - 1 : to)),
                      children: [
                        for (final (int i, HomeCard card) in layout.order.indexed)
                          Padding(
                            key: ValueKey(card),
                            padding: const EdgeInsets.only(bottom: AppSpace.x8),
                            child: _Row(
                              icon: _iconOf(card),
                              title: card.label,
                              subtitle: card.hint,
                              dim: layout.hidden.contains(card),
                              leading: ReorderableDragStartListener(
                                index: i,
                                child: Semantics(
                                  label: 'Seret untuk memindahkan ${card.label}',
                                  child: Text('⠿', style: t.title.copyWith(color: c.muted)),
                                ),
                              ),
                              trailing: Switch.adaptive(
                                value: !layout.hidden.contains(card),
                                activeTrackColor: c.accent,
                                onChanged: (v) => save(layout.toggle(card, v)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.x8),
              isPro
                  ? AppButton(label: 'Selesai', large: true, onPressed: () => Navigator.of(context).maybePop())
                  : AppButton(
                      label: 'Lihat HitungIn Pro',
                      large: true,
                      onPressed: () => openPremium(context, ProReason.personalisasi),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.leading,
    this.trailing,
    this.dim = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: leading)),
            const SizedBox(width: AppSpace.x8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(icon, size: 18, color: c.accentText),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.item),
                  Text(subtitle, style: t.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
