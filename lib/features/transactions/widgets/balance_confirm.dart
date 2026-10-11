import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/utils/rupiah_input.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/rupiah_prefix.dart';
import '../../settings/widgets/settings_tile.dart' show showAppSheet;
import '../../wallets/data/wallets_dao.dart';
import '../data/balance_guard.dart';

/// Saldo dompet asal akan jadi minus → tanya dulu (tidak memblokir, P0):
/// "Tetap catat" atau "Sesuaikan saldo" (isi saldo sebenarnya, lalu catat).
/// Mengembalikan true bila boleh lanjut menyimpan.
Future<bool> confirmWalletBalance(
  BuildContext context,
  WidgetRef ref, {
  required TxKind kind,
  required int walletId,
  int? toWalletId,
  required int amount,
  Txn? editing,
}) async {
  if (kind == TxKind.pemasukan) return true;
  final WalletsDao dao = ref.read(appDatabaseProvider).walletsDao;
  final WalletBalance? wb =
      (await dao.watchBalances(includeArchived: true).first)
          .where((b) => b.wallet.id == walletId)
          .firstOrNull;
  if (wb == null || !context.mounted) return true;
  final check = negativeBalanceCheck(
    current: wb.balance,
    walletId: wb.wallet.id,
    kind: kind,
    amount: amount,
    toWalletId: toWalletId,
    editing: editing,
  );
  if (!check.warn) return true;
  final String name = wb.wallet.name;
  final String? choice = await showAppSheet<String>(
    context,
    title: 'Saldo $name jadi minus',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Setelah dicatat, saldo $name menjadi ${Rupiah.format(check.after)}. '
          'Mungkin ada pemasukan yang belum dicatat, atau saldonya perlu disesuaikan.',
          style: context.text.body.copyWith(color: context.colors.sub),
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
            label: 'Tetap catat',
            large: true,
            onPressed: () => Navigator.pop(context, 'catat')),
        const SizedBox(height: AppSpace.x8),
        AppButton(
          label: 'Sesuaikan saldo',
          variant: AppButtonVariant.soft,
          onPressed: () => Navigator.pop(context, 'sesuaikan'),
        ),
      ],
    ),
  );
  if (choice == 'catat') return true;
  if (choice != 'sesuaikan' || !context.mounted) return false;
  final int? target = await showAppSheet<int>(
    context,
    title: 'Saldo $name sekarang',
    builder: (context) => BalanceForm(current: check.before),
  );
  if (target == null) return false;
  await dao.setBalance(wb.wallet.id, target + (wb.balance - check.before));
  return true;
}

/// Isi saldo sebenarnya (sebelum transaksi yang sedang dicatat).
class BalanceForm extends StatefulWidget {
  const BalanceForm({super.key, required this.current});

  final int current;

  @override
  State<BalanceForm> createState() => _BalanceFormState();
}

class _BalanceFormState extends State<BalanceForm> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.current > 0 ? Rupiah.digits(widget.current) : '',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Isi saldo yang sebenarnya ada sekarang, sebelum transaksi ini. Riwayat transaksi tidak berubah.',
          style: context.text.body.copyWith(color: context.colors.sub),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          key: const Key('saldo-sebenarnya'),
          controller: _amount,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: context.text.number,
          decoration: const InputDecoration(
            labelText: 'Saldo sekarang',
            prefixIcon: RupiahPrefix(),
            prefixIconConstraints: RupiahPrefix.constraints,
          ),
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Simpan & catat',
          large: true,
          onPressed: () =>
              Navigator.pop(context, RupiahInputFormatter.parse(_amount.text)),
        ),
      ],
    );
  }
}
