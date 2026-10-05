import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/data_providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/month_switcher.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../security/app_gate.dart';
import 'data/budget_insights.dart';
import 'data/budgets_dao.dart';
import '../transactions/riwayat_screen.dart' show riwayatLink;
import '../../core/widgets/hi_icons.dart';

String _hex(Color x) => '#${(x.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Budget (Claude Design › Budget & Budget · kosong), dengan pilihan bulan dari app.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _month = ref.read(currentMonthProvider);

  void _atur({bool saran = false}) => context.push(Uri(path: Routes.aturBudget, queryParameters: {
        'month': DateFmt.monthKey(_month),
        if (saran) 'saran': '1',
      }).toString());

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<BudgetProgress>> async = ref.watch(budgetProgressProvider(_month));
    final List<BudgetProgress> all = async.valueOrNull ?? const [];
    final List<BudgetProgress> perCategory = [for (final b in all) if (b.category != null) b];
    final BudgetOverview? overview = budgetOverview(all);
    final bool warn = ref.watch(budgetWarnProvider).valueOrNull ?? true;
    final bool isCurrent = _month.year == now.year && _month.month == now.month;
    final int days = Dates.daysInMonth(_month.year, _month.month);
    final String monthName = DateFmt.months[_month.month - 1];
    final String subtitle = all.isEmpty
        ? '$monthName · belum diatur'
        : isCurrent
            ? '$monthName · hari ke-${now.day} dari $days'
            : '${DateFmt.month(_month)} · sudah lewat';
    final BudgetProgress? hot = isCurrent && warn ? hottestCategory(all, now) : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget', style: t.pageTitle),
                      const SizedBox(height: AppSpace.x4),
                      Text(subtitle, style: t.caption.copyWith(color: c.muted)),
                    ],
                  ),
                ),
                if (all.isNotEmpty)
                  Pressable(
                    onTap: _atur,
                    semanticLabel: 'Atur budget',
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                      child: Text('+ Atur', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.x12),
            // Pilihan bulan dari app: lihat pemakaian bulan-bulan sebelumnya.
            Align(
              alignment: Alignment.centerLeft,
              child: MonthPill(month: _month, now: now, onChanged: (m) => setState(() => _month = m)),
            ),
            const SizedBox(height: AppSpace.block),
            if (async.hasValue && all.isEmpty)
              _Empty(
                onManual: _atur,
                onSuggest: () => _atur(saran: true),
              )
            else if (overview != null) ...[
              _Overview(overview: overview, now: now, isCurrent: isCurrent, days: days),
              if (hot != null) ...[
                const SizedBox(height: AppSpace.x16),
                _Warning(budget: hot, now: now),
              ],
              if (perCategory.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x16),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x4),
                  child: Text('Per kategori', style: t.section.copyWith(fontSize: 17)),
                ),
                for (final (int i, BudgetProgress b) in perCategory.indexed)
                  _CategoryRow(
                    budget: b,
                    delay: AppMotion.stagger * i,
                    onTap: () => context.push(riwayatLink(month: _month, category: b.category!.id)),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Kartu utama: terpakai, sisa, bar dengan penanda "Hari ini".
class _Overview extends StatelessWidget {
  const _Overview({required this.overview, required this.now, required this.isCurrent, required this.days});

  final BudgetOverview overview;
  final DateTime now;
  final bool isCurrent;
  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final double ratio = overview.limit == 0 ? 0 : overview.spent / overview.limit;
    final double elapsed = isCurrent ? now.day / days : 1;
    final int left = overview.limit - overview.spent;
    final String art = '''
<svg width="78" height="64" viewBox="0 0 200 160" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="148" rx="70" ry="7" fill="${_hex(c.track)}"/>
  <rect x="54" y="48" width="92" height="98" rx="24" fill="${_hex(c.accentSoft)}" stroke="${_hex(c.accent)}" stroke-width="4"/>
  <rect x="64" y="34" width="72" height="18" rx="7" fill="${_hex(c.accent)}"/>
  <circle cx="84" cy="118" r="15" fill="#F2C14E"/>
  <circle cx="114" cy="122" r="15" fill="#F2C14E"/>
  <circle cx="100" cy="94" r="15" fill="#F6D27A"/>
</svg>''';
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Stack(
        children: [
          Positioned(right: -2, top: -4, child: ExcludeSemantics(child: SvgPicture.string(art, width: 78, height: 64))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(overview.fromTotal ? 'Terpakai' : 'Terpakai (jumlah budget kategori)',
                  style: t.caption.copyWith(color: c.muted)),
              const SizedBox(height: AppSpace.x2),
              Text(Rupiah.format(overview.spent), style: t.amountL.copyWith(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpace.x2),
              Text.rich(
                TextSpan(
                  text: 'dari ',
                  children: [
                    TextSpan(
                      text: Rupiah.format(overview.limit),
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    TextSpan(text: left >= 0 ? ' · sisa ${Rupiah.format(left)}' : ' · lewat ${Rupiah.format(-left)}'),
                  ],
                ),
                style: t.caption.copyWith(color: c.muted),
              ),
              const SizedBox(height: AppSpace.x12),
              LayoutBuilder(
                builder: (context, box) {
                  final double x = box.maxWidth * elapsed.clamp(0.0, 1.0);
                  return SizedBox(
                    height: isCurrent ? 40 : 12,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: isCurrent ? 22 : 0,
                          child: AppProgressBar(value: ratio, height: 12),
                        ),
                        if (isCurrent) ...[
                          Positioned(
                            left: (x - 30).clamp(0.0, box.maxWidth - 60),
                            width: 60,
                            top: 0,
                            child: Text(
                              'Hari ini',
                              textAlign: TextAlign.center,
                              style: t.label.copyWith(fontSize: 11, color: c.sub),
                            ),
                          ),
                          Positioned(
                            left: (x - 1).clamp(0.0, box.maxWidth - 2),
                            top: 17,
                            child: Container(
                              width: 2,
                              height: 22,
                              decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpace.x12),
              Text(
                isCurrent
                    ? 'Pemakaian ${(ratio * 100).round()}% · waktu berjalan ${(elapsed * 100).round()}%'
                    : 'Pemakaian ${(ratio * 100).round()}%',
                style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Makan & Minum lebih cepat dari jadwal" (desain).
class _Warning extends StatelessWidget {
  const _Warning({required this.budget, required this.now});

  final BudgetProgress budget;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int limit = budget.budget.limitAmount;
    final int left = limit - budget.spent;
    final int days = daysLeftInMonth(now);
    final int lastDay = Dates.daysInMonth(now.year, now.month);
    final String month = DateFmt.monthsShort[now.month - 1];
    final String body = left <= 0
        ? 'Sudah ${(budget.spent / limit * 100).round()}%, lewat ${Rupiah.compact(-left)} dari batas bulan ini.'
        : 'Sudah ${(budget.spent / limit * 100).round()}%, sisa ${Rupiah.compact(left)} untuk $days hari. '
            'Sekitar ${Rupiah.compact(safeDailySpend(budget, now))} per hari supaya aman sampai $lastDay $month.';
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.lgAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll),
            child: Icon(HiIcons.sparkle, size: 20, color: c.warnInk),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left <= 0 ? '${budget.category!.name} lewat batas' : '${budget.category!.name} lebih cepat dari jadwal',
                  style: t.title.copyWith(fontSize: 14, color: c.warnInk),
                ),
                const SizedBox(height: AppSpace.x2),
                Text(body, style: t.caption.copyWith(height: 1.5, color: c.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.budget, required this.delay, required this.onTap});

  final BudgetProgress budget;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int limit = budget.budget.limitAmount;
    final double ratio = limit == 0 ? 0 : budget.spent / limit;
    final BudgetLevel level = budgetLevelOf(ratio);
    final Color pctColor = switch (level) {
      BudgetLevel.over => c.danger,
      BudgetLevel.warn => c.warnInk,
      BudgetLevel.normal => c.ink,
    };
    return Pressable.card(
      onTap: onTap,
      semanticLabel:
          '${budget.category!.name}, ${Rupiah.format(budget.spent)} dari ${Rupiah.format(limit)}, ${(ratio * 100).round()} persen',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppPalette.soft(context, budget.category!.color),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(AppIcons.of(budget.category!.icon), size: 20, color: AppPalette.ink(context, budget.category!.color)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          budget.category!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                      ),
                      Text(
                        '${Rupiah.compact(budget.spent)} / ${Rupiah.compact(limit)}',
                        style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x8),
                  AppProgressBar(value: ratio, height: 8, delay: delay),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${(ratio * 100).round()}%',
                textAlign: TextAlign.right,
                style: t.caption.copyWith(fontWeight: FontWeight.w700, color: pctColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Budget · kosong: ilustrasi + pilihan "Mulai dari".
class _Empty extends StatelessWidget {
  const _Empty({required this.onManual, required this.onSuggest});

  final VoidCallback onManual;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final String art = '''
<svg width="150" height="120" viewBox="0 0 200 160" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="148" rx="70" ry="7" fill="${_hex(c.track)}"/>
  <rect x="54" y="48" width="92" height="98" rx="24" fill="${_hex(c.accentSoft)}" stroke="${_hex(c.accent)}" stroke-width="4"/>
  <rect x="64" y="34" width="72" height="18" rx="7" fill="${_hex(c.accent)}"/>
  <circle cx="100" cy="100" r="18" fill="none" stroke="${_hex(c.accent)}" stroke-width="4" stroke-dasharray="6 6"/>
</svg>''';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.x24),
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
          child: Column(
            children: [
              ExcludeSemantics(child: SvgPicture.string(art, width: 150, height: 120)),
              const SizedBox(height: AppSpace.x12),
              Text('Belum ada budget bulan ini', textAlign: TextAlign.center, style: t.section),
              const SizedBox(height: AppSpace.x8),
              Text(
                'Budget membantu HitungIn memberi peringatan sebelum uangmu kebablasan.',
                textAlign: TextAlign.center,
                style: t.body.copyWith(fontSize: 14, color: c.sub),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        Text('Mulai dari', style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.sub)),
        const SizedBox(height: AppSpace.x8),
        _Option(
          icon: HiIcons.filter,
          title: 'Atur manual',
          body: 'Tentukan batas tiap kategori sendiri',
          onTap: onManual,
        ),
        const SizedBox(height: AppSpace.x8),
        _Option(
          icon: HiIcons.sparkle,
          title: 'Saran dari kebiasaanmu',
          body: 'Dari rata-rata pengeluaran 3 bulan terakhir',
          onTap: onSuggest,
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.body, required this.onTap});

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable.card(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(icon, size: 20, color: c.accentText),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.item),
                  const SizedBox(height: AppSpace.x2),
                  Text(body, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                ],
              ),
            ),
            Icon(HiIcons.forward, color: c.muted),
          ],
        ),
      ),
    );
  }
}
