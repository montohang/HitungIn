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
import '../../core/widgets/screen_header.dart';
import '../settings/widgets/settings_tile.dart' show FieldLabel, showAppSheet;
import '../security/app_gate.dart';
import 'data/transactions_dao.dart';
import 'widgets/tx_row.dart';
import '../../core/widgets/hi_icons.dart';

/// Riwayat per bulan. Bisa dibuka dengan filter dari Laporan:
/// `/riwayat?month=2026-10&category=3`.
class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key, this.initialMonth, this.categoryId, this.walletId});

  final DateTime? initialMonth;
  final int? categoryId;

  /// Dari Dompet › Lihat riwayat.
  final int? walletId;

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  final TextEditingController _search = TextEditingController();
  late DateTime _month;
  TxKind? _kind;
  int? _categoryId;
  int? _walletId;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth ?? ref.read(currentMonthProvider);
    _categoryId = widget.categoryId;
    _walletId = widget.walletId;
  }

  @override
  void didUpdateWidget(RiwayatScreen old) {
    super.didUpdateWidget(old);
    // Tab tetap hidup (StatefulShellRoute), jadi filter baru datang lewat sini.
    if (widget.initialMonth != old.initialMonth || widget.categoryId != old.categoryId) {
      setState(() {
        if (widget.initialMonth != null) _month = widget.initialMonth!;
        _categoryId = widget.categoryId;
        _kind = null;
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtered => _month != ref.read(currentMonthProvider) || _categoryId != null;

  Future<void> _openFilter() async {
    final DateTime now = ref.read(clockProvider)();
    final List<Category> cats = ref.read(activeCategoriesProvider).valueOrNull ?? const [];
    await showAppSheet<void>(
      context,
      title: 'Filter riwayat',
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(VoidCallback f) {
            setState(f);
            setSheet(() {});
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Bulan'),
              MonthSwitcher(month: _month, now: now, onChanged: (m) => update(() => _month = m)),
              const SizedBox(height: AppSpace.x16),
              const FieldLabel('Kategori'),
              Wrap(
                spacing: AppSpace.x8,
                runSpacing: AppSpace.x8,
                children: [
                  AppChip(label: 'Semua', selected: _categoryId == null, onTap: () => update(() => _categoryId = null)),
                  for (final Category cat in cats)
                    AppChip(
                      label: cat.name,
                      icon: AppIcons.of(cat.icon),
                      selected: cat.id == _categoryId,
                      onTap: () => update(() => _categoryId = cat.id),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.x24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Atur ulang',
                      variant: AppButtonVariant.outline,
                      onPressed: () => update(() {
                        _month = ref.read(currentMonthProvider);
                        _categoryId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(child: AppButton(label: 'Selesai', onPressed: () => Navigator.pop(context))),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final TxQuery query =
        (month: _month, kind: _kind, categoryId: _categoryId, walletId: _walletId, search: _search.text.trim());
    final AsyncValue<List<TxDetail>> async = ref.watch(txListProvider(query));
    final List<TxDetail> items = async.valueOrNull ?? const [];
    final Category? category = _categoryId == null
        ? null
        : (ref.watch(activeCategoriesProvider).valueOrNull ?? const []).where((c) => c.id == _categoryId).firstOrNull;
    final bool thisMonth = _month == DateTime(now.year, now.month);
    final bool anyFilter = query.search.isNotEmpty || _kind != null || _categoryId != null || _walletId != null;
    final String? walletName = _walletId == null
        ? null
        : (ref.watch(walletBalancesProvider).valueOrNull ?? const [])
            .where((w) => w.wallet.id == _walletId)
            .firstOrNull
            ?.wallet
            .name;

    // Kelompokkan per hari (daftar sudah terurut terbaru dulu).
    final List<(DateTime, List<TxDetail>)> groups = [];
    for (final d in items) {
      final DateTime day = DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month, d.tx.occurredAt.day);
      if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
      groups.last.$2.add(d);
    }
    final int sumIn = items.where((d) => d.tx.kind == TxKind.pemasukan).fold(0, (s, d) => s + d.tx.amount);
    final int sumOut = items.where((d) => d.tx.kind == TxKind.pengeluaran).fold(0, (s, d) => s + d.tx.amount);
    // Desain: "Masuk (17–19 Okt)". Bulan ini → 1 s.d. hari ini; bulan lain → nama bulan.
    final String period = thisMonth
        ? (now.day == 1
            ? '1 ${DateFmt.monthsShort[now.month - 1]}'
            : '1–${now.day} ${DateFmt.monthsShort[now.month - 1]}')
        : '${DateFmt.monthsShort[_month.month - 1]} ${_month.year}';

    String dayLabel(DateTime day) {
      final String rel = DateFmt.relativeDay(day, now: now);
      final String full = '${DateFmt.weekdays[day.weekday - 1]}, ${DateFmt.date(day, now: now)}';
      return rel == 'Hari ini' || rel == 'Kemarin' ? '$rel · $full' : full;
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppSpace.screen.copyWith(bottom: 0),
              sliver: SliverList.list(
                children: [
                  ScreenHeader(
                    title: 'Riwayat',
                    large: true,
                    trailing: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SquareIconButton(icon: HiIcons.filter, label: 'Filter lanjutan', onTap: _openFilter),
                        if (_filtered)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: AppSpace.x16, right: AppSpace.x4),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        Icon(HiIcons.search, size: 18, color: c.muted),
                        const SizedBox(width: AppSpace.x12),
                        Expanded(
                          child: TextField(
                            key: const Key('cari'),
                            controller: _search,
                            style: t.item.copyWith(fontWeight: FontWeight.w500),
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Cari nama, catatan, atau nominal',
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_search.text.isNotEmpty)
                          IconButton(
                            icon: Icon(HiIcons.close, size: 18, color: c.muted),
                            tooltip: 'Hapus pencarian',
                            onPressed: () => setState(_search.clear),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        if (!thisMonth) ...[
                          AppChip(
                            label: DateFmt.month(_month),
                            icon: HiIcons.close,
                            selected: true,
                            onTap: () => setState(() => _month = DateTime(now.year, now.month)),
                          ),
                          const SizedBox(width: AppSpace.x8),
                        ],
                        if (walletName != null) ...[
                          AppChip(
                            label: walletName,
                            icon: HiIcons.close,
                            selected: true,
                            onTap: () => setState(() => _walletId = null),
                          ),
                          const SizedBox(width: AppSpace.x8),
                        ],
                        if (category != null) ...[
                          AppChip(
                            label: category.name,
                            icon: HiIcons.close,
                            selected: true,
                            onTap: () => setState(() => _categoryId = null),
                          ),
                          const SizedBox(width: AppSpace.x8),
                        ],
                        for (final (String label, TxKind? kind) in const [
                          ('Semua', null),
                          ('Pengeluaran', TxKind.pengeluaran),
                          ('Pemasukan', TxKind.pemasukan),
                          ('Pindah Saldo', TxKind.transfer),
                        ]) ...[
                          AppChip(label: label, selected: _kind == kind, onTap: () => setState(() => _kind = kind)),
                          const SizedBox(width: AppSpace.x8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Row(
                    children: [
                      Expanded(child: _SumTile(label: 'Masuk ($period)', value: Rupiah.format(sumIn, signed: true), color: sumIn > 0 ? c.good : c.ink)),
                      const SizedBox(width: AppSpace.x8),
                      Expanded(
                        child: _SumTile(
                          label: 'Keluar ($period)',
                          value: Rupiah.format(-sumOut, signed: true),
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x16),
                ],
              ),
            ),
            if (async.hasValue && items.isEmpty)
              SliverToBoxAdapter(
                child: anyFilter
                    ? const EmptyState(
                        icon: HiIcons.search,
                        title: 'Tidak ada transaksi yang cocok',
                        body: 'Coba kata lain atau ubah filter.',
                      )
                    : EmptyState(
                        icon: HiIcons.receipt,
                        title: 'Belum ada transaksi di ${DateFmt.month(_month)}',
                        action: 'Catat transaksi',
                        onAction: () => context.push(Routes.catat),
                      ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x24),
              sliver: SliverList.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final (DateTime day, List<TxDetail> list) = groups[i];
                  final int net = list.fold(0, (sum, d) => sum + txSignedAmount(d.tx));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.x16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpace.x4, 0, AppSpace.x4, AppSpace.x8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dayLabel(day),
                                  style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub),
                                ),
                              ),
                              if (net != 0)
                                Text(
                                  Rupiah.format(net, signed: true),
                                  style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub),
                                ),
                            ],
                          ),
                        ),
                        AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
                          child: Column(
                            children: [
                              for (final (int j, TxDetail d) in list.indexed) ...[
                                if (j > 0) Divider(color: c.line),
                                TxRow(detail: d, onTap: () => context.push(Routes.tx(d.tx.id))),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumTile extends StatelessWidget {
  const _SumTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
          const SizedBox(height: AppSpace.x2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.number.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}
