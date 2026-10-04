import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/month_switcher.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/segmented_control.dart';
import '../security/app_gate.dart';
import '../transactions/data/transactions_dao.dart';
import 'widgets/daily_chart.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  late DateTime _month = ref.read(currentMonthProvider);
  TxKind _kind = TxKind.pengeluaran;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final DateTime prevMonth = DateTime(_month.year, _month.month - 1);
    final PeriodSummary s = ref.watch(monthSummaryProvider(_month)).valueOrNull ?? (income: 0, expense: 0);
    final PeriodSummary prev = ref.watch(monthSummaryProvider(prevMonth)).valueOrNull ?? (income: 0, expense: 0);
    final Map<DateTime, int> daily = ref.watch(dailyExpenseProvider(_month)).valueOrNull ?? const {};
    final List<CategoryTotal> totals = ref.watch(categoryTotalsProvider((_month, _kind))).valueOrNull ?? const [];

    final bool isCurrent = _month.year == now.year && _month.month == now.month;
    final int daysCounted = isCurrent ? now.day : DateTime(_month.year, _month.month + 1, 0).day;
    final int net = s.income - s.expense;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Text('Laporan', style: t.pageTitle),
            const SizedBox(height: AppSpace.block),
            MonthSwitcher(month: _month, now: now, onChanged: (m) => setState(() => _month = m)),
            const SizedBox(height: AppSpace.block),
            Row(
              children: [
                Expanded(child: _Stat(label: 'Pemasukan', value: Rupiah.compact(s.income))),
                const SizedBox(width: AppSpace.x8),
                Expanded(
                  child: _Stat(
                    label: 'Pengeluaran',
                    value: Rupiah.compact(s.expense),
                    delta: _delta(s.expense, prev.expense, DateFmt.monthsShort[prevMonth.month - 1]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.x8),
            AppCard(
              child: Row(
                children: [
                  Expanded(child: Text('Selisih bulan ini', style: t.caption.copyWith(color: c.muted))),
                  Text(
                    Rupiah.format(net, signed: true),
                    style: t.number.copyWith(color: net >= 0 ? c.good : c.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x24),
            const SectionHeader('Pengeluaran harian'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DailyExpenseChart(month: _month, values: daily, now: now),
                  if (s.expense > 0) ...[
                    const SizedBox(height: AppSpace.x8),
                    Text(
                      'Rata-rata ${Rupiah.format((s.expense / daysCounted).round())} per hari',
                      style: t.caption.copyWith(color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x24),
            const SectionHeader('Per kategori'),
            AppSegmentedControl<TxKind>(
              options: const [TxKind.pengeluaran, TxKind.pemasukan],
              selected: _kind,
              labelOf: (k) => k.label,
              onChanged: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: AppSpace.x12),
            if (totals.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'Belum ada ${_kind.label.toLowerCase()}',
                  body: 'di ${DateFmt.month(_month)}',
                ),
              )
            else
              _CategoryBreakdown(
                totals: totals,
                onTap: (cat) => context.go(
                  Uri(path: Routes.riwayat, queryParameters: {
                    'month': DateFmt.monthKey(_month),
                    'category': '${cat.id}',
                  }).toString(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// "▲ 12% vs Sep". Null bila bulan lalu kosong.
  static String? _delta(int now, int before, String prevLabel) {
    if (before <= 0) return null;
    final int pct = ((now - before) / before * 100).round();
    if (pct == 0) return 'Sama dengan $prevLabel';
    return '${pct > 0 ? '▲' : '▼'} ${pct.abs()}% vs $prevLabel';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.delta});

  final String label;
  final String value;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.caption.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.x4),
          Text(value, style: t.amountL.copyWith(fontFeatures: const [])),
          const SizedBox(height: AppSpace.x4),
          Text(delta ?? ' ', style: t.label.copyWith(color: c.sub, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Daftar kategori terurut terbesar → terkecil. Panjang batang relatif
/// terhadap kategori terbesar; persentase = bagian dari total.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.totals, required this.onTap});

  final List<CategoryTotal> totals;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int sum = totals.fold(0, (s, e) => s + e.total);
    final int max = totals.first.total;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
      child: Column(
        children: [
          for (final (int i, CategoryTotal e) in totals.indexed) ...[
            if (i > 0) Divider(color: c.line),
            Pressable.card(
              onTap: () => onTap(e.category),
              semanticLabel: '${e.category.name}, ${Rupiah.format(e.total)}, ${(e.total / sum * 100).round()} persen',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
                child: Row(
                  children: [
                    IconTile(icon: AppIcons.of(e.category.icon), size: 40),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(e.category.name, style: t.item, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(Rupiah.format(e.total), style: t.number),
                            ],
                          ),
                          const SizedBox(height: AppSpace.x8),
                          Row(
                            children: [
                              Expanded(
                                child: AppProgressBar(
                                  value: e.total / max,
                                  height: 6,
                                  autoLevel: false,
                                  delay: AppMotion.stagger * i,
                                ),
                              ),
                              const SizedBox(width: AppSpace.x8),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '${(e.total / sum * 100).round()}%',
                                  textAlign: TextAlign.right,
                                  style: t.label.copyWith(color: c.muted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
