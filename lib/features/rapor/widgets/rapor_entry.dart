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
import '../data/rapor.dart';
import '../rapor_provider.dart';
import '../rapor_screen.dart';

/// Kartu "Rapor September terbit" di Beranda tanggal 1–5 (bisa ditutup).
class RaporHomeCard extends ConsumerWidget {
  const RaporHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    ref.watch(currentDayProvider);
    if (now.day > 5) return const SizedBox.shrink();
    final DateTime m = lastCompletedMonth(now);
    final Rapor? r = ref.watch(raporProvider(m));
    final String? dismissed = ref.watch(raporDismissedProvider).valueOrNull;
    if (r == null || r.overall == null || !ref.watch(raporMonthsProvider).contains(m) || dismissed == DateFmt.monthKey(m)) {
      return const SizedBox.shrink();
    }
    final AspectScore tabung = r.scores.firstWhere((s) => s.aspect == RaporAspect.menabung);
    final int up = r.scores.where((s) => (r.trendOf(s.aspect) ?? 0) > 0).length;
    final String meta = [
      if (tabung.value != null) 'Menabung ${(tabung.value! * 100).round()}%',
      if (up > 0) '$up aspek naik',
      'lihat rapor ›',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.block),
      child: Pressable.card(
        onTap: () => context.push(raporRoute(m)),
        semanticLabel: 'Rapor ${raporMonthName(m)} terbit, ${raporLabel(r.overall)}',
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            gradient: LinearGradient(colors: [Color.lerp(c.card, c.accent, 0.55)!, c.accent]),
          ),
          child: Stack(children: [
            Row(children: [
              Transform.rotate(
                angle: -0.14,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(raporEmoji(r.overall), style: const TextStyle(fontSize: 22, height: 1)),
                    Text(raporLabel(r.overall), style: t.label.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
              const SizedBox(width: AppSpace.x12 + 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RAPOR ${raporMonthName(m).toUpperCase()} TERBIT',
                        style: t.label.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: AppSpace.x4),
                    Text(r.headline, style: t.title.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpace.x4),
                    Text(meta, style: t.label.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
            Positioned(
              top: 0,
              right: 0,
              child: Pressable(
                onTap: () => ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.raporDismissed, DateFmt.monthKey(m)),
                semanticLabel: 'Tutup kartu rapor',
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: AppRadius.smAll),
                  child: const Icon(HiIcons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

String forecastTitle(Forecast f, DateTime now) {
  final String month = raporMonthName(now);
  return f.limit != null && f.projected > f.limit!
      ? 'Prakiraan $month ≈ ${Rupiah.compact(f.projected)}'
      : '${f.hot.first.name} sudah ${f.hot.first.pct}%';
}

String forecastBody(Forecast f) {
  final List<String> parts = [
    if (f.limit != null && f.projected > f.limit!) 'Melewati budget ${Rupiah.compact(f.limit!)} bila kecepatan belanja tetap',
    if (f.hot.isNotEmpty) '${f.hot.first.name} sudah ${f.hot.first.pct}%, sisa ${f.daysLeft} hari',
  ];
  return parts.join(' · ');
}

/// Kartu kecil "Prakiraan" di Beranda — hanya bila ada yang perlu diperhatikan.
class ForecastHomeCard extends ConsumerWidget {
  const ForecastHomeCard({super.key, required this.hidden});

  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final Forecast? f = ref.watch(forecastProvider);
    if (f == null) return const SizedBox.shrink();
    final DateTime now = ref.watch(clockProvider)();
    final String title = hidden && f.limit != null && f.projected > f.limit! ? 'Prakiraan ${raporMonthName(now)} melewati budget' : forecastTitle(f, now);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.block),
      child: Pressable.card(
        onTap: () => context.go(Routes.budget),
        semanticLabel: title,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
          decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.lgAll),
          child: Row(children: [
            const Text('📈', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.item.copyWith(fontSize: 14, color: c.warnInk, fontWeight: FontWeight.w700)),
                Text(hidden ? 'Ketuk untuk lihat di Budget' : forecastBody(f),
                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.sub, height: 1.4)),
              ]),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.muted),
          ]),
        ),
      ),
    );
  }
}

/// Kartu prakiraan akhir bulan di layar Budget (bulan berjalan).
class ForecastBudgetCard extends ConsumerWidget {
  const ForecastBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final Forecast? f = ref.watch(forecastProvider);
    if (f == null || f.limit == null || f.projected <= f.limit!) return const SizedBox.shrink();
    final DateTime now = ref.watch(clockProvider)();
    final int over = f.projected - f.limit!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.block),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Prakiraan akhir ${raporMonthName(now)}', style: t.title)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8 + 2, vertical: 3),
              decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.pillAll),
              child: Text('+${Rupiah.compact(over)} dari budget', style: t.label.copyWith(color: c.warnInk)),
            ),
          ]),
          const SizedBox(height: AppSpace.x8),
          Text('≈ ${Rupiah.format(f.projected)}', style: t.amountL.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpace.x4),
          Text(
            '${Rupiah.compact(f.spent)} dalam ${now.day} hari = ${Rupiah.compact(f.spent ~/ now.day)}/hari. '
            'Supaya pas ${Rupiah.compact(f.limit!)}, sisa ${f.daysLeft} hari cukup ${Rupiah.compact(f.perDayToFit)}/hari.',
            style: t.caption.copyWith(color: c.muted, height: 1.5),
          ),
        ]),
      ),
    );
  }
}

/// Baris "Rapor bulanan" di Laporan.
class RaporReportRow extends ConsumerWidget {
  const RaporReportRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime m = lastCompletedMonth(ref.watch(clockProvider)());
    final bool has = ref.watch(raporMonthsProvider).contains(m);
    final Rapor? r = has ? ref.watch(raporProvider(m)) : null;
    final String sub = r == null
        ? 'Terbit tiap tanggal 1'
        : '${raporMonthName(m)} · ${raporLabel(r.overall)} ${raporDots(r.overall)}';
    return Pressable.card(
      onTap: () => context.push(Routes.rapor),
      semanticLabel: 'Rapor bulanan',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
            child: Text(r == null ? '📋' : raporEmoji(r.overall), style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Rapor bulanan', style: t.item.copyWith(fontSize: 14)),
              Text(sub, style: t.caption.copyWith(color: c.muted)),
            ]),
          ),
          Icon(HiIcons.forward, size: 16, color: c.muted),
        ]),
      ),
    );
  }
}
