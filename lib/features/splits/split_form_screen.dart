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
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../debts/data/debts_dao.dart';
import '../debts/debts_provider.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import '../wallets/data/wallets_dao.dart' show WalletBalance;
import 'data/splits.dart';
import 'data/splits_dao.dart';
import 'splits_provider.dart';
import '../premium/pro_controller.dart';
import '../scan/data/receipt_parser.dart';
import '../scan/scan_screen.dart' show ScanResult, startReceiptScan;
import 'splits_screen.dart' show SplitAvatar;

class _Item {
  _Item(this.name, this.price, this.who);
  String name;
  int price;
  Set<int> who;
}

/// Nama dari Utang-piutang & patungan sebelumnya, untuk saran peserta.
final _knownNamesProvider = Provider<List<String>>((ref) {
  final List<String> out = [];
  void add(String n) {
    final String k = n.trim();
    if (k.isNotEmpty && !out.any((x) => x.toLowerCase() == k.toLowerCase())) out.add(k);
  }

  for (final s in ref.watch(splitsProvider).valueOrNull ?? const <SplitFull>[]) {
    for (final m in s.members) {
      if (!m.isMe) add(m.name);
    }
  }
  for (final DebtWithPayments d in ref.watch(debtsProvider).valueOrNull ?? const <DebtWithPayments>[]) {
    add(d.debt.name);
  }
  return out.take(12).toList();
});

/// Form patungan baru / ubah (P3c, Claude Design › Patungan).
class SplitFormScreen extends ConsumerStatefulWidget {
  const SplitFormScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<SplitFormScreen> createState() => _SplitFormScreenState();
}

