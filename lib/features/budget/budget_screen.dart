import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/month_switcher.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import 'data/budgets_dao.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _month = ref.read(currentMonthProvider);

  Future<void> _edit({BudgetProgress? existing, required List<BudgetProgress> all}) async {
    final List<Category> expense = [
      for (final c in ref.read(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        if (c.kind == TxKind.pengeluaran) c,
    ];
    final Set<int?> taken = {for (final b in all) b.budget.categoryId};
    final bool categoryAllowed = existing != null ||
        FreeLimits.canAddCategoryBudget(existing: all.where((b) => b.category != null).length, isPro: ref.read(isProProvider));
    // Budget total sudah ada & kuota kategori habis → langsung tawarkan Pro.
    if (existing == null && taken.contains(null) && !categoryAllowed) {
      openPremium(context, ProReason.budget);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(
        existing: existing,
        categories: categoryAllowed
            ? [for (final c in expense) if (!taken.contains(c.id) || c.id == existing?.budget.categoryId) c]
            : const [],
        categoryLocked: !categoryAllowed,
        totalTaken: taken.contains(null) && !(existing != null && existing.category == null),
        onSave: (categoryId, amount) =>
            ref.read(appDatabaseProvider).budgetsDao.setLimit(categoryId: categoryId, limitAmount: amount),
        onDelete: existing == null ? null : () => ref.read(appDatabaseProvider).budgetsDao.remove(existing.budget.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<BudgetProgress>> async = ref.watch(budgetProgressProvider(_month));
    final List<BudgetProgress> all = async.valueOrNull ?? const [];
    final BudgetProgress? total = all.where((b) => b.category == null).firstOrNull;
    final List<BudgetProgress> perCategory = [for (final b in all) if (b.category != null) b];

    final bool isCurrent = _month.year == now.year && _month.month == now.month;
    final int daysLeft = isCurrent ? DateTime(now.year, now.month + 1, 0).day - now.day + 1 : 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Row(
              children: [
                Expanded(child: Text('Budget', style: t.pageTitle)),
                if (all.isNotEmpty)
                  AppButton(
                    label: 'Tambah',
                    icon: Icons.add,
                    variant: AppButtonVariant.soft,
                    expand: false,
                    onPressed: () => _edit(all: all),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.block),
            MonthSwitcher(month: _month, now: now, onChanged: (m) => setState(() => _month = m)),
            const SizedBox(height: AppSpace.block),
            if (async.hasValue && all.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'Belum ada budget',
                  body: 'Pasang batas belanja bulanan — total atau per kategori. HitungIn akan memberi tanda saat mendekati batas.',
                  action: 'Atur budget',
                  onAction: () => _edit(all: all),
                ),
              ),
            if (total != null) ...[
              _BudgetCard(progress: total, daysLeft: daysLeft, hero: true, onTap: () => _edit(existing: total, all: all)),
              const SizedBox(height: AppSpace.x24),
            ],
            if (perCategory.isNotEmpty) ...[
              const SectionHeader('Per kategori'),
              for (final (int i, BudgetProgress b) in perCategory.indexed) ...[
                _BudgetCard(progress: b, daysLeft: daysLeft, delay: AppMotion.stagger * i, onTap: () => _edit(existing: b, all: all)),
                const SizedBox(height: AppSpace.x8),
              ],
            ],
            if (total == null && perCategory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.x8),
                child: Text('Tip: tambahkan budget total untuk melihat batas seluruh pengeluaran.',
                    style: t.caption.copyWith(color: c.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress, required this.daysLeft, required this.onTap, this.hero = false, this.delay = Duration.zero});

  final BudgetProgress progress;
  final int daysLeft;
  final VoidCallback onTap;
  final bool hero;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int limit = progress.budget.limitAmount;
    final int spent = progress.spent;
    final int left = limit - spent;
    final double ratio = spent / limit;
    final BudgetLevel level = budgetLevelOf(ratio);
    final String name = progress.category?.name ?? 'Total pengeluaran';

    final String status = switch (level) {
      BudgetLevel.over => 'Lewat ${Rupiah.format(-left)}',
      _ when daysLeft > 0 => 'Sisa ${Rupiah.format(left)} · ${Rupiah.compact(left ~/ daysLeft)}/hari',
      _ => 'Sisa ${Rupiah.format(left)}',
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: progress.category == null ? Icons.savings_outlined : AppIcons.of(progress.category!.icon), size: 40),
              const SizedBox(width: AppSpace.x12),
              Expanded(child: Text(name, style: hero ? t.section : t.item)),
              if (level != BudgetLevel.normal)
                AppBadge(
                  level == BudgetLevel.over ? 'Lewat batas' : 'Hati-hati',
                  background: level == BudgetLevel.over ? c.dangerSoft : c.warnSoft,
                  foreground: level == BudgetLevel.over ? c.danger : c.warnInk,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Rupiah.format(spent), style: hero ? t.amountL : t.number),
              Expanded(
                child: Text(' / ${Rupiah.format(limit)}', style: t.caption.copyWith(color: c.muted)),
              ),
              Text('${(ratio * 100).round()}%', style: t.number.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          AppProgressBar(value: ratio, delay: delay),
          const SizedBox(height: AppSpace.x8),
          Text(status, style: t.caption.copyWith(color: level == BudgetLevel.over ? c.danger : c.muted)),
        ],
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({
    required this.categories,
    required this.totalTaken,
    required this.onSave,
    this.categoryLocked = false,
    this.existing,
    this.onDelete,
  });

  final BudgetProgress? existing;
  final List<Category> categories;

  /// Budget total sudah ada (dan bukan yang sedang diubah).
  final bool totalTaken;

  /// Kuota budget kategori versi gratis sudah terpakai.
  final bool categoryLocked;
  final Future<void> Function(int? categoryId, int amount) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null ? '' : Rupiah.digits(widget.existing!.budget.limitAmount),
  );
  // -1 = belum dipilih, null = total.
  late int? _target = widget.existing != null
      ? widget.existing!.budget.categoryId
      : (widget.totalTaken ? -1 : null);
  String? _error;

  Future<void> _save() async {
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (_target == -1) return setState(() => _error = 'Pilih kategori.');
    if (amount <= 0) return setState(() => _error = 'Isi batasnya dulu.');
    await widget.onSave(_target, amount);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(editing ? 'Ubah budget' : 'Atur budget', style: t.screenTitle),
              const SizedBox(height: AppSpace.x16),
              if (!editing) ...[
                Text('Untuk', style: t.label.copyWith(color: c.muted)),
                const SizedBox(height: AppSpace.x8),
                Wrap(
                  spacing: AppSpace.x8,
                  runSpacing: AppSpace.x8,
                  children: [
                    if (!widget.totalTaken)
                      AppChip(label: 'Total pengeluaran', icon: Icons.savings_outlined, selected: _target == null, onTap: () => setState(() => _target = null)),
                    for (final cat in widget.categories)
                      AppChip(
                        label: cat.name,
                        icon: AppIcons.of(cat.icon),
                        selected: _target == cat.id,
                        onTap: () => setState(() => _target = cat.id),
                      ),
                  ],
                ),
                if (widget.categoryLocked) ...[
                  const SizedBox(height: AppSpace.x12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Versi gratis: ${FreeLimits.categoryBudgets} budget kategori. Tambah lagi dengan Pro.',
                          style: t.caption.copyWith(color: c.muted),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          openPremium(context, ProReason.budget);
                        },
                        child: const Text('Lihat Pro'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.x16),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x16),
                  child: Text(widget.existing!.category?.name ?? 'Total pengeluaran', style: t.item),
                ),
              TextField(
                key: const Key('batas-budget'),
                controller: _amount,
                autofocus: editing,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                style: t.number,
                decoration: const InputDecoration(
                  labelText: 'Batas per bulan',
                  prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.x8),
                Text(_error!, style: t.caption.copyWith(color: c.danger)),
              ],
              const SizedBox(height: AppSpace.x16),
              AppButton(label: 'Simpan', large: true, onPressed: _save),
              if (widget.onDelete != null) ...[
                const SizedBox(height: AppSpace.x8),
                AppButton(
                  label: 'Hapus budget',
                  variant: AppButtonVariant.danger,
                  onPressed: () async {
                    await widget.onDelete!();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
