import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/logo_mark.dart';
import 'data/pro_limits.dart';
import 'pro_controller.dart';

/// Harga cadangan bila Google Play belum mengirim harga (offline/emulator).
const String fallbackProPrice = 'Rp59.000';

/// Daftar keuntungan Pro. `true` = sudah ada, `false` = segera hadir.
const List<(IconData, String, String, bool)> proBenefits = [
  (Icons.block, 'Tanpa iklan', 'Selamanya, di semua layar', true),
  (Icons.savings_outlined, 'Budget tanpa batas', 'Gratis: total + ${FreeLimits.categoryBudgets} kategori', true),
  (Icons.event_repeat_outlined, 'Tagihan tanpa batas', 'Gratis: ${FreeLimits.activeBills} tagihan aktif', true),
  (Icons.notifications_outlined, 'Notifikasi pengingat tagihan', 'Diingatkan walau aplikasi tertutup', true),
  (Icons.insights_outlined, 'Laporan semua bulan', 'Gratis: bulan ini & bulan lalu', true),
  (Icons.table_chart_outlined, 'Ekspor CSV kapan saja', 'Gratis: sekali per iklan berhadiah', true),
  (Icons.trending_up, 'Tren 6–12 bulan & filter dompet', 'Laporan lanjutan', true),
  (Icons.autorenew, 'Transaksi berulang', 'Gaji & langganan tercatat otomatis', true),
  (Icons.palette_outlined, 'Aksen warna tambahan', 'Plum, Laut, Kopi, Arang', true),
  (Icons.apps, 'Ikon aplikasi alternatif', 'Gelap, Emas, Terang', true),
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
                          Icon(Icons.check_circle, color: c.good, size: 22)
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
                  icon: Icons.hourglass_top,
                  text: 'Menunggu pembayaran selesai (mis. di minimarket atau via pulsa). Pro aktif otomatis setelah lunas.',
                  color: c.warnInk,
                ),
              if (s.error != null) _Note(icon: Icons.error_outline, text: s.error!, color: c.danger),
              if (!s.available)
                _Note(icon: Icons.info_outline, text: 'Google Play tidak tersedia di perangkat ini.', color: c.muted),
              if (!s.isPro)
                AppButton(
                  label: s.busy ? 'Membuka Google Play…' : 'Beli Pro · ${s.price ?? fallbackProPrice}',
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
