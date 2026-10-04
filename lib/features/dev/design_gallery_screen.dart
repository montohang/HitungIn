import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/segmented_control.dart';

/// Layar sementara untuk memeriksa design system di HP sungguhan.
/// Akan diganti alur Splash → Onboarding pada tahap berikutnya.
class DesignGalleryScreen extends ConsumerStatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  ConsumerState<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends ConsumerState<DesignGalleryScreen> {
  String _cat = 'Makan & Minum';
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final settings = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Row(
              children: [
                const LogoMark(size: 32),
                const SizedBox(width: AppSpace.x8),
                Text('HitungIn', style: t.screenTitle.copyWith(fontSize: 18)),
                const Spacer(),
                const AppBadge('Design system v1'),
              ],
            ),
            const SizedBox(height: AppSpace.x24),
            Text('Minggu, 19 Oktober', style: t.caption.copyWith(color: c.muted)),
            const SizedBox(height: AppSpace.x4),
            Text.rich(
              TextSpan(
                text: 'Selamat pagi, ',
                children: [TextSpan(text: 'Rina', style: TextStyle(color: c.accentText))],
              ),
              style: t.greeting,
            ),
            const SizedBox(height: AppSpace.block),
            _BalanceCard(replay: _replay, gradient: settings.gradientBalanceCard),
            const SizedBox(height: AppSpace.block),
            _Section(
              title: 'Mode tampilan',
              child: AppSegmentedControl<AppThemeMode>(
                options: AppThemeMode.values,
                selected: settings.mode,
                labelOf: (m) => m.label,
                onChanged: controller.setMode,
              ),
            ),
            _Section(
              title: 'Warna aksen',
              child: Wrap(
                spacing: AppSpace.x12,
                runSpacing: AppSpace.x12,
                children: [
                  for (final a in AccentPreset.values)
                    _Swatch(
                      preset: a,
                      selected: a == settings.accent,
                      onTap: () => controller.setAccent(a),
                    ),
                ],
              ),
            ),
            _Section(
              title: 'Kartu saldo bergradien',
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: settings.gradientBalanceCard,
                onChanged: controller.setGradientBalanceCard,
                title: Text('Gradien halus dari warna aksen', style: t.item),
              ),
            ),
            _Section(
              title: 'Tombol',
              child: Column(
                children: [
                  AppButton(label: 'Simpan transaksi', large: true, onPressed: () => setState(() => _replay++)),
                  const SizedBox(height: AppSpace.x8),
                  AppButton(label: 'Lihat laporan', variant: AppButtonVariant.soft, onPressed: () {}),
                  const SizedBox(height: AppSpace.x8),
                  Row(
                    children: [
                      Expanded(child: AppButton(label: 'Batal', variant: AppButtonVariant.outline, onPressed: () {})),
                      const SizedBox(width: AppSpace.x8),
                      Expanded(child: AppButton(label: 'Hapus', variant: AppButtonVariant.danger, onPressed: () {})),
                    ],
                  ),
                ],
              ),
            ),
            _Section(
              title: 'Chip kategori',
              child: Wrap(
                spacing: AppSpace.x8,
                runSpacing: AppSpace.x8,
                children: [
                  for (final (String name, IconData icon) in const [
                    ('Makan & Minum', Icons.local_cafe_outlined),
                    ('Transportasi', Icons.directions_bus_outlined),
                    ('Belanja', Icons.shopping_bag_outlined),
                    ('Tagihan', Icons.bolt_outlined),
                  ])
                    AppChip(label: name, icon: icon, selected: _cat == name, onTap: () => setState(() => _cat = name)),
                ],
              ),
            ),
            _Section(
              title: 'Progress budget',
              child: AppCard(
                child: Column(
                  children: [
                    for (final (int i, String label, double v) in const [
                      (0, 'Normal', 0.45),
                      (1, 'Hati-hati', 0.82),
                      (2, 'Lewat batas', 1.08),
                    ]) ...[
                      Row(
                        children: [
                          Text(label, style: t.caption.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${(v * 100).round()}%', style: t.number.copyWith(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: AppSpace.x8),
                      AppProgressBar(
                        key: ValueKey('bar-$i-$_replay'),
                        value: v,
                        delay: AppMotion.stagger * i,
                      ),
                      if (i < 2) const SizedBox(height: AppSpace.x16),
                    ],
                  ],
                ),
              ),
            ),
            _Section(
              title: 'Baris transaksi',
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                child: Column(
                  children: [
                    const _TxRow(icon: Icons.local_cafe_outlined, name: 'Kopi Kenangan', meta: 'Makan & Minum · GoPay · 08.42', amount: -25000),
                    Divider(color: c.line),
                    const _TxRow(icon: Icons.work_outline, name: 'Gaji Oktober', meta: 'Gaji · BCA · Kemarin', amount: 9200000),
                  ],
                ),
              ),
            ),
            _Section(
              title: 'Lencana & logo',
              child: Row(
                children: [
                  const AppBadge.pro(),
                  const SizedBox(width: AppSpace.x8),
                  AppBadge('3 hari lagi', background: c.warnSoft, foreground: c.warnInk),
                  const Spacer(),
                  const LogoMark(size: 24),
                  const SizedBox(width: AppSpace.x8),
                  const LogoMark(size: 40),
                  const SizedBox(width: AppSpace.x8),
                  const LogoMark(size: 56, radiusFactor: 0.5, contentScale: 0.82),
                ],
              ),
            ),
            _Section(
              title: 'Tipografi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Laporan', style: t.pageTitle),
                  const SizedBox(height: AppSpace.x8),
                  Text(Rupiah.format(3120000), style: t.amountL),
                  const SizedBox(height: AppSpace.x8),
                  Text('Transaksi terbaru', style: t.section),
                  const SizedBox(height: AppSpace.x4),
                  Text(
                    'Pengeluaran makan sudah 82% dari budget. Masih aman kalau kamu tahan Rp20 ribu per hari.',
                    style: t.body.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: AppSpace.x4),
                  Text('GoPay · 08.42', style: t.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.x8, bottom: AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.label.copyWith(color: context.colors.sub)),
          const SizedBox(height: AppSpace.x8),
          child,
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.replay, required this.gradient});

  final int replay;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.cardHero),
      decoration: BoxDecoration(
        color: gradient ? null : c.card,
        borderRadius: AppRadius.lgAll,
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.4, 1],
                colors: [c.card, c.card, Color.lerp(c.card, c.accent, 0.5)!],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total saldo · 4 dompet', style: t.caption.copyWith(color: c.onCardMuted)),
          const SizedBox(height: AppSpace.x8),
          CountUpRupiah(amount: 8450000, replayKey: replay, style: t.amountXL.copyWith(color: c.onCard)),
          const SizedBox(height: AppSpace.x16),
          Row(
            children: [
              Expanded(child: _Mini(label: 'Masuk bulan ini', value: '+${Rupiah.compact(9200000)}', color: c.goodInk)),
              const SizedBox(width: AppSpace.x12),
              Expanded(child: _Mini(label: 'Keluar bulan ini', value: '${Rupiah.minus}${Rupiah.compact(3120000)}', color: c.onCard)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.onCard.withAlpha(0x12), borderRadius: AppRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.label.copyWith(color: c.onCardMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpace.x2),
          Text(value, style: context.text.number.copyWith(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.icon, required this.name, required this.meta, required this.amount});

  final IconData icon;
  final String name;
  final String meta;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool income = amount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            color: income ? c.good : null,
            background: income ? c.goodSoft : null,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.item, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpace.x2),
                Text(meta, style: context.text.caption.copyWith(color: c.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          Text(Rupiah.format(amount, signed: true), style: context.text.number.copyWith(color: income ? c.good : c.ink)),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.preset, required this.selected, required this.onTap});

  final AccentPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color color = dark ? preset.dark : preset.light;
    return Semantics(
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: preset.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(AppSpace.x4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? color : Colors.transparent, width: 2),
            ),
            child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
        ),
      ),
    );
  }
}
