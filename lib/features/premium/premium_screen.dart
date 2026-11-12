import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/logo_mark.dart';
import 'data/pro_limits.dart';
import 'data/promo.dart';
import 'pro_controller.dart';
import '../../core/widgets/hi_icons.dart';


/// Daftar keuntungan Pro (Claude Design › Premium). `true` = sudah ada, `false` = segera hadir.
const List<(IconData, String, String, bool)> proBenefits = [
  (HiIcons.noAds, 'Tanpa iklan selamanya', 'Layar bersih di setiap halaman', true),
  (HiIcons.folder, 'Backup otomatis', 'Harian ke folder pilihanmu, 7 salinan', true),
  (HiIcons.scan, 'Scan struk & export Excel/PDF', 'Tanpa batas, semua periode', true),
  (HiIcons.target, 'Budget, tagihan & target tanpa batas', 'Termasuk template budget 50/30/20', true),
  (HiIcons.bars, 'Laporan & kekayaan bersih lengkap', 'Semua bulan, tren 12 bulan, emas & investasi', true),
  (HiIcons.palette, 'Aksen warna & ikon aplikasi', 'Plum, Laut, Kopi, Arang · ikon alternatif', true),
];

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, this.reason = ProReason.umum});

  final ProReason reason;

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(proControllerProvider.notifier).loadProduct());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ProState s = ref.watch(proControllerProvider);
    final ProController ctl = ref.read(proControllerProvider.notifier);
    final Promo promo = ref.watch(promoProvider);
    final PromoPhase phase = ref.watch(promoPhaseProvider);
    final bool intro = phase == PromoPhase.intro;
    final String price = s.price ?? (intro ? introProPrice : normalProPrice);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: 0),
        children: [
          Row(
            children: [
              const LogoMark(size: 56),
              const SizedBox(width: AppSpace.x12),
              Text('HitungIn', style: t.pageTitle),
              const SizedBox(width: AppSpace.x8),
              const AppBadge.pro(),
            ],
          ),
          if (!s.isPro && phase.unlocksPro && promo.lastDay != null) ...[
            const SizedBox(height: AppSpace.x16),
            Container(
              key: const Key('promo-pita'),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
              decoration: BoxDecoration(
                color: c.warnSoft,
                borderRadius: AppRadius.mdAll,
              ),
              child: Text('Semua fitur Pro gratis sampai ${promoDate(promo.lastDay!)}',
                  style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.warnInk)),
            ),
          ],
          const SizedBox(height: AppSpace.x16),
          Text(s.isPro ? 'Terima kasih sudah mendukung HitungIn!' : widget.reason.headline, style: t.greeting),
          const SizedBox(height: AppSpace.x8),
          Text(
            s.isPro
                ? 'Semua fitur Pro aktif di HP ini. Pindah HP? Pakai "Pulihkan pembelian" dengan akun Google yang sama.'
                : 'Sekali bayar, berlaku selamanya. Tanpa langganan. Data tetap 100% di HP-mu.',
            style: t.body.copyWith(color: c.sub),
          ),
          const SizedBox(height: AppSpace.x24),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
            child: Column(
              children: [
                for (final (int i, (IconData icon, String title, String sub, bool ready)) in proBenefits.indexed) ...[
                  if (i > 0) Divider(color: c.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
                    child: Row(
                      children: [
                        IconTile(icon: icon, size: 40),
                        const SizedBox(width: AppSpace.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: t.item),
                              Text(sub, style: t.caption.copyWith(color: c.muted)),
                            ],
                          ),
                        ),
                        if (ready)
                          Icon(HiIcons.checkCircle, color: c.good, size: 22)
                        else
                          AppBadge('Segera', background: c.chip, foreground: c.sub),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (proBenefits.any((b) => !b.$4)) ...[
            const SizedBox(height: AppSpace.x8),
            Text('Fitur bertanda "Segera" otomatis aktif begitu tersedia, tanpa biaya tambahan.',
                style: t.caption.copyWith(color: c.muted)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.pending)
                _Note(
                  icon: HiIcons.hourglass,
                  text: 'Menunggu pembayaran selesai (mis. di minimarket atau via pulsa). Pro aktif otomatis setelah lunas.',
                  color: c.warnInk,
                ),
              if (s.error != null) _Note(icon: HiIcons.error, text: s.error!, color: c.danger),
              if (!s.available)
                _Note(icon: HiIcons.info, text: 'Google Play tidak tersedia di perangkat ini.', color: c.muted),
              if (!s.isPro && (phase.unlocksPro || intro))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x8),
                  child: Text(
                    intro
                        ? 'Harga perkenalan sampai ${promoDate(promo.introLastDay!)}, sesudahnya $normalProPrice.'
                        : 'Beli sekarang: tanpa iklan & Pro tetap milikmu.',
                    key: const Key('promo-catatan'),
                    textAlign: TextAlign.center,
                    style: t.caption.copyWith(color: c.muted),
                  ),
                ),
              if (!s.isPro)
                AppButton(
                  label: s.busy ? 'Membuka Google Play…' : 'Beli Pro · $price',
                  large: true,
                  onPressed: s.busy || s.pending || !s.available ? null : ctl.buy,
                ),
              const SizedBox(height: AppSpace.x8),
              AppButton(
                label: 'Pulihkan pembelian',
                variant: AppButtonVariant.outline,
                onPressed: s.busy ? null : () => ctl.restore(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.x12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpace.x8),
            Expanded(child: Text(text, style: context.text.caption.copyWith(color: color))),
          ],
        ),
      );
}
