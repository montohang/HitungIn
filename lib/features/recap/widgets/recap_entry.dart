import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/data_providers.dart';
import '../../../core/db/providers.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../security/app_gate.dart';
import '../../settings/data/settings_dao.dart';
import '../data/weekly_recap.dart';
import '../recap_provider.dart';
import '../recap_screen.dart';

/// Chip "🔥 5 hari" di samping tanggal Beranda (tampil bila streak ≥ 1).
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final int n = ref.watch(streakProvider)?.current ?? 0;
    if (n < 1) return const SizedBox.shrink();
    return Pressable(
      onTap: () => context.push(Routes.rekap),
      semanticLabel: 'Streak mencatat $n hari',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 2),
        decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.pillAll),
        child: Text('🔥 $n hari', style: t.label.copyWith(color: c.warnInk, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Kartu "Rekap minggu lalu" di Beranda: Senin–Rabu, bila minggu lalu ada
/// catatan dan belum ditutup.
class RecapHomeCard extends ConsumerWidget {
  const RecapHomeCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    ref.watch(currentDayProvider);
    if (now.weekday > DateTime.wednesday) return const SizedBox.shrink();
    final WeeklyRecap? r = ref.watch(weeklyRecapProvider(1)).valueOrNull;
    final String? dismissed = ref.watch(recapDismissedProvider).valueOrNull;
    if (r == null || r.isEmpty || dismissed == DateFmt.dayKey(r.start)) return const SizedBox.shrink();
    final String headline = r.prevOut == 0
        ? 'Minggu pertamamu tercatat ✍️'
        : r.saved >= 0
            ? 'Kamu ${hidden ? '' : '${Rupiah.compact(r.saved)} '}lebih hemat dari minggu sebelumnya 🎉'
            : 'Minggu lalu lebih sibuk — yuk cek ke mana saja';
    Widget pill(String s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8 + 2, vertical: AppSpace.x4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: AppRadius.pillAll),
          child: Text(s, style: t.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.block),
      child: Pressable.card(
        onTap: () => context.push('${Routes.rekap}?minggu=1'),
        semanticLabel: 'Rekap minggu lalu',
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x16),
          decoration: BoxDecoration(borderRadius: AppRadius.lgAll, gradient: recapGradient(c.accent)),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REKAP MINGGU LALU · ${recapRangeLabel(r).toUpperCase()}',
                      style: t.label.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpace.x8),
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: Text(headline,
                        style: t.title.copyWith(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
                  ),
                  const SizedBox(height: AppSpace.x8 + 2),
                  Wrap(spacing: AppSpace.x8, runSpacing: AppSpace.x8, children: [
                    pill('Keluar ${hidden ? 'Rp••••' : Rupiah.compact(r.out)}'),
                    pill('${r.daysLogged}/7 hari mencatat'),
                  ]),
                  const SizedBox(height: AppSpace.x12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x8),
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: AppRadius.smAll),
                    child: Text('Lihat rekap ›', style: t.caption.copyWith(color: c.accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Pressable(
                  onTap: () => ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.recapDismissed, DateFmt.dayKey(r.start)),
                  semanticLabel: 'Tutup rekap',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: AppRadius.smAll),
                    child: const Icon(HiIcons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris "Rekap mingguan" di Laporan.
class RecapReportRow extends ConsumerWidget {
  const RecapReportRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final WeeklyRecap? r = ref.watch(weeklyRecapProvider(0)).valueOrNull;
    final int streak = ref.watch(streakProvider)?.current ?? 0;
    final String sub = [
      if (r != null) '${recapRangeLabel(r)} · berjalan',
      if (streak > 0) 'streak $streak hari',
    ].join(' · ');
    return Pressable.card(
      onTap: () => context.push(Routes.rekap),
      semanticLabel: 'Rekap mingguan',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
            child: const Text('🔥', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rekap mingguan', style: t.item.copyWith(fontSize: 14)),
              if (sub.isNotEmpty) Text(sub, style: t.caption.copyWith(color: c.muted)),
            ]),
          ),
          Icon(HiIcons.forward, size: 16, color: c.muted),
        ]),
      ),
    );
  }
}
