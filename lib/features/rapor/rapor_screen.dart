import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/providers.dart';
import '../../core/platform/share_capture.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/security/secure_store.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/rapor.dart';
import 'rapor_provider.dart';

/// Warna latar & tulisan untuk satu nilai (null = belum dinilai).
({Color soft, Color ink}) raporTone(AppColors c, RaporGrade? g) => switch (g) {
      RaporGrade.juara => (soft: c.goodSoft, ink: c.goodInk),
      RaporGrade.aman => (soft: c.accentSoft, ink: c.accentText),
      RaporGrade.nanggung => (soft: c.warnSoft, ink: c.warnInk),
      RaporGrade.waduh => (soft: c.dangerSoft, ink: c.danger),
      null => (soft: c.chip, ink: c.muted),
    };

String raporLabel(RaporGrade? g) => g?.label ?? raporUngradedLabel;
String raporDots(RaporGrade? g) => g?.dots ?? raporUngradedDots;
String raporEmoji(RaporGrade? g) => g?.emoji ?? '❔';

String raporRoute(DateTime month) => '${Routes.rapor}?bulan=${DateFmt.monthKey(month)}';

/// Rapor Keuangan bulanan (P3d, Claude Design › Rapor bulanan).
class RaporScreen extends ConsumerWidget {
  const RaporScreen({super.key, this.month});

  /// Bulan rapor; null = bulan lalu.
  final DateTime? month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final DateTime m = month ?? lastCompletedMonth(now);
    final Rapor? r = ref.watch(raporProvider(m));
    final bool hasData = ref.watch(raporMonthsProvider).contains(DateTime(m.year, m.month));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpace.screen,
                children: [
                  ScreenHeader(
                    title: 'Rapor bulanan',
                    large: true,
                    trailing: Pressable(
                      onTap: () => context.push(Routes.raporArsip),
                      semanticLabel: 'Arsip rapor',
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                        child: Text('Arsip', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  if (r == null)
                    const SizedBox(height: 200)
                  else if (!hasData)
                    _Empty(month: m)
                  else ...[
                    _Hero(r: r),
                    const SizedBox(height: AppSpace.x12),
                    if (r.lowData) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
                        decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.mdAll),
                        child: Text(
                          'Datanya belum lengkap: baru ${r.daysLogged} dari ${r.daysCounted} hari tercatat. Nilai lain mungkin kurang akurat.',
                          style: t.caption.copyWith(color: c.warnInk, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: AppSpace.x12),
                    ],
                    _NoteCard(text: r.note),
                    const SizedBox(height: AppSpace.x16),
                    Text('Skor per aspek', style: t.section),
                    const SizedBox(height: AppSpace.x8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                      decoration:
                          BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                      child: Column(
                        children: [
                          for (final (int i, AspectScore s) in r.scores.indexed)
                            _AspectRow(s: s, trend: r.trendOf(s.aspect), last: i == r.scores.length - 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x8),
                    Text(
                      'Batas nilai memakai anjuran umum perencana keuangan, bukan ketentuan OJK/BI. Ketuk aspek untuk lihat rumus & dasarnya.',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    _Totals(r: r),
                    if (r.categories.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x16),
                      Text('Kategori terbesar', style: t.section),
                      const SizedBox(height: AppSpace.x8),
                      _Categories(r: r),
                    ],
                    if (r.highlights.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x16),
                      Text('Sorotan', style: t.section),
                      const SizedBox(height: AppSpace.x8),
                      _Highlights(r: r),
                    ],
                    if (r.tips.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.x16),
                      Text('Untuk ${raporMonthName(DateTime(m.year, m.month + 1))}', style: t.section),
                      const SizedBox(height: AppSpace.x8),
                      for (final RaporTip tip in r.tips) ...[
                        _TipCard(tip: tip),
                        const SizedBox(height: AppSpace.x8),
                      ],
                    ],
                    const SizedBox(height: AppSpace.x8),
                    const _NotifySetting(),
                  ],
                ],
              ),
            ),
            if (r != null && hasData)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
                child: AppButton(
                  key: const Key('bagikan-rapor'),
                  label: 'Bagikan rapor',
                  large: true,
                  onPressed: () => showAppSheet<void>(context, title: 'Bagikan rapor', builder: (_) => _ShareSheet(r: r)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x24),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpace.x12),
          Text('Rapor pertamamu terbit 1 ${raporMonthName(DateTime(month.year, month.month + 2))}', textAlign: TextAlign.center, style: t.section),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Rapor menilai bulan yang sudah selesai: menabung, cicilan, tagihan, budget, ketahanan, dan kebiasaan mencatat. Terus catat, ya!',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: c.sub, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.r});

  final Rapor r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int up = r.scores.where((s) => (r.trendOf(s.aspect) ?? 0) > 0).length;
    final int down = r.scores.where((s) => (r.trendOf(s.aspect) ?? 0) < 0).length;
    final String meta = [
      '${r.graded} aspek dinilai',
      if (up > 0) '$up naik',
      if (down > 0) '$down turun',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(AppSpace.x16 + 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(colors: [Color.lerp(c.card, c.accent, 0.55)!, c.accent]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RAPOR ${raporMonthName(r.month).toUpperCase()} ${r.month.year}',
                    style: t.label.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: AppSpace.x4),
                Text(r.headline, style: t.screenTitle.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpace.x4),
                Text(meta, style: t.caption.copyWith(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x12),
          _Stamp(grade: r.overall, size: 92),
        ],
      ),
    );
  }
}

