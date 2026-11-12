import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../data/pro_limits.dart';
import '../data/promo.dart';
import '../pro_controller.dart';
import 'pro_teaser.dart' show openPremium;

/// Kartu Beranda promo perkenalan (P4): 7 hari terakhir promo, lalu
/// 7 hari pertama sesudahnya. Tidak tampil bagi yang sudah membeli Pro.
class PromoHomeCard extends ConsumerWidget {
  const PromoHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    if (ref.watch(ownsProProvider)) return const SizedBox.shrink();
    final Promo promo = ref.watch(promoProvider);
    final DateTime now = ref.watch(clockProvider)();
    final DateTime? last = promo.lastDay;
    final bool ending = promo.phase(now) == PromoPhase.endingSoon;
    final bool ended = promo.justEnded(now);
    if (last == null || (!ending && !ended)) return const SizedBox.shrink();
    final int days = promo.daysLeft(now);
    final String title = ended ? 'Promo Pro gratis sudah selesai' : 'Fitur Pro gratis tinggal $days hari';
    final String body = ended
        ? 'Datamu tetap aman. Harga perkenalan $introProPrice sampai ${promoDate(promo.introLastDay!)}.'
        : 'Sampai ${promoDate(last)}. Sesudahnya Pro $normalProPrice sekali bayar, perkenalan $introProPrice.';
    final Color ink = ended ? c.ink : c.warnInk;
    final Color sub = ended ? c.muted : c.warnInk;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.block),
      child: Pressable.card(
        key: const Key('kartu-promo'),
        onTap: () => openPremium(context, ProReason.umum),
        semanticLabel: title,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
          decoration: BoxDecoration(
            color: ended ? c.surface : c.warnSoft,
            borderRadius: AppRadius.lgAll,
            border: ended ? Border.all(color: c.line) : null,
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF6D27A), borderRadius: AppRadius.smAll),
              child: const Icon(HiIcons.clock, size: 20, color: Color(0xFF7A5A06)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.item.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 2),
                Text(body, style: t.label.copyWith(fontWeight: FontWeight.w500, color: sub, height: 1.45)),
              ]),
            ),
            const SizedBox(width: AppSpace.x8),
            Icon(HiIcons.forward, size: 16, color: sub),
          ]),
        ),
      ),
    );
  }
}
