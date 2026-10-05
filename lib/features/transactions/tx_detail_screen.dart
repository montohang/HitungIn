import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../budget/data/budgets_dao.dart';
import '../security/app_gate.dart';
import 'data/transactions_dao.dart';
import 'widgets/tx_row.dart';
import '../../core/widgets/hi_icons.dart';

/// Asal transaksi untuk chip di bawah nominal (desain: "Pengeluaran · dicatat manual").
String txOrigin(Txn tx) => tx.billId != null
    ? 'dari tagihan'
    : tx.recurringId != null
        ? 'dicatat otomatis'
        : 'dicatat manual';

/// Budget yang terdampak transaksi pengeluaran: budget kategorinya, atau
/// budget total bila kategori tak punya budget. Null bila tidak ada.
BudgetProgress? impactedBudget(Txn tx, List<BudgetProgress> budgets) {
  if (tx.kind != TxKind.pengeluaran) return null;
  return budgets.where((b) => b.category != null && b.category!.id == tx.categoryId).firstOrNull ??
      budgets.where((b) => b.category == null).firstOrNull;
}

/// Detail transaksi (Claude Design › Detail Transaksi).
class TxDetailScreen extends ConsumerWidget {
  const TxDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref, TxDetail d) async {
    final c = context.colors;
    final t = context.text;
    final String body = switch (d.tx.kind) {
      TxKind.pengeluaran =>
        'Saldo ${d.wallet.name} akan dikembalikan ${Rupiah.format(d.tx.amount)} dan laporan bulan ini ikut diperbarui.',
      TxKind.pemasukan =>
        'Saldo ${d.wallet.name} akan berkurang ${Rupiah.format(d.tx.amount)} dan laporan bulan ini ikut diperbarui.',
      TxKind.transfer =>
        '${Rupiah.format(d.tx.amount)} kembali ke ${d.wallet.name} dari ${d.toWallet?.name ?? 'dompet tujuan'}.',
    };
    final bool? ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hapus transaksi ini?', style: t.screenTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpace.x16),
              Text(body, style: t.body.copyWith(height: 1.55, color: c.sub)),
              const SizedBox(height: AppSpace.x16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: AppButton(
                      key: const Key('konfirmasi-hapus'),
                      label: 'Hapus',
                      variant: AppButtonVariant.dangerSolid,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final TransactionsDao dao = ref.read(appDatabaseProvider).transactionsDao;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Txn removed = d.tx;
    await dao.remove(removed.id);
    messenger.showSnackBar(SnackBar(
      content: const Text('Transaksi dihapus'),
      action: SnackBarAction(label: 'Urungkan', onPressed: () => dao.restore(removed)),
    ));
    if (!context.mounted) return;
    // Bisa dibuka lewat tautan langsung (tanpa halaman sebelumnya).
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final AsyncValue<TxDetail?> async = ref.watch(txDetailProvider(id));
    final TxDetail? d = async.valueOrNull;
    final DateTime now = ref.watch(clockProvider)();
    final DateTime? month = d == null ? null : DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month);
    final List<BudgetProgress> budgets =
        month == null ? const [] : ref.watch(budgetProgressProvider(month)).valueOrNull ?? const [];
    final BudgetProgress? impact = d == null ? null : impactedBudget(d.tx, budgets);
    final bool income = d?.tx.kind == TxKind.pemasukan;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            children: [
              ScreenHeader(
                title: 'Detail transaksi',
                trailing: d == null
                    ? null
                    : Pressable(
                        onTap: () => context.push(Uri(path: Routes.catat, queryParameters: {'id': '$id'}).toString()),
                        semanticLabel: 'Edit transaksi',
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                          child: Text('Edit', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpace.x16),
              Expanded(
                child: d == null
                    ? Center(
                        child: async.isLoading
                            ? null
                            : Text('Transaksi tidak ditemukan.', style: t.body.copyWith(color: c.sub)),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: AppSpace.x8),
                          Center(
                            child: IconTile(
                              icon: d.tx.kind == TxKind.transfer
                                  ? HiIcons.swap
                                  : AppIcons.of(d.category?.icon ?? 'other'),
                              size: 56,
                              color: income
                                  ? c.good
                                  : d.tx.kind == TxKind.transfer
                                      ? c.sub
                                      : AppPalette.ink(context, d.category?.color ?? 0),
                              background: income
                                  ? c.goodSoft
                                  : d.tx.kind == TxKind.transfer
                                      ? c.chip
                                      : AppPalette.soft(context, d.category?.color ?? 0),
                            ),
                          ),
                          const SizedBox(height: AppSpace.x8),
                          Text(
                            txTitle(d),
                            textAlign: TextAlign.center,
                            style: t.item.copyWith(fontWeight: FontWeight.w600, color: c.sub2),
                          ),
                          const SizedBox(height: AppSpace.x8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              d.tx.kind == TxKind.transfer
                                  ? Rupiah.format(d.tx.amount)
                                  : Rupiah.format(txSignedAmount(d.tx), signed: true),
                              style: t.amountXL.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: income ? c.good : c.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.x8),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x4),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: AppRadius.pillAll,
                                border: Border.all(color: c.line),
                              ),
                              child: Text(
                                '${d.tx.kind == TxKind.transfer ? 'Pindah saldo' : d.tx.kind.label} · ${txOrigin(d.tx)}',
                                style: t.label.copyWith(color: c.sub),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.x24),
                          _Rows(rows: [
                            if (d.category != null) ('Kategori', d.tx.sub.isEmpty ? d.category!.name : '${d.category!.name} › ${d.tx.sub}'),
                            if (d.tx.kind == TxKind.transfer) ...[
                              ('Dari', d.wallet.name),
                              ('Ke', d.toWallet?.name ?? '-'),
                            ] else
                              ('Dompet', d.wallet.name),
                            (
                              'Waktu',
                              '${DateFmt.weekdays[d.tx.occurredAt.weekday - 1]}, '
                                  '${d.tx.occurredAt.day} ${DateFmt.monthsShort[d.tx.occurredAt.month - 1]} '
                                  '${d.tx.occurredAt.year} · ${DateFmt.time(d.tx.occurredAt)}',
                            ),
                            // Catatan sudah tampil sebagai judul bila judulnya diambil dari catatan.
                            if (d.tx.note.isNotEmpty && d.tx.note != txTitle(d)) ('Catatan', d.tx.note),
                          ]),
                          if (impact != null) ...[
                            const SizedBox(height: AppSpace.x16),
                            _BudgetImpact(budget: impact, amount: d.tx.amount, sameMonth: month == DateTime(now.year, now.month)),
                          ],
                        ],
                      ),
              ),
              if (d != null) ...[
                const SizedBox(height: AppSpace.x16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Duplikat',
                        variant: AppButtonVariant.outline,
                        onPressed: () =>
                            context.push(Uri(path: Routes.catat, queryParameters: {'copy': '$id'}).toString()),
                      ),
                    ),
                    const SizedBox(width: AppSpace.x8),
                    Expanded(
                      child: AppButton(
                        label: 'Hapus',
                        variant: AppButtonVariant.danger,
                        onPressed: () => _delete(context, ref, d),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          for (final (int i, (String k, String v)) in rows.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
              decoration: BoxDecoration(
                border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k, style: t.caption.copyWith(fontSize: 14, color: c.muted)),
                  const SizedBox(width: AppSpace.x16),
                  Expanded(
                    child: Text(
                      v,
                      textAlign: TextAlign.right,
                      style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Budget Makan & Minum 82% · Transaksi ini memakai 1,8% dari budget…".
class _BudgetImpact extends StatelessWidget {
  const _BudgetImpact({required this.budget, required this.amount, required this.sameMonth});

  final BudgetProgress budget;
  final int amount;
  final bool sameMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int limit = budget.budget.limitAmount;
    final double ratio = limit == 0 ? 0 : budget.spent / limit;
    final double share = limit == 0 ? 0 : amount / limit * 100;
    final String shareText = share >= 10 ? share.round().toString() : share.toStringAsFixed(1).replaceAll('.', ',');
    final String name = budget.category == null ? 'Budget total' : 'Budget ${budget.category!.name}';
    final Color pctColor = ratio > 1
        ? c.danger
        : ratio >= 0.8
            ? c.warnInk
            : c.ink;
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.ink))),
              Text('${(ratio * 100).round()}%', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: pctColor)),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          AppProgressBar(value: ratio, height: 8),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Transaksi ini memakai $shareText% dari ${budget.category == null ? 'budget total' : 'budget kategori'} '
            '${sameMonth ? 'bulan ini' : 'bulan itu'}.',
            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
          ),
        ],
      ),
    );
  }
}