class _SplitFormScreenState extends ConsumerState<SplitFormScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _total = TextEditingController();
  final TextEditingController _fee = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final List<String> _names = ['Aku'];
  final List<TextEditingController> _custom = [TextEditingController()];
  final List<_Item> _items = [];
  int _payer = 0;
  SplitMode _mode = SplitMode.rata;
  bool _tax = true;
  bool _service = false;

  /// Tarif pajak & service dalam permil (bawaan PB1 10%, service 5%; dari struk bila discan).
  int _taxRate = 100;
  int _serviceRate = 50;
  late DateTime _date = ref.read(clockProvider)();
  int? _walletId;
  int? _categoryId;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _load(widget.editId!);
  }

  Future<void> _load(int id) async {
    final SplitFull? s = await ref.read(appDatabaseProvider).splitsDao.byId(id);
    if (s == null || !mounted) return;
    setState(() {
      _title.text = s.split.title;
      _total.text = Rupiah.digits(s.split.total);
      _date = s.split.occurredAt;
      _walletId = s.split.walletId;
      _categoryId = s.split.categoryId;
      _mode = s.split.mode;
      _tax = s.split.taxPermille > 0;
      _service = s.split.servicePermille > 0;
      if (_tax) _taxRate = s.split.taxPermille;
      if (_service) _serviceRate = s.split.servicePermille;
      _fee.text = s.split.extraFee > 0 ? Rupiah.digits(s.split.extraFee) : '';
      _discount.text = s.split.discount > 0 ? Rupiah.digits(s.split.discount) : '';
      _names
        ..clear()
        ..addAll([for (final m in s.members) m.isMe ? 'Aku' : m.name]);
      _custom
        ..clear()
        ..addAll([for (final m in s.members) TextEditingController(text: Rupiah.digits(m.share))]);
      _payer = s.members.indexWhere((m) => m.payer);
      _items
        ..clear()
        ..addAll([
          for (final i in s.items)
            _Item(i.name, i.price, {for (final w in i.who.split(',')) if (int.tryParse(w) != null) int.parse(w)}),
        ]);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _total, _fee, _discount, ..._custom]) {
      c.dispose();
    }
    super.dispose();
  }

  MenuBill get _bill => menuBill(
        [for (final i in _items) (name: i.name, price: i.price, who: i.who)],
        taxPermille: _tax ? _taxRate : 0,
        servicePermille: _service ? _serviceRate : 0,
        extraFee: RupiahInputFormatter.parse(_fee.text),
        discount: RupiahInputFormatter.parse(_discount.text),
      );

  int get _totalValue => _mode == SplitMode.menu ? _bill.total : RupiahInputFormatter.parse(_total.text);

  List<int> get _shares => switch (_mode) {
        SplitMode.rata => splitEven(_totalValue, _names.length, payer: _payer),
        SplitMode.custom => [for (final c in _custom) RupiahInputFormatter.parse(c.text)],
        SplitMode.menu => splitMenu([for (final i in _items) (name: i.name, price: i.price, who: i.who)], _names.length, _bill),
      };

  void _addMember(String name) {
    final String n = name.trim();
    if (n.isEmpty || _names.any((x) => x.toLowerCase() == n.toLowerCase())) return;
    setState(() {
      _names.add(n);
      _custom.add(TextEditingController());
      for (final i in _items) {
        if (i.who.length == _names.length - 1) i.who.add(_names.length - 1);
      }
    });
  }

  void _removeMember(int i) {
    if (i == 0) return;
    setState(() {
      _names.removeAt(i);
      _custom.removeAt(i).dispose();
      if (_payer == i) _payer = 0;
      if (_payer > i) _payer--;
      for (final it in _items) {
        it.who = {for (final w in it.who) if (w != i) w > i ? w - 1 : w};
      }
    });
  }

  Future<void> _openAddMember() async {
    final List<String> known = [
      for (final n in ref.read(_knownNamesProvider))
        if (!_names.any((x) => x.toLowerCase() == n.toLowerCase())) n,
    ];
    final String? name = await showAppSheet<String>(context, title: 'Tambah peserta', builder: (_) => _AddMemberSheet(known: known));
    if (name != null) _addMember(name);
  }

  Future<void> _openItem([int? index]) async {
    final _Item? existing = index == null ? null : _items[index];
    final ({String name, int price})? r = await showAppSheet<({String name, int price})>(
      context,
      title: existing == null ? 'Tambah item' : 'Ubah item',
      builder: (_) => _ItemSheet(name: existing?.name, price: existing?.price),
    );
    if (r == null) return;
    setState(() {
      if (existing == null) {
        _items.add(_Item(r.name, r.price, {for (int i = 0; i < _names.length; i++) i}));
      } else {
        existing
          ..name = r.name
          ..price = r.price;
      }
    });
  }

  Future<void> _save() async {
    final List<int> shares = _shares;
    final String title = _title.text.trim();
    if (title.isEmpty) return setState(() => _error = 'Isi judul patungannya.');
    final String? problem = splitProblem(
      total: _totalValue,
      names: _names,
      shares: shares,
      lines: _mode == SplitMode.menu ? [for (final i in _items) (name: i.name, price: i.price, who: i.who)] : null,
    );
    if (problem != null) return setState(() => _error = problem);
    final int? wallet = _walletId ?? _defaultWallet();
    if (wallet == null) return setState(() => _error = 'Buat dompet dulu.');
    final SplitsDao dao = ref.read(appDatabaseProvider).splitsDao;
    try {
      final int id = await dao.save(
        id: widget.editId,
        title: title,
        mode: _mode,
        total: _totalValue,
        walletId: wallet,
        categoryId: _categoryId ?? _defaultCategory(),
        occurredAt: _date,
        members: [
          for (final (int i, String n) in _names.indexed) (name: n, isMe: i == 0, payer: i == _payer, share: shares[i]),
        ],
        items: _mode == SplitMode.menu ? [for (final i in _items) (name: i.name, price: i.price, who: i.who)] : const [],
        taxPermille: _mode == SplitMode.menu && _tax ? _taxRate : 0,
        servicePermille: _mode == SplitMode.menu && _service ? _serviceRate : 0,
        extraFee: _mode == SplitMode.menu ? RupiahInputFormatter.parse(_fee.text) : 0,
        discount: _mode == SplitMode.menu ? RupiahInputFormatter.parse(_discount.text) : 0,
      );
      if (!mounted) return;
      final int debtsMade = _payer == 0 ? shares.skip(1).where((v) => v > 0).length : (shares[0] > 0 ? 1 : 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_payer == 0
            ? 'Patungan tersimpan · $debtsMade catatan piutang dibuat'
            : 'Patungan tersimpan · utangmu ke ${_names[_payer]} dicatat'),
      ));
      widget.editId == null ? context.pushReplacement(Routes.patunganDetail(id)) : context.pop();
    } on StateError catch (e) {
      setState(() => _error = e.message);
    }
  }

  static String _pct(int permille) =>
      '${(permille / 10).toStringAsFixed(permille % 10 == 0 ? 0 : 1).replaceAll('.', ',')}%';

  /// Scan struk restoran (P3e): item, pajak, service, ongkir & diskon terisi.
  Future<void> _scan() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ScanResult? r = await startReceiptScan(context, ref, forSplit: true);
    if (r == null || !mounted) return;
    final ReceiptScan s = r.scan;
    final int base = s.items.fold(0, (a, i) => a + i.price);
    final int taxRate = s.taxPermille, serviceRate = s.servicePermille;
    // Selisih pembulatan tarif masuk ke biaya supaya total sama persis dengan struk.
    final int drift = (s.tax - (base * taxRate / 1000).round()) + (s.service - (base * serviceRate / 1000).round());
    setState(() {
      _mode = SplitMode.menu;
      _error = null;
      _items
        ..clear()
        ..addAll([
          for (final it in s.items)
            _Item(it.qty > 1 ? '${it.name} ×${it.qty}' : it.name, it.price, {for (int i = 0; i < _names.length; i++) i}),
        ]);
      _tax = taxRate > 0;
      _service = serviceRate > 0;
      if (taxRate > 0) _taxRate = taxRate;
      if (serviceRate > 0) _serviceRate = serviceRate;
      final int fee = s.extraFee + drift;
      _fee.text = fee > 0 ? Rupiah.digits(fee) : '';
      _discount.text = s.discount + (fee < 0 ? -fee : 0) > 0 ? Rupiah.digits(s.discount + (fee < 0 ? -fee : 0)) : '';
      if (_title.text.trim().isEmpty && s.merchant != null) _title.text = s.merchant!;
      if (r.date != null) _date = r.date!;
      if (r.walletId != null) _walletId = r.walletId;
    });
  }

  int? _defaultWallet() {
    final List<WalletBalance> ws = ref.read(walletBalancesProvider).valueOrNull ?? const [];
    return ws.firstOrNull?.wallet.id;
  }

  int? _defaultCategory() {
    final List<Category> cats = ref.read(activeCategoriesProvider).valueOrNull ?? const [];
    return (cats.where((c) => c.kind == TxKind.pengeluaran && c.name == 'Makan & Minum').firstOrNull ??
            cats.where((c) => c.kind == TxKind.pengeluaran).firstOrNull)
        ?.id;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    final List<Category> cats = [
      for (final x in ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        if (x.kind == TxKind.pengeluaran) x,
    ];
    _walletId ??= wallets.firstOrNull?.wallet.id;
    _categoryId ??= _defaultCategory();
    if (widget.editId != null && !_loaded) return const Scaffold(body: SizedBox.shrink());
    final List<int> shares = _shares;
    final int total = _totalValue;
    final int left = total - shares.fold(0, (a, v) => a + v);
    final int orphan = _mode == SplitMode.menu ? _items.where((i) => i.who.isEmpty).length : 0;
    final String walletName = wallets.where((w) => w.wallet.id == _walletId).firstOrNull?.wallet.name ?? 'dompet';
    final String catName = cats.where((x) => x.id == _categoryId).firstOrNull?.name ?? 'Pengeluaran';
    final List<String> effects = _payer == 0
        ? [
            'Pengeluaranmu ${Rupiah.format(shares[0])} · $catName (masuk Laporan)',
            if (shares.skip(1).any((v) => v > 0))
              'Piutang: ${[for (int i = 1; i < _names.length; i++) if (shares[i] > 0) '${_names[i]} ${Rupiah.format(shares[i])}'].join(', ')}',
            'Saldo $walletName berkurang ${Rupiah.format(total)}',
          ]
        : [
            'Pengeluaranmu ${Rupiah.format(shares[0])} · $catName (masuk Laporan)',
            'Utangmu ke ${_names[_payer]} ${Rupiah.format(shares[0])} · saldo $walletName tidak berubah',
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpace.screen,
                children: [
                  ScreenHeader(title: widget.editId == null ? 'Patungan baru' : 'Ubah patungan', large: true),
                  const SizedBox(height: AppSpace.x16),
                  TextField(
                    controller: _title,
                    autofocus: widget.editId == null,
                    maxLength: 60,
                    style: t.item,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Judul', hintText: 'mis. Makan Solaria', counterText: ''),
                  ),
                  const SizedBox(height: AppSpace.x8),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      AppChip(
                        label: DateFmt.dayLabel(_date, now: now),
                        icon: HiIcons.calendar,
                        selected: true,
                        onTap: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          final DateTime? d = await showDatePicker(
                              context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                        },
                      ),
                    ],
                  ),
                  FieldLabel('Peserta · ${_names.length} orang'),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final (int i, String n) in _names.indexed)
                        _PersonChip(name: n, me: i == 0, onRemove: i == 0 ? null : () => _removeMember(i)),
                      Pressable(
                        onTap: _openAddMember,
                        semanticLabel: 'Tambah peserta',
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
                          decoration: BoxDecoration(borderRadius: AppRadius.pillAll, border: Border.all(color: c.line)),
                          child: Text('+ Tambah', style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const FieldLabel('Yang bayar ke kasir'),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final (int i, String n) in _names.indexed)
                        AppChip(label: n, selected: _payer == i, onTap: () => setState(() => _payer = i)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x16),
                  AppSegmentedControl<SplitMode>(
                    options: SplitMode.values,
                    selected: _mode,
                    labelOf: (m) => m.label,
                    onChanged: (m) => setState(() {
                      _mode = m;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  if (_mode != SplitMode.menu)
                    TextField(
                      controller: _total,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [RupiahInputFormatter()],
                      style: t.number.copyWith(fontSize: 18),
                      onChanged: (_) => setState(() => _error = null),
                      decoration: const InputDecoration(
                          labelText: 'Total tagihan', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
                    )
                  else
                    _MenuEditor(
                      items: _items,
                      names: _names,
                      bill: _bill,
                      tax: _tax,
                      service: _service,
                      taxLabel: 'PB1 ${_pct(_taxRate)}',
                      serviceLabel: 'Service ${_pct(_serviceRate)}',
                      onScan: _scan,
                      fee: _fee,
                      discount: _discount,
                      onAdd: () => _openItem(),
                      onEdit: _openItem,
                      onRemove: (i) => setState(() => _items.removeAt(i)),
                      onToggle: (i, who) => setState(() {
                        final Set<int> w = _items[i].who;
                        w.contains(who) ? w.remove(who) : w.add(who);
                      }),
                      onTax: (v) => setState(() => _tax = v),
                      onService: (v) => setState(() => _service = v),
                      onChanged: () => setState(() {}),
                    ),
                  const SizedBox(height: AppSpace.x12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                    decoration:
                        BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                    child: Column(
                      children: [
                        for (final (int i, String n) in _names.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                            child: Row(
                              children: [
                                SplitAvatar(name: n, me: i == 0, size: 32),
                                const SizedBox(width: AppSpace.x12),
                                Expanded(child: Text(i == _payer ? '$n · bayar dulu' : n, style: t.item.copyWith(fontSize: 14))),
                                if (_mode == SplitMode.custom)
                                  SizedBox(
                                    width: 130,
                                    child: TextField(
                                      controller: _custom[i],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: const [RupiahInputFormatter()],
                                      textAlign: TextAlign.right,
                                      style: t.number,
                                      onChanged: (_) => setState(() => _error = null),
                                      decoration: const InputDecoration(isDense: true, hintText: '0', prefixText: 'Rp '),
                                    ),
                                  )
                                else
                                  Text(Rupiah.format(shares[i]), style: t.number),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(orphan > 0 ? 'Item belum dipilih siapa' : 'Sisa belum terbagi',
                                    style: t.caption.copyWith(color: c.sub)),
                              ),
                              Text(
                                orphan > 0 ? '$orphan item' : (left == 0 ? 'Rp0 ✓' : Rupiah.format(left)),
                                style: t.caption.copyWith(
                                    fontWeight: FontWeight.w700, color: orphan > 0 || left != 0 ? c.danger : c.good),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  FieldLabel(_payer == 0 ? 'Dibayar dari dompet' : 'Dompet untuk catatan utangmu'),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final w in wallets)
                        AppChip(
                          label: w.wallet.name,
                          icon: AppIcons.of(w.wallet.icon),
                          emoji: AppIcons.emojiOf(w.wallet.icon),
                          selected: w.wallet.id == _walletId,
                          onTap: () => setState(() => _walletId = w.wallet.id),
                        ),
                    ],
                  ),
                  const FieldLabel('Kategori bagianmu'),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final x in cats.take(10))
                        AppChip(
                          label: x.name,
                          icon: AppIcons.of(x.icon),
                          emoji: AppIcons.emojiOf(x.icon),
                          selected: x.id == _categoryId,
                          onTap: () => setState(() => _categoryId = x.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdAll),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yang dicatat', style: t.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                        for (final e in effects) Text('• $e', style: t.caption.copyWith(color: c.sub, height: 1.5)),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpace.x12),
                    Text(_error!, style: t.caption.copyWith(color: c.danger)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
              child: AppButton(label: 'Simpan · ${Rupiah.format(total)}', large: true, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name, required this.me, this.onRemove});

  final String name;
  final bool me;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      height: 36,
      padding: EdgeInsets.only(left: 4, right: onRemove == null ? AppSpace.x12 : 2),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.pillAll, border: Border.all(color: c.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SplitAvatar(name: name, me: me, size: 28),
          const SizedBox(width: AppSpace.x8),
          Text(name, style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.ink)),
          if (onRemove != null)
            Pressable(
              onTap: onRemove,
              semanticLabel: 'Hapus $name',
              child: SizedBox(width: 32, height: 32, child: Icon(HiIcons.close, size: 14, color: c.muted)),
            ),
        ],
      ),
    );
  }
}

class _MenuEditor extends StatelessWidget {
  const _MenuEditor({
    required this.items,
    required this.names,
    required this.bill,
    required this.tax,
    required this.service,
    required this.fee,
    required this.discount,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onToggle,
    required this.onTax,
    required this.onService,
    required this.taxLabel,
    required this.serviceLabel,
    required this.onScan,
    required this.onChanged,
  });

  final List<_Item> items;
  final List<String> names;
  final MenuBill bill;
  final bool tax;
  final bool service;
  final TextEditingController fee;
  final TextEditingController discount;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onRemove;
  final void Function(int item, int who) onToggle;
  final ValueChanged<bool> onTax;
  final ValueChanged<bool> onService;
  final String taxLabel;
  final String serviceLabel;
  final VoidCallback onScan;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.x8, bottom: AppSpace.x4),
            child: _ScanCard(onTap: onScan),
          ),
          for (final (int i, _Item it) in items.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pressable(
                    onTap: () => onEdit(i),
                    onLongPress: () => onRemove(i),
                    semanticLabel: '${it.name} ${Rupiah.format(it.price)}, ketuk untuk ubah, tahan untuk hapus',
                    child: Row(
                      children: [
                        Expanded(child: Text(it.name, style: t.item.copyWith(fontSize: 14))),
                        Text(Rupiah.format(it.price), style: t.number.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x8),
                  Wrap(
                    spacing: AppSpace.x8 - 2,
                    runSpacing: AppSpace.x8 - 2,
                    children: [
                      for (final (int w, String n) in names.indexed)
                        _WhoToggle(name: n, me: w == 0, on: it.who.contains(w), onTap: () => onToggle(i, w)),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppChip(label: '+ Tambah item', onTap: onAdd),
            ),
          ),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              AppChip(label: taxLabel, selected: tax, onTap: () => onTax(!tax)),
              AppChip(label: serviceLabel, selected: service, onTap: () => onService(!service)),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fee,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  style: t.number.copyWith(fontSize: 14),
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(isDense: true, labelText: 'Ongkir/biaya', prefixText: 'Rp '),
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(
                child: TextField(
                  controller: discount,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  style: t.number.copyWith(fontSize: 14),
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(isDense: true, labelText: 'Diskon', prefixText: 'Rp '),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          for (final (String k, int v) in [
            ('Subtotal', bill.subtotal),
            if (bill.tax > 0) (taxLabel, bill.tax),
            if (bill.service > 0) (serviceLabel, bill.service),
            if (bill.extraFee > 0) ('Ongkir/biaya', bill.extraFee),
            if (bill.discount > 0) ('Diskon', -bill.discount),
            ('Total', bill.total),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.x4),
              child: Row(
                children: [
                  Expanded(
                      child: Text(k,
                          style: t.caption.copyWith(color: k == 'Total' ? c.ink : c.sub, fontWeight: k == 'Total' ? FontWeight.w700 : null))),
                  Text(Rupiah.format(v),
                      style: t.caption.copyWith(color: k == 'Total' ? c.ink : c.sub, fontWeight: k == 'Total' ? FontWeight.w700 : null)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.x8),
            child: Text('Pajak, service, ongkir & diskon dibagi sesuai porsi tiap orang. Tahan item untuk menghapus.',
                style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
          ),
        ],
      ),
    );
  }
}

class _WhoToggle extends StatelessWidget {
  const _WhoToggle({required this.name, required this.me, required this.on, required this.onTap});

  final String name;
  final bool me;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: on,
      child: Pressable(
        onTap: onTap,
        semanticLabel: '${on ? 'Hapus' : 'Tambah'} $name',
        child: Opacity(
          opacity: on ? 1 : 0.35,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: on ? c.accent : Colors.transparent, width: 2),
            ),
            child: SplitAvatar(name: name, me: me, size: 32),
          ),
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.known});

  final List<String> known;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(context, v.trim().isEmpty ? null : v.trim()),
          decoration: const InputDecoration(labelText: 'Nama', hintText: 'mis. Budi', counterText: ''),
        ),
        if (widget.known.isNotEmpty) ...[
          const FieldLabel('Pernah dicatat'),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final n in widget.known)
                Pressable(
                  onTap: () => Navigator.pop(context, n),
                  semanticLabel: 'Tambah $n',
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.only(left: 4, right: AppSpace.x12),
                    decoration: BoxDecoration(borderRadius: AppRadius.pillAll, border: Border.all(color: context.colors.line)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SplitAvatar(name: n, size: 28),
                      const SizedBox(width: AppSpace.x8),
                      Text(n, style: t.caption.copyWith(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Tambah',
          large: true,
          onPressed: () => Navigator.pop(context, _name.text.trim().isEmpty ? null : _name.text.trim()),
        ),
        const SizedBox(height: AppSpace.x8),
        Text('Nama diketik sendiri — HitungIn tidak membaca kontakmu.',
            textAlign: TextAlign.center, style: t.label.copyWith(fontWeight: FontWeight.w500, color: context.colors.muted)),
      ],
    );
  }
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({this.name, this.price});

  final String? name;
  final int? price;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.name ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.price == null ? '' : Rupiah.digits(widget.price!));
  int _qty = 1;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int price = RupiahInputFormatter.parse(_price.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 60,
          style: t.item,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama item', hintText: 'mis. Ayam bakar', counterText: ''),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Harga satuan', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        if (widget.name == null) ...[
          const FieldLabel('Jumlah'),
          Row(
            children: [
              AppChip(label: '−', onTap: _qty > 1 ? () => setState(() => _qty--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Text('$_qty', style: t.number),
              ),
              AppChip(label: '+', onTap: () => setState(() => _qty++)),
              const Spacer(),
              Text(price > 0 ? Rupiah.format(price * _qty) : '', style: t.number.copyWith(color: c.sub)),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x8),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: widget.name == null ? 'Tambah item' : 'Simpan',
          large: true,
          onPressed: () {
            final String n = _name.text.trim();
            if (n.isEmpty) return setState(() => _error = 'Isi nama itemnya.');
            if (price <= 0) return setState(() => _error = 'Isi harganya.');
            Navigator.pop(context, (name: _qty > 1 ? '$n ×$_qty' : n, price: price * _qty));
          },
        ),
      ],
    );
  }
}

class _ScanCard extends ConsumerWidget {
  const _ScanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      key: const Key('scan-struk-patungan'),
      onTap: onTap,
      semanticLabel: 'Scan struk',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: c.accent.withValues(alpha: 0.6)),
        ),
        child: Row(children: [
          Icon(HiIcons.receipt, size: 22, color: c.accentText),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Scan struk', style: t.item.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Semua menu, PB1 & service langsung terisi', style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ]),
          ),
          if (!ref.watch(isProProvider)) const AppBadge.pro(),
        ]),
      ),
    );
  }
}
