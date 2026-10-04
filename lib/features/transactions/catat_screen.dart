import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/segmented_control.dart';
import '../wallets/data/wallets_dao.dart';
import '../security/app_gate.dart';
import 'quick_entry_parser.dart';

/// Catat atau ubah transaksi. Kolom "Catat cepat" di atas membaca kalimat
/// bebas ("kopi 25rb gopay") dan mengisi form di bawahnya.
class CatatScreen extends ConsumerStatefulWidget {
  const CatatScreen({super.key, this.initialText, this.editId});

  final String? initialText;

  /// Ubah transaksi yang sudah ada.
  final int? editId;

  @override
  ConsumerState<CatatScreen> createState() => _CatatScreenState();
}

class _CatatScreenState extends ConsumerState<CatatScreen> {
  final TextEditingController _quick = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();

  TxKind _kind = TxKind.pengeluaran;
  int? _categoryId;
  int? _walletId;
  int? _toWalletId;
  late DateTime _date;
  Txn? _editing;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _date = ref.read(clockProvider)();
    _load();
  }

  Future<void> _load() async {
    final AppDatabase db = ref.read(appDatabaseProvider);
    final List<Wallet> wallets = await db.walletsDao.active();
    final List<Category> categories = await db.categoriesDao.active();
    Txn? editing;
    if (_isEdit) editing = await db.transactionsDao.byId(widget.editId!);
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      _categories = categories;
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      if (editing != null) {
        _editing = editing;
        _kind = editing.kind;
        _amount.text = Rupiah.digits(editing.amount);
        _categoryId = editing.categoryId;
        _walletId = editing.walletId;
        _toWalletId = editing.toWalletId;
        _date = editing.occurredAt;
        _note.text = editing.note;
      }
      _loaded = true;
    });
    final String text = widget.initialText?.trim() ?? '';
    if (text.isNotEmpty && editing == null) {
      _quick.text = text;
      _applyQuick(text);
    }
  }

  void _applyQuick(String text) {
    final QuickEntry e = QuickEntryParser(wallets: _wallets, categories: _categories)
        .parse(text, now: ref.read(clockProvider)());
    setState(() {
      _error = null;
      _kind = e.kind;
      if (e.amount != null) _amount.text = Rupiah.digits(e.amount!);
      _categoryId = e.categoryId;
      if (e.walletId != null) _walletId = e.walletId;
      _toWalletId = e.toWalletId;
      _date = e.occurredAt;
      _note.text = e.note;
    });
  }

  void _setKind(TxKind kind) => setState(() {
        if (kind == _kind) return;
        _kind = kind;
        _categoryId = null;
        _error = null;
        if (kind != TxKind.transfer) _toWalletId = null;
      });

  Future<void> _pickDate() async {
    final DateTime now = ref.read(clockProvider)();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Tanggal transaksi',
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
  }

  void _setDay(int daysAgo) {
    final DateTime now = ref.read(clockProvider)();
    setState(() => _date = DateTime(now.year, now.month, now.day - daysAgo, now.hour, now.minute));
  }

  Future<void> _save() async {
    final int amount = RupiahInputFormatter.parse(_amount.text);
    final bool transfer = _kind == TxKind.transfer;
    final String? problem = amount <= 0
        ? 'Isi nominalnya dulu.'
        : _walletId == null
            ? 'Pilih dompet.'
            : transfer && _toWalletId == null
                ? 'Pilih dompet tujuan.'
                : transfer && _toWalletId == _walletId
                    ? 'Dompet asal dan tujuan harus berbeda.'
                    : !transfer && _categoryId == null
                        ? 'Pilih kategori.'
                        : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() => _saving = true);
    final dao = ref.read(appDatabaseProvider).transactionsDao;
    if (_editing != null) {
      await dao.edit(_editing!.copyWith(
        kind: _kind,
        amount: amount,
        walletId: _walletId,
        toWalletId: Value(transfer ? _toWalletId : null),
        categoryId: Value(transfer ? null : _categoryId),
        note: _note.text,
        occurredAt: _date,
      ));
    } else {
      await dao.add(
        kind: _kind,
        amount: amount,
        walletId: _walletId!,
        toWalletId: transfer ? _toWalletId : null,
        categoryId: transfer ? null : _categoryId,
        note: _note.text,
        occurredAt: _date,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editing != null ? 'Perubahan disimpan' : 'Tersimpan · ${Rupiah.format(amount)}')),
    );
    // Bisa dibuka lewat tautan langsung (tanpa halaman sebelumnya).
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  @override
  void dispose() {
    _quick.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    // Saldo terkini untuk keterangan di chip dompet.
    final Map<int, int> balances = {
      for (final WalletBalance w in ref.watch(walletBalancesProvider).valueOrNull ?? const []) w.wallet.id: w.balance,
    };

    if (!_loaded) return const Scaffold(body: SizedBox.shrink());

    final List<Category> cats = [for (final cat in _categories) if (cat.kind == _kind) cat];
    final bool transfer = _kind == TxKind.transfer;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int daysAgo = today.difference(DateTime(_date.year, _date.month, _date.day)).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah transaksi' : 'Catat', style: t.screenTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Tutup',
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: _wallets.isEmpty
          ? Center(child: Text('Belum ada dompet aktif.', style: t.body.copyWith(color: c.sub)))
          : ListView(
              padding: AppSpace.screen.copyWith(top: AppSpace.x8),
              children: [
                if (!_isEdit) ...[
                  TextField(
                    key: const Key('catat-cepat'),
                    controller: _quick,
                    autofocus: widget.initialText == null,
                    style: t.item,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Catat cepat: kopi 25rb gopay',
                      prefixIcon: Icon(Icons.bolt_outlined),
                    ),
                    onChanged: _applyQuick,
                  ),
                  const SizedBox(height: AppSpace.block),
                ],
                AppSegmentedControl<TxKind>(
                  options: TxKind.values,
                  selected: _kind,
                  labelOf: (k) => k == TxKind.transfer ? 'Pindah Saldo' : k.label,
                  onChanged: _setKind,
                ),
                const SizedBox(height: AppSpace.x24),
                Center(child: Text('Nominal', style: t.label.copyWith(color: c.muted))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Rp', style: t.amountXL.copyWith(color: c.muted)),
                    const SizedBox(width: AppSpace.x4),
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          key: const Key('nominal'),
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [RupiahInputFormatter()],
                          style: t.amountXL.copyWith(color: _kind == TxKind.pemasukan ? c.good : c.ink),
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: AppSpace.x8),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x16),
                if (!transfer) ...[
                  const _Label('Kategori'),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final cat in cats)
                        AppChip(
                          label: cat.name,
                          icon: AppIcons.of(cat.icon),
                          selected: cat.id == _categoryId,
                          onTap: () => setState(() {
                            _categoryId = cat.id;
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x24),
                ],
                _Label(transfer ? 'Dari dompet' : 'Dompet'),
                _WalletChips(
                  wallets: _wallets,
                  balances: balances,
                  selected: _walletId,
                  onSelected: (id) => setState(() {
                    _walletId = id;
                    _error = null;
                  }),
                ),
                if (transfer) ...[
                  const SizedBox(height: AppSpace.x24),
                  const _Label('Ke dompet'),
                  _WalletChips(
                    wallets: [for (final w in _wallets) if (w.id != _walletId) w],
                    balances: balances,
                    selected: _toWalletId,
                    onSelected: (id) => setState(() {
                      _toWalletId = id;
                      _error = null;
                    }),
                  ),
                ],
                const SizedBox(height: AppSpace.x24),
                const _Label('Tanggal'),
                Wrap(
                  spacing: AppSpace.x8,
                  runSpacing: AppSpace.x8,
                  children: [
                    AppChip(label: 'Hari ini', selected: daysAgo == 0, onTap: () => _setDay(0)),
                    AppChip(label: 'Kemarin', selected: daysAgo == 1, onTap: () => _setDay(1)),
                    AppChip(
                      label: daysAgo > 1 ? DateFmt.date(_date, now: now) : 'Pilih tanggal',
                      icon: Icons.calendar_today_outlined,
                      selected: daysAgo > 1,
                      onTap: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x24),
                const _Label('Catatan'),
                TextField(
                  key: const Key('catatan'),
                  controller: _note,
                  style: t.item,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Opsional', counterText: ''),
                ),
                const SizedBox(height: AppSpace.x24),
              ],
            ),
      bottomNavigationBar: _wallets.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: t.caption.copyWith(color: c.danger)),
                      const SizedBox(height: AppSpace.x8),
                    ],
                    AppButton(
                      label: _isEdit ? 'Simpan perubahan' : 'Simpan transaksi',
                      large: true,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.x8),
        child: Text(text, style: context.text.label.copyWith(color: context.colors.muted)),
      );
}

class _WalletChips extends StatelessWidget {
  const _WalletChips({required this.wallets, required this.balances, required this.selected, required this.onSelected});

  final List<Wallet> wallets;
  final Map<int, int> balances;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpace.x8,
        runSpacing: AppSpace.x8,
        children: [
          for (final w in wallets)
            AppChip(
              label: balances[w.id] == null ? w.name : '${w.name} · ${Rupiah.compact(balances[w.id]!)}',
              icon: AppIcons.of(w.icon),
              selected: w.id == selected,
              onTap: () => onSelected(w.id),
            ),
        ],
      );
}
