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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/month_switcher.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/segmented_control.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../security/app_gate.dart';
import '../transactions/data/transactions_dao.dart';
import '../wallets/data/wallets_dao.dart';
import 'widgets/daily_chart.dart';
import '../budget/data/budget_insights.dart' show shortCategoryName;
import 'widgets/cash_flow_chart.dart';
import 'widgets/donut_chart.dart';
import '../../core/widgets/hi_icons.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  late DateTime _month = ref.read(currentMonthProvider);
  TxKind _kind = TxKind.pengeluaran;

  /// Filter dompet (Pro). null = semua dompet.
  int? _walletId;

  /// Rentang tren (Pro): 6 atau 12 bulan.
  int _trendMonths = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final DateTime prevMonth = DateTime(_month.year, _month.month - 1);
    final bool isPro = ref.watch(isProProvider);
    final int? wallet = isPro ? _walletId : null;
    final PeriodSummary s =
        ref.watch(reportSummaryProvider((month: _month, walletId: wallet))).valueOrNull ?? (income: 0, expense: 0);
    final PeriodSummary prev =
        ref.watch(reportSummaryProvider((month: prevMonth, walletId: wallet))).valueOrNull ?? (income: 0, expense: 0);
    final Map<DateTime, int> daily =
        ref.watch(dailyExpenseProvider((month: _month, walletId: wallet))).valueOrNull ?? const {};
    final List<CategoryTotal> totals =
        ref.watch(categoryTotalsProvider((month: _month, kind: _kind, walletId: wallet))).valueOrNull ?? const [];
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];

    final bool isCurrent = _month.year == now.year && _month.month == now.month;
    final int daysCounted = isCurrent ? now.day : DateTime(_month.year, _month.month + 1, 0).day;
    final int net = s.income - s.expense;

    final List<TxDetail>? recent = ref.watch(recentTxProvider).valueOrNull;
    final bool tooFew = recent != null && recent.length < 3;
    final List<DonutSlice> slices = donutSlices(totals);
    final int kindTotal = totals.fold(0, (sum, e) => sum + e.total);
    final CategoryTotal? biggest = _kind == TxKind.pengeluaran && totals.isNotEmpty
        ? totals.reduce((a, b) => b.total > a.total ? b : a)
        : (ref.watch(categoryTotalsProvider((month: _month, kind: TxKind.pengeluaran, walletId: wallet))).valueOrNull ??
                const <CategoryTotal>[])
            .fold<CategoryTotal?>(null, (m, e) => m == null || e.total > m.total ? e : m);
    final int trendMonths = isPro ? _trendMonths : 6;
    final List<MonthTotal> trend =
        ref.watch(monthlyTotalsProvider((lastMonth: _month, months: trendMonths, walletId: wallet))).valueOrNull ??
            const [];
    final String period = isCurrent
        ? (now.day == 1
            ? '1 ${DateFmt.monthsShort[now.month - 1]}'
            : '1–${now.day} ${DateFmt.monthsShort[now.month - 1]}')
        : DateFmt.month(_month);

    void openRiwayat(Category cat) => context.push(
          Uri(path: Routes.riwayat, queryParameters: {
            'month': DateFmt.monthKey(_month),
            'category': '${cat.id}',
          }).toString(),
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Row(
              children: [
                Expanded(child: Text('Laporan', style: t.pageTitle)),
                if (!tooFew) MonthPill(month: _month, now: now, onChanged: (m) => setState(() => _month = m)),
              ],
            ),
            const SizedBox(height: AppSpace.block),
            if (tooFew)
              _NotEnough(count: recent.length)
            else if (!FreeLimits.canViewReport(_month, now, isPro: isPro))
              const ProTeaser(
                reason: ProReason.laporan,
                body: 'Versi gratis menampilkan laporan bulan ini dan bulan lalu. '
                    'Riwayat transaksi bulan-bulan sebelumnya tetap bisa dilihat di Riwayat.',
              )
            else ...[
              if (wallets.length > 1) ...[
                _WalletFilter(
                  wallets: wallets,
                  selected: wallet,
                  isPro: isPro,
                  onSelected: (id) => isPro ? setState(() => _walletId = id) : openPremium(context, ProReason.laporan),
                ),
                const SizedBox(height: AppSpace.block),
              ],
              // Ringkasan bulan (app).
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
              const SizedBox(height: AppSpace.x12),
              // Donat per kategori (desain), dengan pilihan Pengeluaran/Pemasukan dari app.
              _Panel(
                title: '${_kind.label} per kategori',
                trailing: Text(period, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                children: [
                  AppSegmentedControl<TxKind>(
                    options: const [TxKind.pengeluaran, TxKind.pemasukan],
                    selected: _kind,
                    onSurface: true,
                    labelOf: (k) => k.label,
                    onChanged: (k) => setState(() => _kind = k),
                  ),
                  if (slices.isEmpty)
                    EmptyState(
                      icon: HiIcons.bars,
                      title: 'Belum ada ${_kind.label.toLowerCase()}',
                      body: 'di ${DateFmt.month(_month)}',
                    )
                  else
                    CategoryDonut(slices: slices, total: kindTotal, onTap: openRiwayat),
                ],
              ),
              const SizedBox(height: AppSpace.x12),
              // Pengeluaran harian (app).
              _Panel(
                title: 'Pengeluaran harian',
                children: [DailyExpenseChart(month: _month, values: daily, now: now)],
              ),
              const SizedBox(height: AppSpace.x12),
              // Arus kas (desain): 6 bulan gratis; 12 bulan & tabel = Pro.
              _Panel(
                title: 'Arus kas $trendMonths bulan',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Legend(color: c.good, label: 'Masuk'),
                    const SizedBox(width: AppSpace.x12),
                    _Legend(color: c.accent, label: 'Keluar'),
                  ],
                ),
                children: [
                  CashFlowChart(data: trend, onTapMonth: (m) => setState(() => _month = m)),
                  AppSegmentedControl<int>(
                    options: const [6, 12],
                    selected: trendMonths,
                    onSurface: true,
                    labelOf: (m) => m == 12 && !isPro ? '12 bulan · PRO' : '$m bulan',
                    onChanged: (m) =>
                        isPro || m == 6 ? setState(() => _trendMonths = m) : openPremium(context, ProReason.laporan),
                  ),
                ],
              ),
              if (isPro) ...[
                const SizedBox(height: AppSpace.x8),
                _TrendTable(data: trend, onTapMonth: (m) => setState(() => _month = m)),
              ],
              const SizedBox(height: AppSpace.x12),
              // Kartu kecil (desain).
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      label: 'Rata-rata per hari',
                      value: Rupiah.compact(s.expense == 0 ? 0 : (s.expense / daysCounted).round()),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(
                    child: _Tile(
                      label: 'Kategori terbesar',
                      value: biggest == null ? '–' : shortCategoryName(biggest.category.name),
                    ),
                  ),
                ],
              ),
            ],
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