/// Cap nilai keseluruhan (emoji, label, titik).
class _Stamp extends StatelessWidget {
  const _Stamp({required this.grade, required this.size});

  final RaporGrade? grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Transform.rotate(
      angle: -0.14,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.white.withValues(alpha: 0.12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(raporEmoji(grade), style: TextStyle(fontSize: size * 0.34, height: 1)),
            Text(raporLabel(grade),
                style: t.label.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.14)),
            Text(raporDots(grade), style: TextStyle(color: Colors.white, fontSize: size * 0.1, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12 + 2),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kata HitungIn', style: t.label.copyWith(color: c.muted)),
                const SizedBox(height: AppSpace.x4),
                Text(text, style: t.body.copyWith(color: c.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectRow extends StatelessWidget {
  const _AspectRow({required this.s, required this.trend, required this.last});

  final AspectScore s;
  final int? trend;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ({Color soft, Color ink}) tone = raporTone(c, s.grade);
    final (String tr, Color trColor) = switch (trend) {
      null => ('', c.muted),
      > 0 => ('▲ naik', c.good),
      < 0 => ('▼ turun', c.danger),
      _ => ('= tetap', c.muted),
    };
    return Pressable.card(
      onTap: () => showAppSheet<void>(context, title: s.aspect.label, builder: (_) => _AspectSheet(s: s)),
      semanticLabel: '${s.aspect.label}, ${raporLabel(s.grade)}. ${s.reason}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone.soft, borderRadius: AppRadius.smAll),
              child: Text(raporEmoji(s.grade), style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(s.aspect.label, style: t.title)),
                    if (tr.isNotEmpty) ...[
                      const SizedBox(width: AppSpace.x8 - 2),
                      Text(tr, style: t.label.copyWith(color: trColor, fontWeight: FontWeight.w700)),
                    ],
                  ]),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${raporLabel(s.grade)} '),
                      TextSpan(text: raporDots(s.grade), style: const TextStyle(fontSize: 9, letterSpacing: 1)),
                    ]),
                    style: t.label.copyWith(color: tone.ink, fontWeight: FontWeight.w800),
                  ),
                  Text(s.reason, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Icon(HiIcons.forward, size: 18, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// "Dari mana nilai ini?"
class _AspectSheet extends StatelessWidget {
  const _AspectSheet({required this.s});

  final AspectScore s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ({Color soft, Color ink}) tone = raporTone(c, s.grade);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.soft, borderRadius: AppRadius.mdAll),
            child: Text(raporEmoji(s.grade), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Text('${raporLabel(s.grade)} ${raporDots(s.grade)} · dari mana nilai ini?',
                style: t.caption.copyWith(color: tone.ink, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: AppSpace.x12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
          decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rumus', style: t.label.copyWith(color: c.muted)),
              Text(s.aspect.formula, style: t.item.copyWith(fontSize: 14)),
              const SizedBox(height: AppSpace.x8),
              Text('Angkamu bulan ini', style: t.label.copyWith(color: c.muted)),
              Text(s.mine, style: t.number),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        Row(
          children: [
            for (final (int i, RaporGrade g) in RaporGrade.values.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.x4 + 2),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.x8, horizontal: AppSpace.x4),
                  decoration: BoxDecoration(
                    color: g == s.grade ? raporTone(c, g).soft : Colors.transparent,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: g == s.grade ? raporTone(c, g).ink : c.line, width: 2),
                  ),
                  child: Column(children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 18)),
                    Text(g.label, style: t.label.copyWith(color: raporTone(c, g).ink, fontWeight: FontWeight.w800)),
                    Text(s.aspect.bands[i],
                        textAlign: TextAlign.center, style: t.label.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: c.sub)),
                  ]),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.x12),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Dasar acuan: ', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
            TextSpan(text: s.aspect.basis),
          ]),
          style: t.caption.copyWith(color: c.sub, height: 1.55),
        ),
        if (s.tip != null) ...[
          const SizedBox(height: AppSpace.x12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
            decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdAll),
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Saran: ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: s.tip),
              ]),
              style: t.caption.copyWith(color: c.ink, height: 1.55),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Mengerti', large: true, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.r});

  final Rapor r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    String delta(int now, int before, {bool lowerIsBetter = false}) {
      if (before == 0) return '';
      final int d = now - before;
      if (d == 0) return '= bulan lalu';
      return '${d > 0 ? '▲' : '▼'} ${Rupiah.compact(d.abs())}';
    }

    final List<(String, String, String, Color)> items = [
      ('Masuk', Rupiah.compact(r.income), r.income == 0 ? 'belum dicatat' : delta(r.income, r.prevIncome), c.good),
      ('Keluar', Rupiah.compact(r.expense), delta(r.expense, r.prevExpense, lowerIsBetter: true), c.ink),
      (
        'Sisa',
        r.income == 0 ? '—' : Rupiah.compact(r.net),
        r.income == 0 ? '' : '${(r.net * 100 / r.income).round()}% dari masuk',
        r.net < 0 ? c.danger : c.ink
      ),
    ];
    return Row(
      children: [
        for (final (int i, (String k, String v, String d, Color col)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.x8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpace.x12),
              decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(v, style: t.number.copyWith(fontWeight: FontWeight.w800, color: col)),
                ),
                Text(d, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label.copyWith(fontSize: 11, color: c.muted)),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.r});

  final Rapor r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          for (final (int i, RaporCategory k) in r.categories.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
              decoration: BoxDecoration(border: i == r.categories.length - 1 ? null : Border(bottom: BorderSide(color: c.line))),
              child: Row(children: [
                Expanded(child: Text(k.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.item.copyWith(fontSize: 14))),
                if (k.deltaPct != null)
                  Text(
                    k.deltaPct == 0 ? '= 0%' : '${k.deltaPct! > 0 ? '▲' : '▼'} ${k.deltaPct!.abs()}%',
                    style: t.label.copyWith(color: k.deltaPct! > 0 ? c.danger : (k.deltaPct! < 0 ? c.good : c.muted)),
                  ),
                const SizedBox(width: AppSpace.x8),
                Text(Rupiah.format(k.amount), style: t.number.copyWith(fontSize: 14)),
                SizedBox(
                  width: 64,
                  child: Text(
                    k.budgetPct == null ? '' : (k.budgetPct! > 100 ? 'jebol ${k.budgetPct}%' : '${k.budgetPct}%'),
                    textAlign: TextAlign.right,
                    style: t.label.copyWith(fontSize: 11, color: (k.budgetPct ?? 0) > 100 ? c.danger : c.muted),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.r});

  final Rapor r;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          for (final (int i, RaporHighlight h) in r.highlights.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
              decoration: BoxDecoration(border: i == r.highlights.length - 1 ? null : Border(bottom: BorderSide(color: c.line))),
              child: Row(children: [
                SizedBox(width: 28, child: Text(h.icon, style: const TextStyle(fontSize: 18))),
                const SizedBox(width: AppSpace.x8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.label, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                    Text(h.value, style: t.item.copyWith(fontSize: 14)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

String raporActionRoute(RaporAction a) => switch (a) {
      RaporAction.aturBudget => Routes.aturBudget,
      RaporAction.tagihan => Routes.tagihan,
      RaporAction.target => Routes.target,
      RaporAction.catat => Routes.catat,
    };

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final RaporTip tip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.lgAll),
      child: Row(children: [
        Expanded(child: Text(tip.text, style: t.caption.copyWith(color: c.ink, height: 1.5))),
        const SizedBox(width: AppSpace.x12),
        Pressable(
          onTap: () => context.push(raporActionRoute(tip.target)),
          semanticLabel: tip.action,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
            decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.smAll),
            child: Text(tip.action, style: t.label.copyWith(color: c.onAccent, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _NotifySetting extends ConsumerWidget {
  const _NotifySetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool on = ref.watch(raporMonthlyProvider).valueOrNull ?? true;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: on,
      activeTrackColor: c.accent,
      title: Text('Notifikasi rapor tiap tanggal 1', style: t.item.copyWith(fontSize: 14)),
      subtitle: Text('Pukul 08.00', style: t.caption.copyWith(color: c.muted)),
      onChanged: (v) => ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.raporMonthly, '$v'),
    );
  }
}

/// Arsip rapor: tren nilai & daftar bulan.
class RaporArchiveScreen extends ConsumerWidget {
  const RaporArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final List<DateTime> months = ref.watch(raporMonthsProvider);
    final List<Rapor> rapors = [
      for (final m in months)
        if (ref.watch(raporProvider(m)) case final Rapor r) r,
    ];
    final List<Rapor> chart = rapors.take(6).toList().reversed.toList();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            const ScreenHeader(title: 'Arsip rapor', large: true),
            const SizedBox(height: AppSpace.x16),
            if (rapors.isEmpty)
              Text('Belum ada rapor. Rapor pertama terbit tanggal 1 bulan depan.',
                  textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted))
            else ...[
              Container(
                padding: const EdgeInsets.all(AppSpace.card),
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nilai keseluruhan ${chart.length} bulan terakhir', style: t.caption.copyWith(color: c.muted)),
                  const SizedBox(height: AppSpace.x12),
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final Rapor r in chart)
                          SizedBox(
                            width: 40,
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                Text(raporEmoji(r.overall), style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: AppSpace.x4),
                                Container(
                                  height: r.overall == null ? 6 : r.average / 4 * 70,
                                  decoration: BoxDecoration(color: raporTone(c, r.overall).ink, borderRadius: AppRadius.smAll),
                                ),
                                const SizedBox(height: AppSpace.x4),
                                Text(DateFmt.monthsShort[r.month.month - 1], style: t.label.copyWith(color: c.muted)),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpace.x16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                child: Column(children: [
                  for (final (int i, Rapor r) in rapors.indexed)
                    Pressable.card(
                      onTap: () => context.push(raporRoute(r.month)),
                      semanticLabel: 'Rapor ${DateFmt.month(r.month)}, ${raporLabel(r.overall)}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
                        decoration: BoxDecoration(border: i == rapors.length - 1 ? null : Border(bottom: BorderSide(color: c.line))),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: raporTone(c, r.overall).soft, borderRadius: AppRadius.smAll),
                            child: Text(raporEmoji(r.overall), style: const TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: AppSpace.x12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text.rich(TextSpan(children: [
                                TextSpan(text: '${DateFmt.month(r.month)} · '),
                                TextSpan(text: raporLabel(r.overall), style: TextStyle(color: raporTone(c, r.overall).ink)),
                              ]), style: t.title),
                              Text(r.headline, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                            ]),
                          ),
                          Icon(HiIcons.forward, size: 18, color: c.muted),
                        ]),
                      ),
                    ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.r});

  final Rapor r;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final GlobalKey _card = GlobalKey();
  bool _amounts = false;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final bool ok = await shareBoundaryPng(
        _card,
        fileName: 'rapor-hitungin.png',
        title: 'Bagikan rapor lewat',
        wrap: (share) => withAutoLockPaused(ref, share),
      );
      nav.pop();
      if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Menu Bagikan tidak tersedia di perangkat ini.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 248,
              height: 310,
              child: FittedBox(
                child: RepaintBoundary(key: _card, child: RaporShareCard(r: widget.r, showAmounts: _amounts, accent: c.accent)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _amounts,
          activeTrackColor: c.accent,
          title: Text('Tampilkan nominal', style: t.item.copyWith(fontSize: 14)),
          subtitle: Text('Mati: kartu hanya berisi nilai', style: t.caption.copyWith(color: c.muted)),
          onChanged: (v) => setState(() => _amounts = v),
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(label: _busy ? 'Menyiapkan…' : 'Bagikan', large: true, onPressed: _busy ? null : _share),
      ],
    );
  }
}

/// Kartu 4:5 untuk dibagikan: nilai keseluruhan + skor aspek.
class RaporShareCard extends StatelessWidget {
  const RaporShareCard({super.key, required this.r, required this.showAmounts, required this.accent});

  final Rapor r;
  final bool showAmounts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final TextStyle white = TextStyle(color: Colors.white, fontFamily: t.body.fontFamily);
    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, const Color(0xFFF2C14E), 0.45)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogoMark(size: 30, background: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 10),
            Text('HitungIn · Rapor ${raporMonthName(r.month)}', style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _Stamp(grade: r.overall, size: 84),
            const SizedBox(width: 14),
            Expanded(
              child: Text(r.headline,
                  style: t.screenTitle.copyWith(color: Colors.white, fontSize: 22, height: 1.2, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in r.scores)
                Container(
                  width: 146,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.aspect.short, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: white.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
                    Text('${raporEmoji(s.grade)} ${s.grade?.label ?? 'Belum dinilai'}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
          const Spacer(),
          if (showAmounts && r.income > 0)
            Text('Sisa ${Rupiah.compact(r.net)} dari pemasukan ${Rupiah.compact(r.income)} (${(r.net * 100 / r.income).round()}%)',
                style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Dinilai di HitungIn · offline, tanpa akun', style: white.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}
