import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../settings/widgets/settings_tile.dart';
import '../wallets/data/wallets_dao.dart';
import '../../core/widgets/hi_icons.dart';

final _recurringProvider = StreamProvider.autoDispose<List<RecurringTx>>(
  (ref) => ref.watch(appDatabaseProvider).recurringDao.watchAll(),
);

/// Pilihan ulang untuk transaksi berulang (tanpa "Sekali").
const List<BillRepeat> recurringRepeats = [BillRepeat.mingguan, BillRepeat.bulanan, BillRepeat.tahunan];

/// Transaksi berulang (Pro): gaji, langganan, iuran — dicatat otomatis.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  void _add(BuildContext context, WidgetRef ref) {
    if (!ref.read(isProProvider)) {
      openPremium(context, ProReason.berulang);
      return;
    }
    _openForm(context, null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final AsyncValue<List<RecurringTx>> async = ref.watch(_recurringProvider);
    final List<RecurringTx> items = async.valueOrNull ?? const [];
    final List<Category> cats = ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
    final Map<int, String> walletNames = {
      for (final WalletBalance w in ref.watch(walletBalancesProvider).valueOrNull ?? const <WalletBalance>[])
        w.wallet.id: w.wallet.name,
    };
    final DateTime now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text('Transaksi berulang', style: t.screenTitle)),
      floatingActionButton: AppFab(label: 'Tambah jadwal', onPressed: () => _add(context, ref)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8, bottom: 96),
        children: [
          Text(
            'Dicatat otomatis setiap jatuh tempo (jam 08.00), juga susulan bila aplikasi lama tidak dibuka. '
            'Untuk yang perlu dibayar manual, pakai Tagihan.',
            style: t.caption.copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpace.x12),
          if (async.hasValue && items.isEmpty)
            AppCard(
              child: EmptyState(
                icon: HiIcons.repeat,
                title: 'Belum ada jadwal',
                body: 'Contoh: gaji tiap tanggal 25, langganan Spotify tiap bulan, uang kos tiap tanggal 1.',
                action: 'Tambah jadwal',
                onAction: () => _add(context, ref),
              ),
            ),
          for (final r in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.x8),
              child: Opacity(
                opacity: r.active ? 1 : 0.6,
                child: AppCard(
                  onTap: () => _openForm(context, r),
                  child: Row(
                    children: [
                      IconTile(
                        icon: r.kind == TxKind.transfer
                            ? HiIcons.swap
                            : AppIcons.of(cats.where((c) => c.id == r.categoryId).firstOrNull?.icon ?? 'other'),
                        color: r.kind == TxKind.pemasukan ? c.good : null,
                        background: r.kind == TxKind.pemasukan ? c.goodSoft : null,
                      ),
                      const SizedBox(width: AppSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.note.isNotEmpty
                                  ? r.note
                                  : cats.where((c) => c.id == r.categoryId).firstOrNull?.name ?? r.kind.label,
                              style: t.item,
                            ),
                            Text(
                              r.active ? '${r.repeat.label} · ${DateFmt.date(r.nextRun, now: now)}' : 'Dijeda',
                              style: t.caption.copyWith(color: c.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            r.kind == TxKind.transfer
                                ? Rupiah.format(r.amount)
                                : Rupiah.format(r.kind == TxKind.pengeluaran ? -r.amount : r.amount, signed: true),
                            style: t.number.copyWith(color: r.kind == TxKind.pemasukan ? c.good : null),
                          ),
                          Text(
                            r.kind == TxKind.transfer
                                ? '${walletNames[r.walletId] ?? '?'} → ${walletNames[r.toWalletId] ?? '?'}'
                                : walletNames[r.walletId] ?? '?',
                            style: t.caption.copyWith(color: c.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _openForm(BuildContext context, RecurringTx? existing) => showAppSheet<void>(
        context,
        title: existing == null ? 'Jadwal baru' : 'Ubah jadwal',
        builder: (_) => _RecurringForm(existing: existing),
      );
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.existing});

  final RecurringTx? existing;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  late final RecurringTx? _r = widget.existing;
  late TxKind _kind = _r?.kind ?? TxKind.pengeluaran;
  late final TextEditingController _amount = TextEditingController(text: _r == null ? '' : Rupiah.digits(_r.amount));
  late final TextEditingController _note = TextEditingController(text: _r?.note ?? '');
  late int? _categoryId = _r?.categoryId;
  late int? _walletId = _r?.walletId;
  late int? _toWalletId = _r?.toWalletId;
  late BillRepeat _repeat = _r?.repeat ?? BillRepeat.bulanan;
  late DateTime _next = _r?.nextRun ?? ref.read(clockProvider)();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _next,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: _r == null ? 'Mulai tanggal' : 'Berikutnya tanggal',
    );
    if (d != null) setState(() => _next = d);
  }

  Future<void> _save() async {
    final int amount = RupiahInputFormatter.parse(_amount.text);
    final bool transfer = _kind == TxKind.transfer;
    final String? problem = amount <= 0
        ? 'Isi nominalnya.'
        : _walletId == null
            ? 'Pilih dompet.'
            : transfer && (_toWalletId == null || _toWalletId == _walletId)
                ? 'Pilih dompet tujuan yang berbeda.'
                : !transfer && _categoryId == null
                    ? 'Pilih kategori.'
                    : null;
    if (problem != null) return setState(() => _error = problem);

    final dao = ref.read(appDatabaseProvider).recurringDao;
    if (_r == null) {
      await dao.add(
        kind: _kind,
        amount: amount,
        walletId: _walletId!,
        toWalletId: transfer ? _toWalletId : null,
        categoryId: transfer ? null : _categoryId,
        note: _note.text,
        repeat: _repeat,
        firstRun: _next,
      );
    } else {
      await dao.edit(_r.copyWith(
        kind: _kind,
        amount: amount,
        walletId: _walletId,
        toWalletId: Value(transfer ? _toWalletId : null),
        categoryId: Value(transfer ? null : _categoryId),
        note: _note.text,
        repeat: _repeat,
        nextRun: _next,
        anchorDay: _next.day,
      ));
    }
    // Bila mulai hari ini/terlewat, langsung catat.
    await dao.runDue(ref.read(clockProvider)());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus jadwal?',
      body: 'Transaksi yang sudah tercatat dari jadwal ini tetap ada.',
      confirm: 'Hapus',
      danger: true,
    );
    if (!ok) return;
    await ref.read(appDatabaseProvider).recurringDao.remove(_r!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool transfer = _kind == TxKind.transfer;
    final List<Category> cats = [
      for (final cat in ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        if (cat.kind == _kind) cat,
    ];
    final wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];

    Widget walletChips(int? selected, ValueChanged<int> onTap, {int? exclude}) => Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final w in wallets)
              if (w.wallet.id != exclude)
                AppChip(
                  label: w.wallet.name,
                  icon: AppIcons.of(w.wallet.icon),
                  selected: w.wallet.id == selected,
                  onTap: () => onTap(w.wallet.id),
                ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSegmentedControl<TxKind>(
          options: TxKind.values,
          selected: _kind,
          labelOf: (k) => k == TxKind.transfer ? 'Pindah Saldo' : k.label,
          onChanged: (k) => setState(() {
            _kind = k;
            _categoryId = null;
          }),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: const InputDecoration(
              labelText: 'Nominal', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _note,
          maxLength: 80,
          style: t.item,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Catatan', hintText: 'Gaji, Spotify, uang kos', counterText: ''),
        ),
        if (!transfer) ...[
          const FieldLabel('Kategori'),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final cat in cats)
                AppChip(
                  label: cat.name,
                  icon: AppIcons.of(cat.icon),
                  selected: cat.id == _categoryId,
                  onTap: () => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
        ],
        FieldLabel(transfer ? 'Dari dompet' : 'Dompet'),
        walletChips(_walletId, (id) => setState(() => _walletId = id)),
        if (transfer) ...[
          const FieldLabel('Ke dompet'),
          walletChips(_toWalletId, (id) => setState(() => _toWalletId = id), exclude: _walletId),
        ],
        const FieldLabel('Ulangi'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final r in recurringRepeats)
              AppChip(label: r.label, selected: r == _repeat, onTap: () => setState(() => _repeat = r)),
          ],
        ),
        FieldLabel(_r == null ? 'Mulai' : 'Berikutnya'),
        AppChip(label: DateFmt.longDate(_next), icon: HiIcons.calendar, selected: true, onTap: _pickDate),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
        if (_r != null) ...[
          const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _r.active ? 'Jeda' : 'Lanjutkan',
                  variant: AppButtonVariant.outline,
                  onPressed: () async {
                    await ref.read(appDatabaseProvider).recurringDao.setActive(_r.id, !_r.active);
                    if (context.mounted) Navigator.pop(context);
                  },
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
