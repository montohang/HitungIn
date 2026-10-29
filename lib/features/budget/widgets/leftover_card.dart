import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/data_providers.dart';
import '../../../core/db/providers.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glyph_icon.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../goals/data/goals_dao.dart';
import '../../goals/goals_provider.dart';
import '../../home/allowance_provider.dart';
import '../../settings/data/settings_dao.dart';
import '../../settings/widgets/settings_tile.dart' show showAppSheet;
import '../data/budget_template.dart';
import '../data/budgets_dao.dart';

/// Bulan (yyyy-mm) yang sisanya sudah diproses.
final leftoverDoneProvider = StreamProvider<String?>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.budgetLeftoverDone),
);

/// Target untuk "Setor ke target": yang paling butuh setoran per bulan.
SavingGoal? leftoverGoal(List<GoalWithDeposits> goals, DateTime now) {
  final split = splitSavings(
    1000000,
    [for (final g in goals) if (g.active) (id: g.goal.id, name: g.goal.name, left: g.left, due: g.goal.dueDate)],
    now,
  );
  if (split.isEmpty) return null;
  return (split.toList()..sort((a, b) => b.amount.compareTo(a.amount))).first.goal;
}

/// Terapkan pilihan sisa bulan [from] ke bulan [to]: bawa = penyesuaian batas
/// bulan [to], setor = setoran ke [goal], hangus = tidak diapa-apakan.
Future<({int carried, int deposited})> applyLeftovers(
  AppDatabase db, {
  required DateTime from,
  required DateTime to,
  required List<Leftover> items,
  required Map<int, LeftoverChoice> choices,
  SavingGoal? goal,
  int? walletId,
  required DateTime now,
}) async {
  final Map<int, int> carry = {
    for (final l in items)
      if (choices[l.categoryId] == LeftoverChoice.bawa) l.categoryId: l.left,
  };
  final int deposit = goal == null
      ? 0
      : items.where((l) => choices[l.categoryId] == LeftoverChoice.setor).fold(0, (s, l) => s + l.left);
  await db.budgetsDao.carryOver(to, carry);
  if (deposit > 0) await db.goalsDao.deposit(goal!.id, amount: deposit, at: now, walletId: walletId);
  await db.settingsDao.write(SettingKeys.budgetLeftoverDone, DateFmt.monthKey(from));
  return (carried: carry.values.fold(0, (s, v) => s + v), deposited: deposit);
}

/// Kartu "Sisa budget Oktober Rp420rb" di Budget, tanggal 1–5 bulan berjalan.
class LeftoverCard extends ConsumerWidget {
  const LeftoverCard({super.key, required this.month});

