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
import '../../core/widgets/app_button.dart';
import '../../core/widgets/glyph_icon.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../goals/data/goals_dao.dart';
import '../goals/goals_provider.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import 'atur_budget_screen.dart' show BudgetPreset;
import 'data/budget_template.dart';

/// Rute Template budget untuk [month].
String templateBudgetLink(DateTime month) =>
    Uri(path: Routes.templateBudget, queryParameters: {'month': DateFmt.monthKey(month)}).toString();

/// Langkah −/+ pemasukan bulanan.
const int _incomeStep = 500000;

/// Warna kelompok (bilah & penanda); identitas juga ditulis sebagai teks.
Color groupColor(BuildContext context, BudgetGroup g) => switch (g) {
      BudgetGroup.kebutuhan => context.colors.accent,
      BudgetGroup.keinginan => const Color(0xFFD97706),
      BudgetGroup.tabungan => context.colors.good,
      BudgetGroup.cicilan => const Color(0xFF0E7490),
      BudgetGroup.sedekah => const Color(0xFFBE185D),
    };

/// Template budget (P3f, Claude Design › Template budget): pilih template,
/// pemasukan, pratinjau per kelompok & kategori, lalu lanjut ke Atur budget.
class TemplateBudgetScreen extends ConsumerStatefulWidget {
  const TemplateBudgetScreen({super.key, required this.month});

  final DateTime month;

  @override
  ConsumerState<TemplateBudgetScreen> createState() => _TemplateBudgetScreenState();
}

