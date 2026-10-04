import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../data/transactions_dao.dart';

/// Judul baris: catatan, atau nama kategori bila catatan kosong.
String txTitle(TxDetail d) {
  if (d.tx.note.isNotEmpty) return d.tx.note;
  if (d.tx.kind == TxKind.transfer) return 'Pindah saldo';
  return d.category?.name ?? d.tx.kind.label;
}

/// Nominal bertanda: pengeluaran −, pemasukan +, transfer tanpa tanda.
int txSignedAmount(Txn tx) => switch (tx.kind) {
      TxKind.pengeluaran => -tx.amount,
      TxKind.pemasukan => tx.amount,
      TxKind.transfer => 0,
    };

/// Baris transaksi standar (beranda, riwayat).
class TxRow extends StatelessWidget {
  const TxRow({super.key, required this.detail, this.onTap, this.showDate = false});

  final TxDetail detail;
  final VoidCallback? onTap;

  /// Tampilkan tanggal (beranda) atau jam saja (riwayat per hari).
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Txn tx = detail.tx;
    final bool income = tx.kind == TxKind.pemasukan;
    final bool transfer = tx.kind == TxKind.transfer;

    final String when = showDate ? DateFmt.relativeDay(tx.occurredAt) : DateFmt.time(tx.occurredAt);
    final String meta = transfer
        ? '${detail.wallet.name} → ${detail.toWallet?.name ?? '?'}'
        : [
            if (tx.note.isNotEmpty && detail.category != null) detail.category!.name,
            detail.wallet.name,
          ].join(' · ');
    final String amount = transfer ? Rupiah.format(tx.amount) : Rupiah.format(txSignedAmount(tx), signed: true);

    return Pressable.card(
      onTap: onTap,
      semanticLabel: '${txTitle(detail)}, $amount, $meta, $when',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
        child: Row(
          children: [
            IconTile(
              icon: transfer ? Icons.swap_horiz : AppIcons.of(detail.category?.icon ?? 'other'),
              color: income ? c.good : (transfer ? c.sub : null),
              background: income ? c.goodSoft : (transfer ? c.chip : null),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txTitle(detail), style: t.item, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpace.x2),
                  Text(meta, style: t.caption.copyWith(color: c.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: t.number.copyWith(color: income ? c.good : (transfer ? c.sub : c.ink))),
                const SizedBox(height: AppSpace.x2),
                Text(when, style: t.caption.copyWith(color: c.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