  /// Bulan berjalan (tanggal 1).
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider)();
    if (now.day > leftoverLastDay) return const SizedBox.shrink();
    final DateTime prev = DateTime(month.year, month.month - 1);
    final String? done = ref.watch(leftoverDoneProvider).valueOrNull;
    if (done == DateFmt.monthKey(prev)) return const SizedBox.shrink();
    final List<Leftover> items = leftovers(ref.watch(budgetProgressProvider(prev)).valueOrNull ?? const []);
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    final int total = items.fold(0, (s, l) => s + l.left);
    final String prevName = DateFmt.months[prev.month - 1];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x16),
      child: Pressable.card(
        key: const Key('sisa-budget'),
        onTap: () => _open(context, ref, prev, items),
        semanticLabel: 'Sisa budget $prevName ${Rupiah.format(total)}',
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x16),
          decoration: BoxDecoration(color: c.goodSoft, borderRadius: AppRadius.lgAll),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll),
                child: Icon(HiIcons.piggy, size: 20, color: c.good),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sisa budget $prevName ${Rupiah.format(total)}', style: t.title.copyWith(color: c.goodInk)),
                    const SizedBox(height: AppSpace.x2),
                    Text(
                      'Bawa ke ${DateFmt.months[month.month - 1]}, setor ke target, atau biarkan hangus · '
                      'pilih s.d. $leftoverLastDay ${DateFmt.monthsShort[month.month - 1]}',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.sub, height: 1.45),
                    ),
                  ],
                ),
              ),
              Icon(HiIcons.forward, size: 16, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, DateTime prev, List<Leftover> items) async {
    final DateTime now = ref.read(clockProvider)();
    final SavingGoal? goal = leftoverGoal(ref.read(goalsProvider).valueOrNull ?? const [], now);
    final Map<int, LeftoverChoice>? choices = await showAppSheet<Map<int, LeftoverChoice>>(
      context,
      title: 'Sisa budget ${DateFmt.months[prev.month - 1]}',
      aboveNav: true,
      builder: (_) => _LeftoverSheet(items: items, goal: goal, nextMonth: DateFmt.months[month.month - 1]),
    );
    if (choices == null || !context.mounted) return;
    final Set<int> excluded = ref.read(allowanceExcludedProvider).valueOrNull ?? const {};
    final int? walletId = (ref.read(walletBalancesProvider).valueOrNull ?? const [])
        .map((w) => w.wallet.id)
        .where((id) => !excluded.contains(id))
        .firstOrNull;
    final r = await applyLeftovers(
      ref.read(appDatabaseProvider),
      from: prev,
      to: month,
      items: items,
      choices: choices,
      goal: goal,
      walletId: walletId,
      now: now,
    );
    if (!context.mounted) return;
    final List<String> parts = [
      if (r.carried > 0) '${Rupiah.format(r.carried)} dibawa',
      if (r.deposited > 0) '${Rupiah.format(r.deposited)} disetor ke ${goal!.name}',
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(parts.isEmpty ? 'Sisa bulan lalu dibiarkan hangus' : 'Tersimpan · ${parts.join(', ')}')));
  }
}

class _LeftoverSheet extends StatefulWidget {
  const _LeftoverSheet({required this.items, required this.goal, required this.nextMonth});

  final List<Leftover> items;
  final SavingGoal? goal;
  final String nextMonth;

  @override
  State<_LeftoverSheet> createState() => _LeftoverSheetState();
}

class _LeftoverSheetState extends State<_LeftoverSheet> {
  late final Map<int, LeftoverChoice> _choice = {
    for (final l in widget.items) l.categoryId: LeftoverChoice.bawa,
  };

  List<LeftoverChoice> get _options => [
        LeftoverChoice.bawa,
        if (widget.goal != null) LeftoverChoice.setor,
        LeftoverChoice.hangus,
      ];

  int _sum(LeftoverChoice k) => widget.items.where((l) => _choice[l.categoryId] == k).fold(0, (s, l) => s + l.left);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final String summary = [
      'Dibawa ke ${widget.nextMonth} ${Rupiah.format(_sum(LeftoverChoice.bawa))}',
      if (widget.goal != null) 'disetor ke ${widget.goal!.name} ${Rupiah.format(_sum(LeftoverChoice.setor))}',
      'hangus ${Rupiah.format(_sum(LeftoverChoice.hangus))}',
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.goal == null
              ? 'Hemat di bulan lalu tetap terasa. Belum ada target aktif, jadi sisa bisa dibawa atau dibiarkan hangus.'
              : 'Hemat di bulan lalu tetap terasa. Pilih untuk tiap kategori, atau sekaligus.',
          style: t.caption.copyWith(color: c.sub),
        ),
        const SizedBox(height: AppSpace.x12),
        Row(
          children: [
            for (final (int i, LeftoverChoice k) in _options.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Pressable(
                  onTap: () => setState(() {
                    for (final l in widget.items) {
                      _choice[l.categoryId] = k;
                    }
                  }),
                  semanticLabel: '${k == LeftoverChoice.setor ? 'Setor' : k.label} semua',
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: AppRadius.pillAll,
                      border: Border.all(color: c.line),
                    ),
                    child: Text('${k == LeftoverChoice.setor ? 'Setor' : k.label} semua',
                        style: t.label.copyWith(color: c.ink)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.x8),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final Leftover l in widget.items)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(11)),
                              child: GlyphIcon(l.icon, size: 18, color: c.accentText),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(l.name, style: t.item.copyWith(fontSize: 14))),
                            Text(Rupiah.format(l.left), style: t.number.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: AppSpace.x8),
                        AppSegmentedControl<LeftoverChoice>(
                          options: _options,
                          selected: _choice[l.categoryId]!,
                          labelOf: (k) => k.label,
                          onSurface: true,
                          onChanged: (k) => setState(() => _choice[l.categoryId] = k),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(top: AppSpace.x12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
          child: Text(summary, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.sub, height: 1.5)),
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(
          key: const Key('simpan-sisa'),
          label: 'Simpan pilihan',
          onPressed: () => Navigator.of(context).pop(Map<int, LeftoverChoice>.from(_choice)),
        ),
        const SizedBox(height: AppSpace.x8),
        Text(
          'Yang belum dipilih sampai tanggal $leftoverLastDay dianggap hangus.',
          textAlign: TextAlign.center,
          style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
        ),
      ],
    );
  }
}