class _TemplateBudgetScreenState extends ConsumerState<TemplateBudgetScreen> {
  bool _loaded = false;
  TemplateChoice _choice = const TemplateChoice();
  int _income = 0;
  int _incomeAverage = 0;
  List<TemplateCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppDatabase db = ref.read(appDatabaseProvider);
    final List<Category> cats = await db.categoriesDao.active(kind: TxKind.pengeluaran);
    final Map<int, int> avg = await db.transactionsDao.categoryAverages(widget.month);
    final int income = await db.transactionsDao.incomeAverage(widget.month);
    final TemplateChoice choice = TemplateChoice.decode(await db.settingsDao.read(SettingKeys.budgetTemplate));
    if (!mounted) return;
    setState(() {
      _categories = [for (final c in cats) (id: c.id, name: c.name, icon: c.icon, average: avg[c.id] ?? 0)];
      _choice = choice;
      _incomeAverage = income;
      _income = income > 0 ? (income ~/ _incomeStep) * _incomeStep : 5000000;
      _loaded = true;
    });
  }

  void _setChoice(TemplateChoice next) {
    setState(() => _choice = next);
    ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.budgetTemplate, next.encode());
  }

  void _bumpPercent(BudgetGroup g, int delta) {
    final Map<BudgetGroup, int> p = {..._choice.percents};
    p[g] = ((p[g] ?? 0) + delta).clamp(0, 100);
    _setChoice(TemplateChoice(template: _choice.template, custom: p, moved: _choice.moved));
  }

  void _move(TemplateCategory cat, BudgetGroup current) {
    final BudgetGroup next = nextSpendGroup(current, _choice.percents.keys);
    if (next == current) return;
    _setChoice(TemplateChoice(template: _choice.template, custom: _choice.custom, moved: {..._choice.moved, cat.id: next}));
  }

  void _continue(TemplatePlan plan, {required bool all}) {
    final Map<int, int> per = all ? plan.perCategory : plan.top(FreeLimits.categoryBudgets);
    final BudgetPreset preset = (
      total: plan.total,
      perCategory: per,
      note: all
          ? 'Diisi dari template ${_choice.template.label}. Ubah sesukamu sebelum disimpan.'
          : 'Diisi dari template ${_choice.template.label} (versi gratis: total + ${FreeLimits.categoryBudgets} kategori terbesar).',
      savings: plan.savings,
    );
    context.pushReplacement(
      Uri(path: Routes.aturBudget, queryParameters: {'month': DateFmt.monthKey(widget.month)}).toString(),
      extra: preset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool isPro = ref.watch(isProProvider);
    final Map<BudgetGroup, int> percents = _choice.percents;
    final int sum = percents.values.fold(0, (s, v) => s + v);
    final TemplatePlan plan = planTemplate(
      income: _income,
      percents: percents,
      categories: _categories,
      moved: _choice.moved,
    );
    final bool custom = _choice.template == BudgetTemplate.sendiri;
    final bool blocked = custom && sum != 100;
    final List<GoalWithDeposits> goals = [
      for (final g in ref.watch(goalsProvider).valueOrNull ?? const <GoalWithDeposits>[])
        if (g.active) g,
    ];
    final DateTime now = ref.watch(clockProvider)();
    final split = splitSavings(
      plan.savings,
      [for (final g in goals) (id: g.goal.id, name: g.goal.name, left: g.left, due: g.goal.dueDate)],
      now,
    );
    final List<String> top2 = [
      for (final id in plan.top(FreeLimits.categoryBudgets).keys) _categories.firstWhere((x) => x.id == id).name,
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            children: [
              const ScreenHeader(title: 'Template budget'),
              const SizedBox(height: AppSpace.x12),
              AppSegmentedControl<BudgetTemplate>(
                options: BudgetTemplate.values,
                selected: _choice.template,
                labelOf: (x) => x.label,
                onChanged: (x) => _setChoice(TemplateChoice(template: x, custom: _choice.custom, moved: _choice.moved)),
              ),
              const SizedBox(height: AppSpace.x12),
              Expanded(
                child: !_loaded
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Text(_choice.template.description, style: t.caption.copyWith(color: c.sub)),
                          const SizedBox(height: AppSpace.x12),
                          _IncomeCard(
                            income: _income,
                            fromAverage: _incomeAverage > 0 && _income == (_incomeAverage ~/ _incomeStep) * _incomeStep,
                            groups: plan.groups,
                            sum: custom ? sum : null,
                            onMinus: () => setState(() => _income = (_income - _incomeStep).clamp(_incomeStep, 1 << 40)),
                            onPlus: () => setState(() => _income += _incomeStep),
                          ),
                          for (final GroupPlan g in plan.groups) ...[
                            const SizedBox(height: AppSpace.x12),
                            _GroupCard(
                              plan: g,
                              editable: custom,
                              onMinus: () => _bumpPercent(g.group, -templatePercentStep),
                              onPlus: () => _bumpPercent(g.group, templatePercentStep),
                              onMove: (cat) => _move(cat, g.group),
                              savings: g.group == BudgetGroup.tabungan ? split : null,
                            ),
                          ],
                          const SizedBox(height: AppSpace.x12),
                          Text(
                            'Ketuk kategori untuk memindah kelompoknya. Batas per kategori dibagi sebanding kebiasaan '
                            '3 bulan terakhir, dan masih bisa diubah di langkah berikutnya.',
                            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
                          ),
                          const SizedBox(height: AppSpace.x12),
                        ],
                      ),
              ),
              if (_loaded) ...[
                if (!isPro) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: 10),
                    decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.mdAll),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(HiIcons.lock, size: 18, color: c.warnInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Versi gratis menyimpan total ${Rupiah.format(plan.total)} + ${FreeLimits.categoryBudgets} kategori '
                            'terbesar${top2.isEmpty ? '' : ' (${top2.join(' & ')})'}. Semua kategori tersimpan dengan Pro.',
                            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.ink, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x8),
                ],
                if (blocked)
                  const AppButton(label: 'Samakan total jadi 100%', onPressed: null)
                else if (isPro)
                  AppButton(
                    key: const Key('template-lanjut'),
                    label: 'Lanjut ke Atur budget',
                    large: true,
                    onPressed: () => _continue(plan, all: true),
                  )
                else ...[
                  _GoldButton(
                    label: 'Simpan semua kategori · Pro',
                    onTap: () => openPremium(context, ProReason.budget),
                  ),
                  const SizedBox(height: AppSpace.x8),
                  AppButton(
                    key: const Key('template-gratis'),
                    label: 'Simpan versi gratis',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _continue(plan, all: false),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.income,
    required this.fromAverage,
    required this.groups,
    required this.sum,
    required this.onMinus,
    required this.onPlus,
  });

  final int income;
  final bool fromAverage;
  final List<GroupPlan> groups;

  /// Total persen (template Sendiri); null untuk template tetap.
  final int? sum;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int total = groups.fold(0, (s, g) => s + g.percent);
    final int denom = total < 100 ? 100 : total;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.x16, 14, AppSpace.x16, 14),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pemasukan bulanan', style: t.caption.copyWith(color: c.muted)),
                    const SizedBox(height: AppSpace.x2),
                    Text(Rupiah.format(income), style: t.amountL.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
                    Text(
                      fromAverage ? 'Dari rata-rata pemasukan 3 bulan · bisa diubah' : 'Diubah manual',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                    ),
                  ],
                ),
              ),
              _StepButton(label: '−', semantic: 'Kurangi pemasukan 500 ribu', onTap: onMinus),
              const SizedBox(width: 6),
              _StepButton(label: '+', semantic: 'Tambah pemasukan 500 ribu', onTap: onPlus),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final (int i, GroupPlan g) in groups.indexed)
                    if (g.percent > 0)
                      Expanded(
                        flex: g.percent,
                        child: Container(
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                          color: groupColor(context, g.group),
                        ),
                      ),
                  if (denom > total) Expanded(flex: denom - total, child: Container(color: c.track)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x12),
          Wrap(
            spacing: AppSpace.x12,
            runSpacing: 6,
            children: [
              for (final GroupPlan g in groups)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: groupColor(context, g.group), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${g.group.label} ${g.percent}%', style: t.label.copyWith(color: c.sub)),
                  ],
                ),
            ],
          ),
          if (sum case final int s?) ...[
            const SizedBox(height: AppSpace.x12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
              decoration: BoxDecoration(color: s == 100 ? c.goodSoft : c.dangerSoft, borderRadius: AppRadius.smAll),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total $s%',
                        style: t.title.copyWith(fontSize: 13, color: s == 100 ? c.goodInk : c.danger)),
                  ),
                  Text(
                    s == 100 ? 'Pas' : (s > 100 ? 'Lebih ${s - 100}%' : 'Kurang ${100 - s}%'),
                    style: t.title.copyWith(fontSize: 13, color: s == 100 ? c.goodInk : c.danger),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.plan,
    required this.editable,
    required this.onMinus,
    required this.onPlus,
    required this.onMove,
    this.savings,
  });

  final GroupPlan plan;
  final bool editable;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<TemplateCategory> onMove;

  /// Kelompok Tabungan: saran setoran per target aktif.
  final List<({SavingGoal goal, int amount})>? savings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool isSaving = plan.group == BudgetGroup.tabungan;
    final String sub = isSaving
        ? 'Saran setoran ke Target tabungan · bukan batas belanja'
        : plan.items.isEmpty
            ? 'Belum ada kategori · tetap masuk total budget'
            : '${plan.items.length} kategori · dibagi sebanding kebiasaan';
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.x16, 14, AppSpace.x16, 6),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.x8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 28,
                  decoration: BoxDecoration(color: groupColor(context, plan.group), borderRadius: AppRadius.pillAll),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${plan.group.label} · ${plan.percent}%', style: t.title),
                      Text(sub, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                    ],
                  ),
                ),
                if (editable) ...[
                  _StepButton(label: '−', semantic: 'Kurangi ${plan.group.label} 5 persen', onTap: onMinus, size: 30),
                  const SizedBox(width: 4),
                  _StepButton(label: '+', semantic: 'Tambah ${plan.group.label} 5 persen', onTap: onPlus, size: 30),
                  const SizedBox(width: AppSpace.x8),
                ],
                Text(Rupiah.format(plan.amount), style: t.number.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (isSaving)
            if (savings == null || savings!.isEmpty)
              _Row(
                leading: Icon(HiIcons.piggy, size: 18, color: c.good),
                soft: c.goodSoft,
                title: 'Belum ada target aktif',
                hint: 'Buat target tabungan supaya saran setoran punya tujuan',
                amount: '',
                onTap: () => context.push(Routes.target),
              )
            else
              for (final s in savings!)
                _Row(
                  leading: Icon(HiIcons.piggy, size: 18, color: c.good),
                  soft: c.goodSoft,
                  title: s.goal.name,
                  hint: 'Sisa ${Rupiah.format(s.goal.left)}',
                  amount: Rupiah.format(s.amount),
                )
          else if (plan.items.isEmpty)
            _Row(
              leading: Icon(HiIcons.info, size: 18, color: c.muted),
              soft: c.chip,
              title: 'Belum ada kategori di sini',
              hint: 'Ketuk kategori di kelompok lain untuk memindahkannya ke ${plan.group.label}',
              amount: '',
            )
          else
            for (final TemplateItem i in plan.items)
              _Row(
                leading: GlyphIcon(i.category.icon, size: 18, color: c.accentText),
                soft: c.accentSoft,
                title: i.category.name,
                hint: i.category.average > 0 ? 'Rata-rata ${Rupiah.format(i.category.average)}' : 'Belum ada data',
                amount: Rupiah.format(i.amount),
                onTap: () => onMove(i.category),
                semantic: '${i.category.name}, ketuk untuk pindah kelompok',
              ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.soft,
    required this.title,
    required this.hint,
    required this.amount,
    this.onTap,
    this.semantic,
  });

  final Widget leading;
  final Color soft;
  final String title;
  final String hint;
  final String amount;
  final VoidCallback? onTap;
  final String? semantic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(11)),
            child: leading,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.item.copyWith(fontSize: 14)),
                Text(hint, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
          ),
          Text(amount, style: t.number.copyWith(fontSize: 14)),
        ],
      ),
    );
    if (onTap == null) return row;
    return Pressable(onTap: onTap, semanticLabel: semantic ?? title, child: row);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.semantic, required this.onTap, this.size = 36});

  final String label;
  final String semantic;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: semantic,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.smAll),
        child: Text(label, style: context.text.title.copyWith(fontSize: 18)),
      ),
    );
  }
}

/// Tombol emas "Simpan semua kategori · Pro" (desain Premium).
class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const Key('template-pro'),
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFFF6D27A), borderRadius: AppRadius.mdAll),
        child: Text(label, style: context.text.title.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1A1733))),
      ),
    );
  }
}
