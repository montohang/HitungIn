import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../debts/debts_screen.dart' show DebtDraft, debtDraftLink;
import '../goals/goals_screen.dart' show GoalDraft, goalDraftLink;
import '../scan/scan_screen.dart' show ScanResult, startReceiptScan;
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
import '../categories/data/categories_dao.dart' show subsOf;
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'widgets/amount_keypad.dart';
import '../wallets/data/wallets_dao.dart';
import '../security/app_gate.dart';
import 'widgets/balance_confirm.dart';
import 'data/kind_lock.dart';
import 'quick_entry_parser.dart';
import '../../core/widgets/hi_icons.dart';

/// Catat atau ubah transaksi. Kolom "Catat cepat" di atas membaca kalimat
/// bebas ("kopi 25rb gopay") dan mengisi form di bawahnya.
class CatatScreen extends ConsumerStatefulWidget {
  const CatatScreen({super.key, this.initialText, this.editId, this.copyId, this.transfer = false, this.income = false, this.scan = false});

  final String? initialText;

  /// Ubah transaksi yang sudah ada.
  final int? editId;

  /// Duplikat: isi form dari transaksi ini, disimpan sebagai transaksi baru hari ini.
  final int? copyId;

  /// Langsung ke Pindah Saldo (tombol di layar Dompet).
  final bool transfer;

  /// Mulai di tab Pemasukan (pintasan ikon "Catat pemasukan").
  final bool income;

  /// Langsung buka Scan struk (kamera di Beranda, pintasan ikon, kartu kenalan).
  final bool scan;

  @override
  ConsumerState<CatatScreen> createState() => _CatatScreenState();
}

class _CatatScreenState extends ConsumerState<CatatScreen> {
  final TextEditingController _quick = TextEditingController();

  /// Kalimat Catat cepat yang dibaca sebagai utang-piutang.
  DebtDraft? _debt;
  GoalDraft? _goal;
  final TextEditingController _note = TextEditingController();

  TxKind _kind = TxKind.pengeluaran;
  int _amount = 0;
  int? _categoryId;

  /// Kategori dari Catat cepat / transaksi yang diubah tampil paling depan.
  int? _pinnedCategory;

