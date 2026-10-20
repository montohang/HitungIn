import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../security/app_gate.dart';
import '../data/goals.dart';
import '../data/goals_dao.dart';
import '../goals_provider.dart';

/// Kartu kecil Beranda (P3b): target aktif teratas. Tidak tampil bila belum
/// ada target aktif.
class GoalHomeCard extends ConsumerWidget {
  const GoalHomeCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final List<GoalWithDeposits> active = [
      for (final g in ref.watch(goalsProvider).valueOrNull ?? const <GoalWithDeposits>[])
        if (g.active) g,
    ];
    if (active.isEmpty) return const SizedBox.shrink();
    final GoalWithDeposits g = active.first;
    final DateTime now = ref.watch(clockProvider)();
    final String estimate = goalEstimateText(g.estimate(now), now: now);
    final String line = hidden
        ? 'Terkumpul ••• · ${active.length > 1 ? '${active.length} target aktif' : estimate}'
        : '${Rupiah.compact(g.saved)} dari ${Rupiah.compact(g.goal.target)}'
            '${active.length > 1 ? ' · ${active.length} target aktif' : ''}';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.block),
      child: Pressable.card(
        onTap: () => context.push(active.length > 1 ? Routes.target : Routes.targetDetail(g.goal.id)),
        semanticLabel: 'Target ${g.goal.name}, ${g.percent} persen',
        child: Container(
          padding: const EdgeInsets.all(AppSpace.card),
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                child: Text(g.goal.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(g.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title)),
                        Text('${g.percent}%', style: t.number),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x8),
                    AppProgressBar(value: g.saved / g.goal.target, height: 8, autoLevel: false, color: c.accent),
                    const SizedBox(height: AppSpace.x8),
                    Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.caption.copyWith(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
