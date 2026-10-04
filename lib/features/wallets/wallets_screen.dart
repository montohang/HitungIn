import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/wallets_dao.dart';

final _allWalletsProvider = StreamProvider.autoDispose<List<WalletBalance>>(
  (ref) => ref.watch(appDatabaseProvider).walletsDao.watchBalances(includeArchived: true),
);

String walletIconFor(WalletType type) => switch (type) {
      WalletType.tunai => 'cash',
      WalletType.bank => 'bank',
      WalletType.ewallet => 'ewallet',
      WalletType.lainnya => 'wallet',
    };

/// Kelola dompet: tambah, ubah, urutkan (tahan & geser), arsipkan, hapus.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final List<WalletBalance> all = ref.watch(_allWalletsProvider).valueOrNull ?? const [];
    final List<WalletBalance> active = [for (final w in all) if (!w.wallet.archived) w];
    final List<WalletBalance> archived = [for (final w in all) if (w.wallet.archived) w];

    return Scaffold(
      appBar: AppBar(title: Text('Dompet', style: t.screenTitle)),
      floatingActionButton: AppFab(label: 'Tambah dompet', onPressed: () => _openForm(context, ref, null)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8, bottom: 96),
        children: [
          Text('Tahan lalu geser untuk mengubah urutan.', style: t.caption.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.x8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (from, to) {
              final List<int> ids = [for (final w in active) w.wallet.id];
              final int id = ids.removeAt(from);
              ids.insert(to > from ? to - 1 : to, id);
              ref.read(appDatabaseProvider).walletsDao.reorder(ids);
            },
            children: [
              for (final (int i, WalletBalance w) in active.indexed)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(w.wallet.id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.x8),
                    child: _WalletCard(item: w, onTap: () => _openForm(context, ref, w)),
                  ),
                ),
            ],
          ),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x16),
            Text('Diarsipkan', style: t.label.copyWith(color: c.muted)),
            const SizedBox(height: AppSpace.x8),
            for (final w in archived)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x8),
                child: Opacity(opacity: 0.6, child: _WalletCard(item: w, onTap: () => _openForm(context, ref, w))),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, WalletBalance? existing) =>
      showAppSheet<void>(context, title: existing == null ? 'Dompet baru' : 'Ubah dompet', builder: (_) => _WalletForm(existing: existing));
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.item, required this.onTap});

  final WalletBalance item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconTile(icon: AppIcons.of(item.wallet.icon)),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.wallet.name, style: t.item),
                Text(item.wallet.type.label, style: t.caption.copyWith(color: context.colors.muted)),
              ],
            ),
          ),
          Text(Rupiah.format(item.balance), style: t.number.copyWith(color: item.balance < 0 ? context.colors.danger : null)),
        ],
      ),
    );
  }
}

class _WalletForm extends ConsumerStatefulWidget {
  const _WalletForm({this.existing});

  final WalletBalance? existing;

  @override
  ConsumerState<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends ConsumerState<_WalletForm> {
  late final Wallet? _w = widget.existing?.wallet;
  late final TextEditingController _name = TextEditingController(text: _w?.name ?? '');
  late final TextEditingController _initial =
      TextEditingController(text: _w == null || _w.initialBalance == 0 ? '' : Rupiah.digits(_w.initialBalance));
  late WalletType _type = _w?.type ?? WalletType.bank;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Isi nama dompet.');
    final dao = ref.read(appDatabaseProvider).walletsDao;
    final bool taken = (await dao.watchBalances(includeArchived: true).first)
        .any((w) => w.wallet.id != _w?.id && w.wallet.name.toLowerCase() == name.toLowerCase());
    if (taken) return setState(() => _error = 'Nama dompet sudah dipakai.');
    final int initial = RupiahInputFormatter.parse(_initial.text);
    if (_w == null) {
      await dao.add(name: name, type: _type, initialBalance: initial, icon: walletIconFor(_type));
    } else {
      await dao.edit(_w.copyWith(name: name, type: _type, initialBalance: initial, icon: walletIconFor(_type)));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive(bool archived) async {
    final dao = ref.read(appDatabaseProvider).walletsDao;
    if (archived && (await dao.active()).length <= 1) {
      return setState(() => _error = 'Minimal harus ada satu dompet aktif.');
    }
    await dao.setArchived(_w!.id, archived);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final dao = ref.read(appDatabaseProvider).walletsDao;
    if (!_w!.archived && (await dao.active()).length <= 1) {
      return setState(() => _error = 'Minimal harus ada satu dompet aktif.');
    }
    if (!mounted) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus ${_w.name}?',
      body: 'Dompet yang belum punya transaksi akan dihapus permanen.',
      confirm: 'Hapus',
      danger: true,
    );
    if (!ok) return;
    final bool deleted = await dao.deleteIfUnused(_w.id);
    if (!mounted) return;
    if (!deleted) {
      return setState(() => _error = 'Dompet ini sudah punya transaksi. Arsipkan saja supaya riwayat tetap utuh.');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          autofocus: _w == null,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama dompet', counterText: ''),
        ),
        const FieldLabel('Jenis'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final type in WalletType.values)
              AppChip(
                label: type.label,
                icon: AppIcons.of(walletIconFor(type)),
                selected: type == _type,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        TextField(
          controller: _initial,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: InputDecoration(
            labelText: 'Saldo awal',
            helperText: _w == null ? 'Saldo saat ini, sebelum transaksi pertama dicatat.' : 'Saldo sebelum transaksi pertama. Saldo sekarang ikut berubah.',
            prefixText: 'Rp',
            prefixStyle: t.number.copyWith(color: c.muted),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
        if (_w != null) ...[
          const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _w.archived ? 'Aktifkan lagi' : 'Arsipkan',
                  variant: AppButtonVariant.outline,
                  onPressed: () => _archive(!_w.archived),
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(child: AppButton(label: 'Hapus', variant: AppButtonVariant.danger, onPressed: _delete)),
            ],
          ),
        ],
      ],
    );
  }
}
