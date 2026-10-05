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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/segmented_control.dart';
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'widgets/amount_keypad.dart';
import '../wallets/data/wallets_dao.dart';
import '../security/app_gate.dart';
import 'quick_entry_parser.dart';

/// Catat atau ubah transaksi. Kolom "Catat cepat" di atas membaca kalimat
/// bebas ("kopi 25rb gopay") dan mengisi form di bawahnya.
class CatatScreen extends ConsumerStatefulWidget {
  const CatatScreen({super.key, this.initialText, this.editId, this.copyId});

  final String? initialText;

  /// Ubah transaksi yang sudah ada.
  final int? editId;

  /// Duplikat: isi form dari transaksi ini, disimpan sebagai transaksi baru hari ini.
  final int? copyId;

  @override
  ConsumerState<CatatScreen> createState() => _CatatScreenState();
}

class _CatatScreenState extends ConsumerState<CatatScreen> {
  final TextEditingController _quick = TextEditingController();
  final TextEditingController _note = TextEditingController();

  TxKind _kind = TxKind.pengeluaran;
  int _amount = 0;
  int? _categoryId;

  /// Kategori dari Catat cepat / transaksi yang diubah tampil paling depan.
  int? _pinnedCategory;
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
    final Txn? copy = widget.copyId == null ? null : await db.transactionsDao.byId(widget.copyId!);
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      _categories = categories;
      _walletId = wallets.isEmpty ? null : wallets.first.id;
      if (editing != null) {
        _editing = editing;
        _kind = editing.kind;
        _amount = editing.amount;
        _categoryId = editing.categoryId;
        _pinnedCategory = editing.categoryId;
        _walletId = editing.walletId;
        _toWalletId = editing.toWalletId;
        _date = editing.occurredAt;
        _note.text = editing.note;
      }
      if (copy != null) {
        _kind = copy.kind;
        _amount = copy.amount;
        _categoryId = copy.categoryId;
        _pinnedCategory = copy.categoryId;
        _walletId = copy.walletId;
        _toWalletId = copy.toWalletId;
        _note.text = copy.note;
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
      if (e.amount != null) _amount = e.amount!;
      _categoryId = e.categoryId;
      _pinnedCategory = e.categoryId;
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

  void _onKey(String key) => setState(() {
        _amount = applyKeypad(_amount, key);
        _error = null;
      });

  Future<void> _pickWallet({required bool to}) async {
    final Map<int, int> balances = {
      for (final WalletBalance w in ref.read(walletBalancesProvider).valueOrNull ?? const []) w.wallet.id: w.balance,
    };
    final List<Wallet> options = to ? [for (final w in _wallets) if (w.id != _walletId) w] : _wallets;
    final int? picked = await showAppSheet<int>(
      context,
      title: to ? 'Ke dompet' : (_kind == TxKind.transfer ? 'Dari dompet' : 'Pilih dompet'),
      builder: (context) => Column(
        children: [
          for (final Wallet w in options)
            _SheetOption(
              icon: AppIcons.of(w.icon),
              label: w.name,
              value: balances[w.id] == null ? null : Rupiah.format(balances[w.id]!),
              selected: w.id == (to ? _toWalletId : _walletId),
              onTap: () => Navigator.pop(context, w.id),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _error = null;
      if (to) {
        _toWalletId = picked;
      } else {
        _walletId = picked;
        if (_toWalletId == picked) _toWalletId = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = ref.read(clockProvider)();
    DateTime at(int daysAgo) => DateTime(now.year, now.month, now.day - daysAgo, _date.hour, _date.minute);
    final int daysAgo =
        DateTime(now.year, now.month, now.day).difference(DateTime(_date.year, _date.month, _date.day)).inDays;
    final Object? picked = await showAppSheet<Object>(
      context,
      title: 'Tanggal transaksi',
      builder: (context) => Column(
        children: [
          _SheetOption(
            icon: Icons.today_outlined,
            label: 'Hari ini',
            value: DateFmt.date(now, now: now),
            selected: daysAgo == 0,
            onTap: () => Navigator.pop(context, at(0)),
          ),
          _SheetOption(
            icon: Icons.history,
            label: 'Kemarin',
            value: DateFmt.date(at(1), now: now),
            selected: daysAgo == 1,
            onTap: () => Navigator.pop(context, at(1)),
          ),
          _SheetOption(
            icon: Icons.calendar_month_outlined,
            label: 'Pilih tanggal lain',
            value: daysAgo > 1 ? DateFmt.date(_date, now: now) : null,
            selected: daysAgo > 1,
            onTap: () => Navigator.pop(context, 'kalender'),
          ),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    if (picked is DateTime) {
      setState(() => _date = picked);
      return;
    }
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Tanggal transaksi',
    );
    if (day == null) return;
    setState(() => _date = DateTime(day.year, day.month, day.day, _date.hour, _date.minute));
  }

  Future<void> _save() async {
    final int amount = _amount;
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
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();

    if (!_loaded) return const Scaffold(body: SizedBox.shrink());

    final List<Category> cats = [
      for (final cat in _categories)
        if (cat.kind == _kind && cat.id == _pinnedCategory) cat,
      for (final cat in _categories)
        if (cat.kind == _kind && cat.id != _pinnedCategory) cat,
    ];
    final bool transfer = _kind == TxKind.transfer;
    final bool keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    String walletName(int? id) => _wallets.where((w) => w.id == id).firstOrNull?.name ?? 'Pilih';
    void close() => context.canPop() ? context.pop() : context.go(Routes.home);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            children: [
              // ✕ · judul · ruang kosong (desain).
              Row(
                children: [
                  Pressable(
                    onTap: close,
                    semanticLabel: 'Tutup',
                    child: Container(
                      width: AppSpace.touch,
                      height: AppSpace.touch,
                      decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.smAll),
                      child: Icon(Icons.close, size: 20, color: c.ink),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Ubah transaksi' : 'Catat transaksi',
                      textAlign: TextAlign.center,
                      style: t.title.copyWith(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: AppSpace.touch),
                ],
              ),
              const SizedBox(height: AppSpace.x16),
              Expanded(
                child: _wallets.isEmpty
                    ? Center(child: Text('Belum ada dompet aktif.', style: t.body.copyWith(color: c.sub)))
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (!_isEdit) ...[
                            _QuickField(
                              controller: _quick,
                              autofocus: false,
                              onChanged: _applyQuick,
                            ),
                            const SizedBox(height: AppSpace.x16),
                          ],
                          AppSegmentedControl<TxKind>(
                            options: TxKind.values,
                            selected: _kind,
                            onSurface: true,
                            labelOf: (k) => k == TxKind.transfer ? 'Pindah Saldo' : k.label,
                            onChanged: _setKind,
                          ),
                          const SizedBox(height: AppSpace.x16),
                          Center(child: Text('Nominal', style: t.caption.copyWith(color: c.muted))),
                          const SizedBox(height: AppSpace.x8),
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Rupiah.format(_amount),
                                key: const Key('nominal'),
                                style: t.amountXL.copyWith(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: _amount == 0
                                      ? c.muted
                                      : _kind == TxKind.pemasukan
                                          ? c.good
                                          : c.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.x16),
                          if (transfer) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _PickTile(
                                    label: 'Dari',
                                    value: walletName(_walletId),
                                    onTap: () => _pickWallet(to: false),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.x8),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                                  child: Icon(Icons.arrow_forward, size: 18, color: c.accentText),
                                ),
                                const SizedBox(width: AppSpace.x8),
                                Expanded(
                                  child: _PickTile(
                                    label: 'Ke',
                                    value: _toWalletId == null ? 'Pilih' : walletName(_toWalletId),
                                    onTap: () => _pickWallet(to: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.x12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
                              decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: c.sub),
                                  const SizedBox(width: AppSpace.x12),
                                  Expanded(
                                    child: Text(
                                      'Hanya memindahkan saldo antar dompetmu, mis. top up GoPay dari BCA. '
                                      'Tidak dihitung sebagai pengeluaran.',
                                      style: t.caption.copyWith(height: 1.5, color: c.sub),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.x8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Pressable(
                                onTap: _pickDate,
                                semanticLabel: 'Tanggal: ${DateFmt.dayLabel(_date, now: now)}',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4, vertical: AppSpace.x8),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Tanggal: ',
                                      children: [
                                        TextSpan(
                                          text: '${DateFmt.dayLabel(_date, now: now)} ›',
                                          style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                                        ),
                                      ],
                                    ),
                                    style: t.caption.copyWith(color: c.muted),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Text('Kategori', style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.sub)),
                            const SizedBox(height: AppSpace.x8),
                            // Satu baris geser: dompet & tanggal tetap terlihat di atas keypad.
                            SizedBox(
                              height: 38,
                              child: ListView.separated(
                                key: const Key('kategori'),
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                itemCount: cats.length,
                                separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x8),
                                itemBuilder: (_, i) => AppChip(
                                  label: cats[i].name,
                                  icon: AppIcons.of(cats[i].icon),
                                  selected: cats[i].id == _categoryId,
                                  onTap: () => setState(() {
                                    _categoryId = cats[i].id;
                                    _error = null;
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.x16),
                            Row(
                              children: [
                                Expanded(
                                  child: _PickTile(
                                    label: _kind == TxKind.pemasukan ? 'Ke dompet' : 'Dari dompet',
                                    value: walletName(_walletId),
                                    onTap: () => _pickWallet(to: false),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.x12),
                                Expanded(
                                  child: _PickTile(
                                    label: 'Tanggal',
                                    value: DateFmt.dayLabel(_date, now: now),
                                    onTap: _pickDate,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpace.x16),
                          Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                            decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              key: const Key('catatan'),
                              controller: _note,
                              style: t.item.copyWith(fontWeight: FontWeight.w500),
                              maxLength: 80,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: _bare('Catatan (opsional)'),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_wallets.isNotEmpty) ...[
                // Keypad disembunyikan saat keyboard HP terbuka (mengetik catatan / Catat cepat).
                if (!keyboard) ...[
                  const SizedBox(height: AppSpace.x16),
                  AmountKeypad(onKey: _onKey),
                ],
                const SizedBox(height: AppSpace.x12),
                if (_error != null) ...[
                  Text(_error!, style: t.caption.copyWith(color: c.danger)),
                  const SizedBox(height: AppSpace.x8),
                ],
                AppButton(
                  label: _isEdit
                      ? 'Simpan perubahan'
                      : _amount == 0
                          ? 'Simpan'
                          : 'Simpan · ${Rupiah.format(_amount)}',
                  large: true,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _bare(String hint) => InputDecoration(
      hintText: hint,
      filled: false,
      isDense: true,
      counterText: '',
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );

/// Kolom Catat cepat (fitur app, dipertahankan di atas form).
class _QuickField extends StatelessWidget {
  const _QuickField({required this.controller, required this.autofocus, required this.onChanged});

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
      decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 20, color: c.accentText),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: TextField(
              key: const Key('catat-cepat'),
              controller: controller,
              autofocus: autofocus,
              style: context.text.item.copyWith(fontWeight: FontWeight.w500),
              textInputAction: TextInputAction.done,
              decoration: _bare('Ketik cepat: kopi 25rb gopay'),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan "Dari dompet · GoPay ›" / "Tanggal · Hari ini, 19 Okt ›".
class _PickTile extends StatelessWidget {
  const _PickTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable.card(
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: context.text.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            const SizedBox(height: AppSpace.x2),
            Text(
              '$value ›',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.title.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris pilihan di lembar bawah dompet / tanggal.
class _SheetOption extends StatelessWidget {
  const _SheetOption({required this.icon, required this.label, required this.selected, required this.onTap, this.value});

  final IconData icon;
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.x8),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x12),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.bg,
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll),
                child: Icon(icon, size: 20, color: c.accentText),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(child: Text(label, style: t.item)),
              if (value != null) Text(value!, style: t.caption.copyWith(color: c.sub)),
              if (selected) ...[
                const SizedBox(width: AppSpace.x8),
                Icon(Icons.check_circle, size: 20, color: c.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
