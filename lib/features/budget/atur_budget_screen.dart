import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import '../settings/data/settings_dao.dart';
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'data/budget_insights.dart';

/// Atur budget satu halaman (Claude Design › Atur Budget): total + pembagian,
/// −/+ per kategori dengan rata-rata 3 bulan, peringatan 80%.
/// [suggest] = isi awal dari kebiasaan (rata-rata 3 bulan).
class AturBudgetScreen extends ConsumerStatefulWidget {
  const AturBudgetScreen({super.key, this.suggest = false});

  final bool suggest;

  @override
  ConsumerState<AturBudgetScreen> createState() => _AturBudgetScreenState();
}

class _AturBudgetScreenState extends ConsumerState<AturBudgetScreen> {
  bool _loaded = false;
  bool _saving = false;
  int _total = 0;
  final Map<int, int> _amounts = {};
  Map<int, int> _averages = const {};
  List<Category> _categories = const [];
  bool _warn = true;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppDatabase db = ref.read(appDatabaseProvider);
    final DateTime now = ref.read(clockProvider)();
    final List<Category> cats = await db.categoriesDao.active(kind: TxKind.pengeluaran);
    final List<Budget> budgets = await db.budgetsDao.all();
    final Map<int, int> avg = await db.transactionsDao.categoryAverages(DateTime(now.year, now.month));
    final String? warn = await db.settingsDao.read(SettingKeys.budgetWarn80);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _averages = avg;
      _warn = warn != 'false';
      for (final Budget b in budgets) {
        if (b.categoryId == null) {
          _total = b.limitAmount;
        } else {
          _amounts[b.categoryId!] = b.limitAmount;
        }
      }
      if (widget.suggest) _applySuggestion();
      _loaded = true;
    });
  }

  /// Isi dari rata-rata 3 bulan. Versi gratis: hanya 2 kategori terbesar.
  void _applySuggestion() {
    if (_averages.isEmpty) {
      _note = 'Belum ada catatan bulan sebelumnya. Isi manual dulu; saran muncul setelah 1 bulan pencatatan.';
      return;
    }
    final bool isPro = ref.read(isProProvider);
    final List<MapEntry<int, int>> sorted = _averages.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    _amounts.clear();
    for (final MapEntry<int, int> e in isPro ? sorted : sorted.take(FreeLimits.categoryBudgets)) {
      _amounts[e.key] = suggestLimit(e.value);
    }
    _total = suggestLimit(_averages.values.fold(0, (s, v) => s + v));
    _note = isPro
        ? 'Diisi dari rata-rata 3 bulan terakhir. Ubah sesukamu sebelum disimpan.'
        : 'Diisi dari rata-rata 3 bulan terakhir (versi gratis: ${FreeLimits.categoryBudgets} kategori terbesar).';
  }

  int get _allocated => _amounts.values.fold(0, (s, v) => s + v);
  int get _activeCategories => _amounts.values.where((v) => v > 0).length;

  /// Batas gratis: budget kategori ke-3 dst. butuh Pro.
  bool _allowNew(int categoryId) {
    if ((_amounts[categoryId] ?? 0) > 0) return true;
    if (FreeLimits.canAddCategoryBudget(existing: _activeCategories, isPro: ref.read(isProProvider))) return true;
    openPremium(context, ProReason.budget);
    return false;
  }

  void _step(int categoryId, int delta) {
    if (delta > 0 && !_allowNew(categoryId)) return;
    setState(() => _amounts[categoryId] = ((_amounts[categoryId] ?? 0) + delta).clamp(0, 99999999999));
  }

  Future<void> _type({required String title, required int current, required ValueChanged<int> onDone}) async {
    final int? value = await showAppSheet<int>(
      context,
      title: title,
      builder: (context) => _AmountForm(initial: current),
    );
    if (value != null && mounted) setState(() => onDone(value));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final AppDatabase db = ref.read(appDatabaseProvider);
    await db.budgetsDao.saveAll(total: _total, perCategory: {
      for (final Category c in _categories) c.id: _amounts[c.id] ?? 0,
    });
    await db.settingsDao.write(SettingKeys.budgetWarn80, '$_warn');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget disimpan')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final int allocated = _allocated;
    final bool over = _total > 0 && allocated > _total;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            children: [
              ScreenHeader(title: 'Atur budget ${DateFmt.months[now.month - 1]}'),
              const SizedBox(height: AppSpace.x16),
              Expanded(
                child: !_loaded
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (_note != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppSpace.x12),
                              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdAll),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.auto_awesome_outlined, size: 18, color: c.accentText),
                                  const SizedBox(width: AppSpace.x8),
                                  Expanded(child: Text(_note!, style: t.caption.copyWith(color: c.ink))),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.x16),
                          ],
                          // Total + pembagian.
                          Container(
                            padding: const EdgeInsets.all(AppSpace.card),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: AppRadius.lgAll,
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total budget bulanan', style: t.caption.copyWith(color: c.muted)),
                                          const SizedBox(height: AppSpace.x2),
                                          Text(
                                            _total == 0 ? 'Belum diatur' : Rupiah.format(_total),
                                            style: t.amountL.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppButton(
                                      label: 'Ubah',
                                      variant: AppButtonVariant.outline,
                                      expand: false,
                                      onPressed: () => _type(
                                        title: 'Total budget bulanan',
                                        current: _total,
                                        onDone: (v) => _total = v,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_total > 0) ...[
                                  const SizedBox(height: AppSpace.x12),
                                  AppProgressBar(
                                    value: allocated / _total,
                                    height: 8,
                                    autoLevel: false,
                                    color: over ? c.danger : c.accent,
                                  ),
                                  const SizedBox(height: AppSpace.x8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Terbagi ${Rupiah.compact(allocated)} dari ${Rupiah.compact(_total)}',
                                          style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                                        ),
                                      ),
                                      Text(
                                        allocationStatus(_total, allocated, Rupiah.compact),
                                        style: t.label.copyWith(
                                          color: allocated == _total
                                              ? c.good
                                              : over
                                                  ? c.danger
                                                  : c.warnInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.x16),
                          // Per kategori.
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: AppRadius.lgAll,
                              border: Border.all(color: c.line),
                            ),
                            child: Column(
                              children: [
                                for (final (int i, Category cat) in _categories.indexed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
                                    decoration: BoxDecoration(
                                      border: i == _categories.length - 1
                                          ? null
                                          : Border(bottom: BorderSide(color: c.line)),
                                    ),
                                    child: _CategoryStepper(
                                      category: cat,
                                      amount: _amounts[cat.id] ?? 0,
                                      hint: (_averages[cat.id] ?? 0) > 0
                                          ? 'Rata-rata ${Rupiah.compact(_averages[cat.id]!)}'
                                          : 'Belum ada data',
                                      onMinus: () => _step(cat.id, -budgetStep),
                                      onPlus: () => _step(cat.id, budgetStep),
                                      onTapAmount: () {
                                        if (!_allowNew(cat.id)) return;
                                        _type(
                                          title: cat.name,
                                          current: _amounts[cat.id] ?? 0,
                                          onDone: (v) => _amounts[cat.id] = v,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.x16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x12),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: AppRadius.lgAll,
                              border: Border.all(color: c.line),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Peringatan di 80%', style: t.item),
                                      const SizedBox(height: AppSpace.x2),
                                      Text(
                                        'Tandai kategori yang mendekati batas',
                                        style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(value: _warn, onChanged: (v) => setState(() => _warn = v)),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpace.x12),
              AppButton(label: 'Simpan budget', large: true, onPressed: !_loaded || _saving ? null : _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStepper extends StatelessWidget {
  const _CategoryStepper({
    required this.category,
    required this.amount,
    required this.hint,
    required this.onMinus,
    required this.onPlus,
    required this.onTapAmount,
  });

  final Category category;
  final int amount;
  final String hint;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTapAmount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget step(String label, String semantic, VoidCallback? onTap) => Pressable(
          onTap: onTap,
          semanticLabel: semantic,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.chip, borderRadius: BorderRadius.circular(10)),
            child: ExcludeSemantics(
              child: Text(label, style: t.title.copyWith(fontSize: 18, color: onTap == null ? c.line2 : c.ink)),
            ),
          ),
        );
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
          child: Icon(AppIcons.of(category.icon), size: 20, color: c.accentText),
        ),
        const SizedBox(width: AppSpace.x12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
              Text(hint, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ],
          ),
        ),
        step('−', 'Kurangi ${category.name} 50 ribu', amount == 0 ? null : onMinus),
        Pressable(
          onTap: onTapAmount,
          semanticLabel: 'Batas ${category.name}: ${amount == 0 ? 'belum diatur' : Rupiah.format(amount)}',
          child: SizedBox(
            width: 72,
            child: ExcludeSemantics(
              child: Text(
              amount == 0 ? '–' : Rupiah.compact(amount),
              textAlign: TextAlign.center,
              style: t.caption.copyWith(fontWeight: FontWeight.w700, color: amount == 0 ? c.muted : c.ink),
              ),
            ),
          ),
        ),
        step('+', 'Tambah ${category.name} 50 ribu', onPlus),
      ],
    );
  }
}

/// Isian nominal di lembar bawah; controller dimiliki widget ini supaya
/// tidak dibuang saat lembar masih beranimasi menutup.
class _AmountForm extends StatefulWidget {
  const _AmountForm({required this.initial});

  final int initial;

  @override
  State<_AmountForm> createState() => _AmountFormState();
}

class _AmountFormState extends State<_AmountForm> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initial == 0 ? '' : Rupiah.digits(widget.initial));

  void _done() => Navigator.pop(context, RupiahInputFormatter.parse(_text.text));

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            key: const Key('batas-budget'),
            controller: _text,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            style: context.text.number,
            decoration: const InputDecoration(
              labelText: 'Batas per bulan',
              prefixIcon: RupiahPrefix(),
              prefixIconConstraints: RupiahPrefix.constraints,
            ),
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Pakai', onPressed: _done),
        ],
      );
}