  /// Sub-kategori terpilih (kosong = tidak ada).
  String _sub = '';
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
    // Snackbar simpanan sebelumnya jangan sampai menutupi tombol Simpan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    });
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
        _sub = editing.sub;
        _walletId = editing.walletId;
        _toWalletId = editing.toWalletId;
        _date = editing.occurredAt;
        _note.text = editing.note;
      }
      if (widget.transfer && editing == null && copy == null) _kind = TxKind.transfer;
      if (widget.income && editing == null && copy == null) _kind = TxKind.pemasukan;
      if (copy != null) {
        _kind = copy.kind;
        _amount = copy.amount;
        _categoryId = copy.categoryId;
        _pinnedCategory = copy.categoryId;
        _sub = copy.sub;
        _walletId = copy.walletId;
        _toWalletId = copy.toWalletId;
        _note.text = copy.note;
      }
      _loaded = true;
    });
    if (widget.scan && editing == null && copy == null) _autoScan();
    final String text = widget.initialText?.trim() ?? '';
    if (text.isNotEmpty && editing == null) {
      _quick.text = text;
      _applyQuick(text, open: true);
    }
  }

  /// [open] = dari Catat cepat di Beranda: kalimat utang langsung dibuka di
  /// Utang-piutang. Saat mengetik di sini cukup ditawarkan lewat [_debt].
  void _applyQuick(String text, {bool open = false}) {
    final QuickEntry e =
        QuickEntryParser(wallets: _wallets, categories: _categories).parse(text, now: ref.read(clockProvider)());
    if (e.goal case final String name?) {
      // "nabung 100rb dana darurat" → Target tabungan.
      final GoalDraft g = (name: name, amount: e.amount, walletId: e.walletId);
      if (open) {
        context.pushReplacement(goalDraftLink(g));
      } else {
        setState(() {
          _goal = g;
          _debt = null;
        });
      }
      return;
    }
    final DebtIntent? debt = e.debt;
    final DebtDraft? draft = debt == null
        ? null
        : (direction: debt.direction, payment: debt.payment, name: debt.name, amount: e.amount, walletId: e.walletId);
    if (draft != null && open) {
      // "pinjam budi 200rb" → Utang-piutang, bukan pengeluaran.
      context.pushReplacement(debtDraftLink(draft));
      return;
    }
    if (draft != null) {
      setState(() {
        _debt = draft;
        _goal = null;
      });
      return;
    }
    setState(() {
      _debt = null;
      _goal = null;
      _error = null;
      _kind = e.kind;
      if (e.amount != null) _amount = e.amount!;
      _categoryId = e.categoryId;
      _pinnedCategory = e.categoryId;
      _sub = e.sub;
      if (e.walletId != null) _walletId = e.walletId;
      _toWalletId = e.toWalletId;
      _date = e.occurredAt;
      _note.text = e.note;
    });
  }

  /// Dibuka dari kamera Beranda / pintasan ikon: tunggu halaman selesai masuk
  /// & berada paling depan (mis. baru lewat layar kunci), baru buka scan.
  Future<void> _autoScan() async {
    for (int i = 0; i < 40; i++) {
      if (!mounted) return;
      final ModalRoute<Object?>? route = ModalRoute.of(context);
      if (route != null && route.isCurrent && route.animation?.status == AnimationStatus.completed) {
        await _scanReceipt();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Scan struk (P3e): isi nominal, catatan, tanggal, dompet & kategori.
  Future<void> _scanReceipt() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ScanResult? r = await startReceiptScan(context, ref, forSplit: false);
    if (r == null || !mounted) return;
    setState(() {
      _debt = null;
      _goal = null;
      _error = null;
      _kind = TxKind.pengeluaran;
      if (r.amount > 0) _amount = r.amount;
      _note.text = r.note;
      if (r.date != null) _date = r.date!;
      if (r.walletId != null) _walletId = r.walletId;
      if (r.categoryId != null) {
        _categoryId = r.categoryId;
        _pinnedCategory = r.categoryId;
        _sub = '';
      }
    });
  }

  void _setKind(TxKind kind) {
    final String? locked = _editing == null ? null : kindLockReason(_editing!, kind);
    if (locked != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(locked)));
      return;
    }
    _applyKind(kind);
  }

  void _applyKind(TxKind kind) => setState(() {
        if (kind == _kind) return;
        _kind = kind;
        _categoryId = null;
        _sub = '';
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
    final List<Wallet> options = to
        ? [
            for (final w in _wallets)
              if (w.id != _walletId) w
          ]
        : _wallets;
    final int? picked = await showAppSheet<int>(
      context,
      title: to ? 'Ke dompet' : (_kind == TxKind.transfer ? 'Dari dompet' : 'Pilih dompet'),
      builder: (context) => Column(
        children: [
          for (final Wallet w in options)
            _SheetOption(
              icon: AppIcons.of(w.icon),
              emoji: AppIcons.emojiOf(w.icon),
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
            icon: HiIcons.today,
            label: 'Hari ini',
            value: DateFmt.date(now, now: now),
            selected: daysAgo == 0,
            onTap: () => Navigator.pop(context, at(0)),
          ),
          _SheetOption(
            icon: HiIcons.history,
            label: 'Kemarin',
            value: DateFmt.date(at(1), now: now),
            selected: daysAgo == 1,
            onTap: () => Navigator.pop(context, at(1)),
          ),
          _SheetOption(
            icon: HiIcons.calendar,
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

  Future<bool> _confirmBalance(int amount) => confirmWalletBalance(
        context,
        ref,
        kind: _kind,
        walletId: _walletId!,
        toWalletId: _toWalletId,
        amount: amount,
        editing: _editing,
      );

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
    if (!await _confirmBalance(amount)) return;
    if (!mounted) return;

    setState(() => _saving = true);
    final dao = ref.read(appDatabaseProvider).transactionsDao;
    if (_editing != null) {
      await dao.edit(_editing!.copyWith(
        kind: _kind,
        amount: amount,
        walletId: _walletId,
        toWalletId: Value(transfer ? _toWalletId : null),
        categoryId: Value(transfer ? null : _categoryId),
        sub: transfer ? '' : _sub,
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
        sub: transfer ? '' : _sub,
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
              // ✕ · judul · Scan (desain). Judul selalu di tengah layar.
              SizedBox(
                height: AppSpace.touch,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 96),
                      child: Text(
                        _isEdit ? 'Ubah transaksi' : 'Catat transaksi',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.title.copyWith(fontSize: 17),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Pressable(
                        onTap: close,
                        semanticLabel: 'Tutup',
                        child: Container(
                          width: AppSpace.touch,
                          height: AppSpace.touch,
                          decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.smAll),
                          child: Icon(HiIcons.close, size: 20, color: c.ink),
                        ),
                      ),
                    ),
                    if (!_isEdit)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Pressable(
                          key: const Key('scan-struk'),
                          onTap: _scanReceipt,
                          semanticLabel: 'Scan struk',
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.only(left: 10, right: AppSpace.x12),
                            decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.pillAll),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(HiIcons.receipt, size: 18, color: c.accentText),
                              const SizedBox(width: 6),
                              Text('Scan', style: t.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText)),
                            ]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x16),
              Expanded(
                child: _wallets.isEmpty
                    ? Center(child: Text('Belum ada dompet aktif.', style: t.body.copyWith(color: c.sub)))
                    // Ruang sisa dibagi di atas & bawah nominal; isian (kategori, dompet,
                    // catatan) menempel ke keypad seperti desain. Layar pendek → bisa digulir.
                    : LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: box.maxHeight),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (!_isEdit) ...[
                                      _QuickField(
                                        controller: _quick,
                                        autofocus: false,
                                        onChanged: _applyQuick,
                                      ),
                                      if (_debt case final DebtDraft d?) ...[
                                        const SizedBox(height: AppSpace.x8),
                                        _DebtHint(draft: d, onOpen: () => context.pushReplacement(debtDraftLink(d))),
                                      ],
                                      if (_goal case final GoalDraft g?) ...[
                                        const SizedBox(height: AppSpace.x8),
                                        _OpenHint(
                                          icon: HiIcons.jar,
                                          text: 'Target tabungan: sisihkan${g.amount == null ? '' : ' ${Rupiah.format(g.amount!)}'}'
                                              '${g.name.isEmpty ? '' : ' untuk ${g.name}'}',
                                          onOpen: () => context.pushReplacement(goalDraftLink(g)),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpace.x16),
                                    ],
                                    AppSegmentedControl<TxKind>(
                                      options: TxKind.manual,
                                      selected: _kind,
                                      onSurface: true,
                                      labelOf: (k) => k == TxKind.transfer ? 'Pindah Saldo' : k.label,
                                      onChanged: _setKind,
                                      isLocked: _editing == null ? null : (k) => kindLockReason(_editing!, k) != null,
                                    ),
                                    if (!_isEdit) ...[
                                      const SizedBox(height: AppSpace.x8),
                                      Center(
                                        child: Pressable(
                                          onTap: () => context.pushReplacement(Routes.patunganBaru),
                                          semanticLabel: 'Bayar bareng teman? Buka Patungan',
                                          child: Container(
                                            height: 32,
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12),
                                            decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.pillAll),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(HiIcons.people, size: 16, color: c.accentText),
                                                const SizedBox(width: AppSpace.x8 - 2),
                                                Flexible(
                                                  child: Text('Bayar bareng teman? Patungan ›',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpace.x16),
                                  child: Column(
                                    children: [
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
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
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
                                            decoration:
                                                BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                                            child: Icon(HiIcons.arrowRight, size: 18, color: c.accentText),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.x16, vertical: AppSpace.x12),
                                        decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(HiIcons.info, size: 18, color: c.sub),
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpace.x4, vertical: AppSpace.x8),
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
                                      Text('Kategori',
                                          style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.sub)),
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
                                            emoji: AppIcons.emojiOf(cats[i].icon),
                                            selected: cats[i].id == _categoryId,
                                            onTap: () => setState(() {
                                              if (_categoryId != cats[i].id) _sub = '';
                                              _categoryId = cats[i].id;
                                              _error = null;
                                            }),
                                          ),
                                        ),
                                      ),
                                      if (subsOf(_categories.where((x) => x.id == _categoryId).firstOrNull)
                                          case final List<String> subs when subs.isNotEmpty) ...[
                                        const SizedBox(height: AppSpace.x8),
                                        // Sub-kategori (opsional): ketuk lagi untuk melepas.
                                        SizedBox(
                                          height: 32,
                                          child: ListView.separated(
                                            key: const Key('sub-kategori'),
                                            scrollDirection: Axis.horizontal,
                                            clipBehavior: Clip.none,
                                            itemCount: subs.length,
                                            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x8),
                                            itemBuilder: (_, i) => _SubChip(
                                              label: subs[i],
                                              selected: subs[i] == _sub,
                                              onTap: () => setState(() => _sub = subs[i] == _sub ? '' : subs[i]),
                                            ),
                                          ),
                                        ),
                                      ],
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
                              ],
                            ),
                          ),
                        ),
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
          Icon(HiIcons.sparkle, size: 20, color: c.accentText),
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
  const _SheetOption(
      {required this.icon, required this.label, required this.selected, required this.onTap, this.value, this.emoji});

  final IconData icon;
  final String? emoji;
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
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll),
                child: emoji != null
                    ? Text(emoji!, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 19, height: 1))
                    : Icon(icon, size: 20, color: c.accentText),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(child: Text(label, style: t.item)),
              if (value != null) Text(value!, style: t.caption.copyWith(color: c.sub)),
              if (selected) ...[
                const SizedBox(width: AppSpace.x8),
                Icon(HiIcons.checkCircle, size: 20, color: c.accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip sub-kategori 32 px (lebih kecil dari chip kategori).
class _SubChip extends StatelessWidget {
  const _SubChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Sub-kategori $label',
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surface,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: selected ? c.accent : c.line),
          ),
          child: Text(
            label,
            style: context.text.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? c.accentText : c.sub2,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Ini utang-piutang: Budi pinjam Rp200.000 · Buka".
class _DebtHint extends StatelessWidget {
  const _DebtHint({required this.draft, required this.onOpen});

  final DebtDraft draft;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final String who = draft.name.isEmpty ? 'seseorang' : draft.name;
    final String amount = draft.amount == null ? '' : ' ${Rupiah.format(draft.amount!)}';
    final String what = switch ((draft.direction, draft.payment)) {
      (DebtDirection.piutang, false) => '$who pinjam$amount',
      (DebtDirection.piutang, true) => '$who bayar$amount',
      (DebtDirection.utang, false) => 'Pinjam$amount dari $who',
      (DebtDirection.utang, true) => 'Bayar utang$amount ke $who',
    };
    return _OpenHint(icon: HiIcons.people, text: 'Utang-piutang: $what', onOpen: onOpen);
  }
}

/// Saran membuka layar lain untuk kalimat Catat cepat ("… · Buka ›").
class _OpenHint extends StatelessWidget {
  const _OpenHint({required this.icon, required this.text, required this.onOpen});

  final IconData icon;
  final String text;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: onOpen,
      semanticLabel: '$text, buka',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdAll),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.accentText),
            const SizedBox(width: AppSpace.x8),
            Expanded(child: Text(text, style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w600))),
            Text('Buka ›', style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
