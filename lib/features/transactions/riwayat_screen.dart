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
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/month_switcher.dart';
import '../security/app_gate.dart';
import 'data/transactions_dao.dart';
import 'widgets/tx_row.dart';

/// Riwayat per bulan. Bisa dibuka dengan filter dari Laporan:
/// `/riwayat?month=2026-10&category=3`.
class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key, this.initialMonth, this.categoryId});

  final DateTime? initialMonth;
  final int? categoryId;

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  final TextEditingController _search = TextEditingController();
  late DateTime _month;
  TxKind? _kind;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth ?? ref.read(currentMonthProvider);
    _categoryId = widget.categoryId;
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final TxQuery query = (month: _month, kind: _kind, categoryId: _categoryId, search: _search.text.trim());
    final AsyncValue<List<TxDetail>> async = ref.watch(txListProvider(query));
    final List<TxDetail> items = async.valueOrNull ?? const [];
    final Category? category = _categoryId == null
        ? null
        : (ref.watch(activeCategoriesProvider).valueOrNull ?? const []).where((c) => c.id == _categoryId).firstOrNull;

    // Kelompokkan per hari (daftar sudah terurut terbaru dulu).
    final List<(DateTime, List<TxDetail>)> groups = [];
    for (final d in items) {
      final DateTime day = DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month, d.tx.occurredAt.day);
      if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
      groups.last.$2.add(d);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppSpace.screen.copyWith(bottom: 0),
              sliver: SliverList.list(
                children: [
                  Text('Riwayat', style: t.pageTitle),
                  const SizedBox(height: AppSpace.block),
                  MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m)),
                  const SizedBox(height: AppSpace.x12),
                  TextField(
                    key: const Key('cari'),
                    controller: _search,
                    style: t.item,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari catatan atau kategori',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Hapus pencarian',
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (category != null) ...[
                          AppChip(
                            label: category.name,
                            icon: Icons.close,
                            selected: true,
                            onTap: () => setState(() => _categoryId = null),
                          ),
                          const SizedBox(width: AppSpace.x8),
                        ],
                        for (final (String label, TxKind? kind) in const [
                          ('Semua', null),
                          ('Pengeluaran', TxKind.pengeluaran),
                          ('Pemasukan', TxKind.pemasukan),
                          ('Transfer', TxKind.transfer),
                        ]) ...[
                          AppChip(label: label, selected: _kind == kind, onTap: () => setState(() => _kind = kind)),
                          const SizedBox(width: AppSpace.x8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.block),
                ],
              ),
            ),
            if (async.hasValue && items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: query.search.isNotEmpty || _kind != null || _categoryId != null
                      ? 'Tidak ada yang cocok'
                      : 'Belum ada transaksi di ${DateFmt.month(_month)}',
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
                    padding: const EdgeInsets.only(bottom: AppSpace.block),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.x8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(DateFmt.relativeDay(day, now: now), style: t.label.copyWith(color: c.sub)),
                              ),
                              if (net != 0)
                                Text(
                                  Rupiah.format(net, signed: true),
                                  style: t.label.copyWith(color: net > 0 ? c.good : c.muted),
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
