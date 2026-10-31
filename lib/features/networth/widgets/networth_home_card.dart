import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../security/app_gate.dart';
import '../data/net_worth.dart';
import '../networth_provider.dart';

/// Kartu Beranda (P3h, bawaan disembunyikan; nyalakan di Atur Beranda).
class NetWorthHomeCard extends ConsumerWidget {
  const NetWorthHomeCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final NetWorth? w = ref.watch(netWorthProvider);
    if (w == null) return const SizedBox.shrink();
    final DateTime now = ref.watch(clockProvider)();
    final int? delta = netWorthDelta(ref.watch(netSnapshotsProvider).valueOrNull ?? const [], w, now);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.block),
      child: Pressable.card(
        key: const Key('kartu-kekayaan'),
        onTap: () => context.push(Routes.kekayaan),
        semanticLabel: 'Kekayaan bersih',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(HiIcons.bars, size: 20, color: c.accentText),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kekayaan bersih', style: t.caption.copyWith(color: c.muted)),
                Text(hidden ? 'Rp••••' : Rupiah.format(w.net), style: t.number.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
            ),
            if (delta != null && delta != 0 && !hidden)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: delta > 0 ? c.goodSoft : c.dangerSoft,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  '${delta > 0 ? '▲' : '▼'} ${Rupiah.compact(delta.abs())}',
                  style: t.label.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: delta > 0 ? c.goodInk : c.danger),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