/// Tawaran pindah batas di bawah kategori yang lewat batas (bulan berjalan).
class MoveOfferCard extends ConsumerStatefulWidget {
  const MoveOfferCard({super.key, required this.over, required this.all, required this.month});

  final BudgetProgress over;
  final List<BudgetProgress> all;
  final DateTime month;

  @override
  ConsumerState<MoveOfferCard> createState() => _MoveOfferCardState();
}

class _MoveOfferCardState extends ConsumerState<MoveOfferCard> {
  int _donor = 0;

  @override
  Widget build(BuildContext context) {
    final MoveOffer? offer = moveOffer(widget.over, widget.all);
    if (offer == null) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    final BudgetProgress donor = offer.donors[_donor % offer.donors.length];
    final int excess = widget.over.spent - widget.over.budget.limitAmount;
    final String monthName = DateFmt.months[widget.month.month - 1];
    return Container(
      key: Key('pindah-batas-${widget.over.category!.id}'),
      margin: const EdgeInsets.only(left: 52, bottom: AppSpace.x8),
      padding: const EdgeInsets.all(AppSpace.x12),
      decoration: BoxDecoration(color: c.dangerSoft, borderRadius: AppRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Lewat '),
              TextSpan(text: Rupiah.format(excess), style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: '. Ambil '),
              TextSpan(text: Rupiah.format(offer.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(
                text: ' dari ${donor.category!.name} (masih sisa ${Rupiah.format(donor.budget.limitAmount - donor.spent)})? '
                    'Berlaku $monthName saja.',
              ),
            ]),
            style: t.caption.copyWith(color: c.ink, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SmallButton(
                key: const Key('ambil-batas'),
                label: 'Ambil ${Rupiah.format(offer.amount)}',
                primary: true,
                onTap: () => _take(donor, offer.amount),
              ),
              if (offer.donors.length > 1) ...[
                const SizedBox(width: AppSpace.x8),
                _SmallButton(label: 'Kategori lain', onTap: () => setState(() => _donor++)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _take(BudgetProgress donor, int amount) async {
    final BudgetsDao dao = ref.read(appDatabaseProvider).budgetsDao;
    final String to = widget.over.category!.name;
    await dao.moveLimit(widget.month, from: donor.category!.id, to: widget.over.category!.id, amount: amount);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Batas $to +${Rupiah.format(amount)}, ${donor.category!.name} −${Rupiah.format(amount)} · '
            '${DateFmt.months[widget.month.month - 1]} saja'),
        action: SnackBarAction(label: 'Urungkan', onPressed: () => dao.undoLastMove(widget.month)),
      ));
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({super.key, required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? c.accent : c.surface,
          borderRadius: AppRadius.smAll,
          border: primary ? null : Border.all(color: c.line),
        ),
        child: Text(label, style: context.text.label.copyWith(fontSize: 13, color: primary ? c.onAccent : c.ink)),
      ),
    );
  }
}