class _WalletFilter extends StatelessWidget {
  const _WalletFilter({required this.wallets, required this.selected, required this.isPro, required this.onSelected});

  final List<WalletBalance> wallets;
  final int? selected;
  final bool isPro;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(label: 'Semua dompet', selected: selected == null, onTap: () => onSelected(null)),
          for (final w in wallets) ...[
            const SizedBox(width: AppSpace.x8),
            AppChip(
              label: w.wallet.name,
              icon: isPro ? AppIcons.of(w.wallet.icon) : HiIcons.lock,
              selected: selected == w.wallet.id,
              onTap: () => onSelected(w.wallet.id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu bagian Laporan: judul 15/700 + aksi kanan, isi berjarak 16.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children, this.trailing});

  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.title)),
              if (trailing != null) trailing!,
            ],
          ),
          for (final Widget w in children) ...[const SizedBox(height: AppSpace.x16), w],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: AppSpace.x4),
          Text(label, style: context.text.label.copyWith(fontWeight: FontWeight.w500, color: context.colors.sub)),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
          const SizedBox(height: AppSpace.x4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.number.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Laporan kosong (desain): cincin n/3 + ajakan mencatat + kerangka "Nanti di sini".
class _NotEnough extends StatelessWidget {
  const _NotEnough({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int left = 3 - count;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpace.x16, AppSpace.x24, AppSpace.x16, AppSpace.x16),
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
          child: Column(
            children: [
              SizedBox.square(
                dimension: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 120,
                      child: CircularProgressIndicator(
                        value: count / 3,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: c.chip,
                        color: c.accent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count/3', style: t.number.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
                        Text('transaksi', style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x16),
              Text('Laporan muncul setelah 3 transaksi', textAlign: TextAlign.center, style: t.section),
              const SizedBox(height: AppSpace.x8),
              Text(
                '${left == 1 ? 'Satu' : left == 2 ? 'Dua' : 'Tiga'} catatan lagi, dan kamu bisa melihat ke mana uangmu pergi bulan ini.',
                textAlign: TextAlign.center,
                style: t.body.copyWith(fontSize: 14, color: c.sub),
              ),
              const SizedBox(height: AppSpace.x16),
              AppButton(label: 'Catat transaksi', onPressed: () => context.push(Routes.catat)),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        ExcludeSemantics(
          child: Opacity(
            opacity: 0.6,
            child: Container(
              padding: const EdgeInsets.all(AppSpace.card),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: c.line2, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nanti di sini', style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.muted)),
                  const SizedBox(height: AppSpace.x12),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final double h in const [40, 64, 52, 80, 58, 30])
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 18,
                                height: h,
                                decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(5)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tabel arus kas (Pro): data lengkap di samping grafik; ketuk baris untuk membuka bulan itu.
class _TrendTable extends StatelessWidget {
  const _TrendTable({required this.data, required this.onTapMonth});

  final List<MonthTotal> data;
  final ValueChanged<DateTime> onTapMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final TextStyle head = t.label.copyWith(color: c.muted);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
            child: Row(
              children: [
                Expanded(child: Text('Bulan', style: head)),
                SizedBox(width: 88, child: Text('Masuk', textAlign: TextAlign.right, style: head)),
                SizedBox(width: 88, child: Text('Keluar', textAlign: TextAlign.right, style: head)),
              ],
            ),
          ),
          for (final e in data.reversed)
            Pressable(
              onTap: () => onTapMonth(e.month),
              semanticLabel:
                  '${DateFmt.month(e.month)}, masuk ${Rupiah.format(e.income)}, keluar ${Rupiah.format(e.expense)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
                child: Row(
                  children: [
                    Expanded(child: Text(DateFmt.month(e.month), style: t.caption.copyWith(color: c.ink))),
                    SizedBox(
                      width: 88,
                      child: Text(Rupiah.compact(e.income),
                          textAlign: TextAlign.right, style: t.number.copyWith(fontSize: 13, color: c.good)),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(Rupiah.compact(e.expense),
                          textAlign: TextAlign.right, style: t.number.copyWith(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
