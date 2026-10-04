import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../security/app_gate.dart';
import 'data/transactions_dao.dart';
import 'widgets/tx_row.dart';

class TxDetailScreen extends ConsumerWidget {
  const TxDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref, TxDetail d) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('${txTitle(d)} · ${Rupiah.format(d.tx.amount)} akan dihapus dan saldo dompet disesuaikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(appDatabaseProvider).transactionsDao.remove(d.tx.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
    // Bisa dibuka lewat tautan langsung (tanpa halaman sebelumnya).
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final AsyncValue<TxDetail?> async = ref.watch(txDetailProvider(id));
    final TxDetail? d = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('Detail', style: t.screenTitle)),
      body: d == null
          ? Center(
              child: async.isLoading ? null : Text('Transaksi tidak ditemukan.', style: t.body.copyWith(color: c.sub)),
            )
          : ListView(
              padding: AppSpace.screen.copyWith(top: AppSpace.x8),
              children: [
                Center(
                  child: IconTile(
                    icon: d.tx.kind == TxKind.transfer ? Icons.swap_horiz : AppIcons.of(d.category?.icon ?? 'other'),
                    size: 64,
                    color: d.tx.kind == TxKind.pemasukan ? c.good : null,
                    background: d.tx.kind == TxKind.pemasukan ? c.goodSoft : null,
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                Center(child: Text(txTitle(d), style: t.section, textAlign: TextAlign.center)),
                const SizedBox(height: AppSpace.x8),
                Center(
                  child: Text(
                    d.tx.kind == TxKind.transfer
                        ? Rupiah.format(d.tx.amount)
                        : Rupiah.format(txSignedAmount(d.tx), signed: true),
                    style: t.amountXL.copyWith(color: d.tx.kind == TxKind.pemasukan ? c.good : c.ink),
                  ),
                ),
                const SizedBox(height: AppSpace.x24),
                AppCard(
                  child: Column(
                    children: [
                      _Field('Jenis', d.tx.kind == TxKind.transfer ? 'Pindah saldo' : d.tx.kind.label),
                      if (d.category != null) _Field('Kategori', d.category!.name),
                      if (d.tx.kind == TxKind.transfer) ...[
                        _Field('Dari', d.wallet.name),
                        _Field('Ke', d.toWallet?.name ?? '-'),
                      ] else
                        _Field('Dompet', d.wallet.name),
                      _Field('Tanggal', '${DateFmt.longDate(d.tx.occurredAt)} · ${DateFmt.time(d.tx.occurredAt)}'),
                      if (d.tx.note.isNotEmpty) _Field('Catatan', d.tx.note),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: d == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Hapus',
                        icon: Icons.delete_outline,
                        variant: AppButtonVariant.danger,
                        onPressed: () => _delete(context, ref, d),
                      ),
                    ),
                    const SizedBox(width: AppSpace.x8),
                    Expanded(
                      child: AppButton(
                        label: 'Ubah',
                        icon: Icons.edit_outlined,
                        onPressed: () => context.push(Uri(path: Routes.catat, queryParameters: {'id': '$id'}).toString()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: t.caption.copyWith(color: context.colors.muted))),
          Expanded(child: Text(value, style: t.item)),
        ],
      ),
    );
  }
}
