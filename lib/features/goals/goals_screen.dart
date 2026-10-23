import 'dart:math' as math;

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
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../home/allowance_provider.dart' show allowanceExcludedProvider;
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import '../wallets/data/wallets_dao.dart' show WalletBalance;
import 'data/goals.dart';
import 'data/goals_dao.dart';
import 'goals_provider.dart';

/// Isian dari Catat cepat ("nabung 100rb dana darurat").
typedef GoalDraft = ({String name, int? amount, int? walletId});

String goalDraftLink(GoalDraft d) => Uri(path: Routes.target, queryParameters: {
      'setor': '1',
      if (d.name.isNotEmpty) 'nama': d.name,
      if (d.amount != null) 'nominal': '${d.amount}',
      if (d.walletId != null) 'dompet': '${d.walletId}',
    }).toString();

GoalDraft? goalDraftFrom(Map<String, String> q) => q['setor'] != '1'
    ? null
    : (name: q['nama'] ?? '', amount: int.tryParse(q['nominal'] ?? ''), walletId: int.tryParse(q['dompet'] ?? ''));

/// Target belum diarsipkan & belum tercapai yang cocok dengan [name]. Nama
/// kosong + hanya satu target aktif → target itu.
GoalWithDeposits? findGoal(List<GoalWithDeposits> all, String name) {
  final List<GoalWithDeposits> open = [for (final g in all) if (g.active) g];
  final String n = name.trim().toLowerCase();
  if (n.isEmpty) return open.length == 1 ? open.single : null;
  return open.where((g) => g.goal.name.toLowerCase() == n).firstOrNull ??
      open.where((g) => g.goal.name.toLowerCase().startsWith(n)).firstOrNull ??
      open.where((g) => g.goal.name.toLowerCase().contains(n) || n.contains(g.goal.name.toLowerCase())).firstOrNull;
}

/// Dompet yang ikut Jatah (untuk keterangan "disisihkan").
final _countedWalletsProvider = Provider<Set<int>>((ref) {
  final List<WalletBalance> ws = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
  final Set<int> excluded = ref.watch(allowanceExcludedProvider).valueOrNull ?? const {};
  return {for (final w in ws) if (!excluded.contains(w.wallet.id)) w.wallet.id};
});

/// Buka form target baru, atau lembar Premium bila batas versi gratis tercapai.
Future<void> openNewGoal(BuildContext context, WidgetRef ref) async {
  final List<GoalWithDeposits> all = ref.read(goalsProvider).valueOrNull ?? const [];
  final int active = all.where((g) => g.active).length;
  if (!FreeLimits.canAddGoal(active: active, isPro: ref.read(isProProvider))) {
    await showAppSheet<void>(context, title: 'Mau menabung untuk lebih dari satu hal?', builder: (_) => const _ProSheet());
    return;
  }
  await openGoalForm(context);
}

/// Target tabungan (P3b, Claude Design › Target tabungan).
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key, this.draft, this.openNew = false});

  final GoalDraft? draft;
  final bool openNew;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final GoalDraft? draft = widget.draft;
      if (widget.openNew) {
        await openNewGoal(context, ref);
      } else if (draft != null) {
        final List<GoalWithDeposits> all = await ref.read(appDatabaseProvider).goalsDao.watchAll().first;
        if (!mounted) return;
        final GoalWithDeposits? g = findGoal(all, draft.name);
        if (g == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(all.where((x) => x.active).isEmpty
                ? 'Belum ada target tabungan. Buat dulu, lalu sisihkan.'
                : draft.name.isEmpty
                    ? 'Sebutkan targetnya, mis. "nabung 100rb dana darurat"'
                    : 'Tidak ada target "${draft.name}"'),
          ));
          return;
        }
        await openDepositSheet(context, g, amount: draft.amount, walletId: draft.walletId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<GoalWithDeposits>> async = ref.watch(goalsProvider);
    final List<GoalWithDeposits> all = async.valueOrNull ?? const [];
    final List<GoalWithDeposits> active = [for (final g in all) if (g.active) g];
    final List<GoalWithDeposits> done = [for (final g in all) if (!g.goal.archived && g.goal.achievedAt != null) g]
      ..sort((a, b) => b.goal.achievedAt!.compareTo(a.goal.achievedAt!));
    final List<GoalWithDeposits> archived = [for (final g in all) if (g.goal.archived) g];
    final Set<int> counted = ref.watch(_countedWalletsProvider);
    final List<GoalWithDeposits> held = [for (final g in all) if (!g.goal.archived) g];
    final int total = held.fold(0, (s, g) => s + g.saved);
    final int fromJatah = setAsideFrom(held.map((g) => g.facts), counted);
    final bool isPro = ref.watch(isProProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: 'Target tabungan',
              large: true,
              trailing: Pressable(
                onTap: () => openNewGoal(context, ref),
                semanticLabel: 'Buat target baru',
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                  child: Text('+ Target', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            if (all.isEmpty && !async.isLoading)
              _Empty(onCreate: () => openNewGoal(context, ref))
            else ...[
              _TotalHero(total: total, fromJatah: fromJatah),
              const SizedBox(height: AppSpace.x16),
              if (active.isNotEmpty) ...[
                const _SectionLabel('Aktif'),
                for (final g in active) ...[
                  _GoalCard(g: g, now: now),
                  const SizedBox(height: AppSpace.x12),
                ],
              ],
              if (!isPro && active.isNotEmpty) ...[
                Pressable.card(
                  onTap: () => openPremium(context, ProReason.target),
                  semanticLabel: 'Premium untuk target tanpa batas',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12 + 2),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        const AppBadge.pro(),
                        const SizedBox(width: AppSpace.x12),
                        Expanded(
                          child: Text(
                            'Versi gratis: 1 target aktif. Premium untuk menabung beberapa target sekaligus.',
                            style: t.caption.copyWith(color: c.sub),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.x12),
              ],
              if (done.isNotEmpty) ...[
                const _SectionLabel('Tercapai'),
                for (final g in done) ...[
                  _DoneRow(g: g, now: now),
                  const SizedBox(height: AppSpace.x8),
                ],
              ],
              if (archived.isNotEmpty) ...[
                const _SectionLabel('Diarsipkan'),
                for (final g in archived) ...[
                  _DoneRow(g: g, now: now),
                  const SizedBox(height: AppSpace.x8),
                ],
              ],
              const SizedBox(height: AppSpace.x8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                child: Text(
                  'Setoran tidak tercatat sebagai pengeluaran di Laporan dan tidak mengubah saldo dompet.',
                  textAlign: TextAlign.center,
                  style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.x4, AppSpace.x4, AppSpace.x4, AppSpace.x8),
        child: Text(text, style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: context.colors.sub)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x24),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(HiIcons.piggy, size: 30, color: c.accent),
          ),
          const SizedBox(height: AppSpace.x16),
          Text('Menabung untuk apa?', style: t.section),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Dana darurat, liburan, atau HP baru. Uangnya tetap di dompetmu — HitungIn menyisihkannya dari Jatah hari ini supaya tidak ikut terpakai.',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: c.sub, height: 1.5),
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Buat target pertama', large: true, onPressed: onCreate),
        ],
      ),
    );
  }
}

class _TotalHero extends StatelessWidget {
  const _TotalHero({required this.total, required this.fromJatah});

  final int total;
  final int fromJatah;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(colors: [c.card, Color.lerp(c.card, c.accent, 0.6)!]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total disisihkan', style: t.caption.copyWith(color: c.onCardMuted)),
          const SizedBox(height: AppSpace.x4),
          Text(Rupiah.format(total), style: t.amountL.copyWith(color: c.onCard, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpace.x4),
          Text(
            'Uangnya tetap di dompet. ${fromJatah > 0 ? '${Rupiah.compact(fromJatah)} dari dompet yang dihitung Jatah tidak ikut dibelanjakan.' : 'Tidak ada yang dipotong dari Jatah hari ini.'}',
            style: t.caption.copyWith(color: c.onCardMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _GoalEmoji extends StatelessWidget {
  const _GoalEmoji(this.emoji, {this.size = 44, this.done = false});

  final String emoji;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? context.colors.goodSoft : context.colors.accentSoft,
          borderRadius: AppRadius.smAll,
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.g, required this.now});

  final GoalWithDeposits g;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable.card(
      onTap: () => context.push(Routes.targetDetail(g.goal.id)),
      semanticLabel: '${g.goal.name}, ${g.percent} persen',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoalEmoji(g.goal.emoji),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(g.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title)),
                      Text('${g.percent}%', style: t.number),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x8),
                  AppProgressBar(value: g.saved / g.goal.target, height: 8, autoLevel: false, color: c.accent),
                  const SizedBox(height: AppSpace.x8),
                  Text('${Rupiah.compact(g.saved)} dari ${Rupiah.compact(g.goal.target)}',
                      style: t.caption.copyWith(color: c.sub)),
                  Text(goalEstimateText(g.estimate(now), now: now),
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.g, required this.now});

  final GoalWithDeposits g;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime? at = g.goal.achievedAt;
    return Pressable.card(
      onTap: () => context.push(Routes.targetDetail(g.goal.id)),
      semanticLabel: g.goal.name,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
        child: Row(
          children: [
            _GoalEmoji(g.goal.emoji, size: 36, done: at != null),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.item),
                  Text(
                    at != null
                        ? '${Rupiah.format(g.goal.target)} · tercapai ${DateFmt.date(at, now: now)}'
                        : '${Rupiah.format(g.saved)} dari ${Rupiah.format(g.goal.target)}',
                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                  ),
                ],
              ),
            ),
            if (at != null) Icon(HiIcons.check, size: 18, color: c.good),
          ],
        ),
      ),
    );
  }
}

/// Detail satu target: progres, setor/ambil, pengingat, riwayat.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<GoalWithDeposits>> async = ref.watch(goalsProvider);
    final GoalWithDeposits? g = (async.valueOrNull ?? const <GoalWithDeposits>[]).where((x) => x.goal.id == id).firstOrNull;
    if (g == null) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: AppSpace.screen,
            children: [
              const ScreenHeader(title: 'Target', large: true),
              if (!async.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.x32),
                  child: Text('Target ini sudah dihapus.', textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted)),
                ),
            ],
          ),
        ),
      );
    }
    final Goal goal = g.goal;
    final Map<int, String> walletNames = {
      for (final WalletBalance w in ref.watch(walletBalancesProvider).valueOrNull ?? const <WalletBalance>[])
        w.wallet.id: w.wallet.name,
    };
    final List<GoalDeposit> history = g.deposits.reversed.toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: goal.name,
              large: true,
              trailing: Pressable(
                onTap: () => showAppSheet<void>(context, title: goal.name, builder: (_) => _GoalMenu(g: g)),
                semanticLabel: 'Ubah atau arsipkan target',
                child: Container(
                  width: AppSpace.touch,
                  height: AppSpace.touch,
                  decoration: BoxDecoration(
                      color: c.surface, borderRadius: AppRadius.smAll, border: Border.all(color: c.line)),
                  child: Icon(HiIcons.dots, size: 20, color: c.ink),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.x16, AppSpace.x20, AppSpace.x16, AppSpace.x16),
              decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
              child: Column(
                children: [
                  GoalRing(value: g.saved / goal.target, emoji: goal.emoji, percent: g.percent),
                  const SizedBox(height: AppSpace.x12),
                  Text(Rupiah.format(g.saved), style: t.amountL.copyWith(fontWeight: FontWeight.w800)),
                  Text('dari ${Rupiah.format(goal.target)} · sisa ${Rupiah.format(g.left)}',
                      style: t.caption.copyWith(color: c.muted)),
                  const SizedBox(height: AppSpace.x12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
                    decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
                    child: Text(
                      g.reached ? 'Target sudah tercapai — saatnya merayakan!' : goalEstimateText(g.estimate(now), now: now),
                      textAlign: TextAlign.center,
                      style: t.caption.copyWith(color: c.sub),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  if (g.reached)
                    AppButton(
                      label: 'Rayakan',
                      large: true,
                      onPressed: () => context.push(Routes.targetTercapai(goal.id)),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: 'Tambah setoran',
                            large: true,
                            onPressed: () => openDepositSheet(context, g),
                          ),
                        ),
                        const SizedBox(width: AppSpace.x8),
                        Expanded(
                          child: AppButton(
                            label: 'Ambil',
                            large: true,
                            variant: AppButtonVariant.outline,
                            onPressed: g.saved > 0 ? () => openDepositSheet(context, g, take: true) : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!g.reached && !goal.archived) ...[
              const SizedBox(height: AppSpace.x12),
              _ReminderTile(goal: goal),
            ],
            const SizedBox(height: AppSpace.x16),
            Row(
              children: [
                Expanded(child: Text('Riwayat setoran', style: t.section)),
                Text('${history.length} catatan', style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
            const SizedBox(height: AppSpace.x8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
              decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
              child: history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.x24),
                      child: Text('Belum ada setoran', textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted)),
                    )
                  : Column(
                      children: [
                        for (final (int i, GoalDeposit d) in history.indexed)
                          _DepositRow(
                            d: d,
                            now: now,
                            wallet: d.walletId == null ? null : walletNames[d.walletId],
                            last: i == history.length - 1,
                          ),
                      ],
                    ),
            ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x8),
              Text('Tahan satu baris untuk menghapusnya.',
                  textAlign: TextAlign.center, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cincin progres dengan emoji & persen di tengah.
class GoalRing extends StatelessWidget {
  const GoalRing({super.key, required this.value, required this.emoji, required this.percent, this.size = 168});

  final double value;
  final String emoji;
  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: context.reduceMotion ? Duration.zero : AppMotion.fill,
      curve: AppMotion.easeOut,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value: v, track: c.track, color: c.accent),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: size * 0.18)),
                Text('$percent%', style: t.amountL.copyWith(fontSize: size * 0.155, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 14;
    final Rect r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(r, 0, math.pi * 2, false, base);
    if (value > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false,
          base
            ..color = color
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class _DepositRow extends ConsumerWidget {
  const _DepositRow({required this.d, required this.now, required this.wallet, required this.last});

  final GoalDeposit d;
  final DateTime now;
  final String? wallet;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool take = d.amount < 0;
    final String meta = [take ? 'Ambil' : 'Setoran', if (wallet != null) wallet!].join(' · ');
    return Pressable(
      onLongPress: () async {
        final bool ok = await confirmDialog(
          context,
          title: 'Hapus ${take ? 'pengambilan' : 'setoran'} ${Rupiah.format(d.amount.abs())}?',
          body: take ? 'Terkumpul bertambah lagi.' : 'Terkumpul berkurang. Saldo dompet tidak berubah.',
          confirm: 'Hapus',
          danger: true,
        );
        if (ok) await ref.read(appDatabaseProvider).goalsDao.removeDeposit(d.id);
      },
      semanticLabel: '${DateFmt.date(d.at, now: now)}, $meta ${Rupiah.format(d.amount.abs())}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFmt.relativeDay(d.at, now: now), style: t.item.copyWith(fontSize: 14)),
                  Text(meta, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                ],
              ),
            ),
            Text(Rupiah.format(d.amount, signed: true), style: t.number.copyWith(color: take ? c.sub : c.good)),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final String when = 'Setiap ${DateFmt.weekdays[goal.remindWeekday - 1]} pukul ${goal.remindHour.toString().padLeft(2, '0')}.00';
    return Pressable.card(
      onTap: () => showAppSheet<void>(context, title: 'Pengingat setoran', builder: (_) => _ReminderSheet(goal: goal)),
      semanticLabel: 'Pengingat setoran, ${goal.remind ? when : 'mati'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(HiIcons.bell, size: 18, color: c.accent),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengingat setoran', style: t.item),
                  Text(goal.remind ? when : 'Mati · nyalakan untuk diingatkan tiap minggu',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                ],
              ),
            ),
            Switch.adaptive(
              value: goal.remind,
              activeTrackColor: c.accent,
              onChanged: (v) => ref.read(appDatabaseProvider).goalsDao.setReminder(goal.id, on: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late int _day = widget.goal.remindWeekday;
  late int _hour = widget.goal.remindHour;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifikasi mingguan untuk menyisihkan ke ${widget.goal.name}.', style: t.caption.copyWith(color: c.sub)),
        const FieldLabel('Hari'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (int d = 1; d <= 7; d++)
              AppChip(label: DateFmt.weekdays[d - 1], selected: _day == d, onTap: () => setState(() => _day = d)),
          ],
        ),
        const FieldLabel('Jam'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final int h in const [7, 9, 12, 17, 19, 21])
              AppChip(label: '${h.toString().padLeft(2, '0')}.00', selected: _hour == h, onTap: () => setState(() => _hour = h)),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Nyalakan pengingat',
          large: true,
          onPressed: () async {
            await ref.read(appDatabaseProvider).goalsDao.setReminder(widget.goal.id, on: true, weekday: _day, hour: _hour);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _GoalMenu extends ConsumerWidget {
  const _GoalMenu({required this.g});

  final GoalWithDeposits g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Goal goal = g.goal;
    final GoalsDao dao = ref.read(appDatabaseProvider).goalsDao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Ubah target',
          variant: AppButtonVariant.outline,
          onPressed: () {
            Navigator.pop(context);
            openGoalForm(context, existing: goal);
          },
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(
          label: goal.archived ? 'Aktifkan lagi' : 'Arsipkan',
          variant: AppButtonVariant.outline,
          onPressed: () async {
            final NavigatorState nav = Navigator.of(context);
            if (goal.archived && !g.reached) {
              final int active = (ref.read(goalsProvider).valueOrNull ?? const []).where((x) => x.active).length;
              if (!FreeLimits.canAddGoal(active: active, isPro: ref.read(isProProvider))) {
                nav.pop();
                openPremium(nav.context, ProReason.target);
                return;
              }
            }
            if (!goal.archived) {
              final bool ok = await confirmDialog(
                context,
                title: 'Arsipkan ${goal.name}?',
                body: 'Target disimpan di bagian Diarsipkan. Uangnya tidak lagi disisihkan dari Jatah hari ini.',
                confirm: 'Arsipkan',
              );
              if (!ok) return;
            }
            await dao.setArchived(goal.id, !goal.archived);
            nav.pop();
          },
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(
          label: 'Hapus',
          variant: AppButtonVariant.danger,
          onPressed: () async {
            final bool ok = await confirmDialog(
              context,
              title: 'Hapus ${goal.name}?',
              body: 'Target dan riwayat setorannya dihapus. Saldo dompet tidak berubah.',
              confirm: 'Hapus',
              danger: true,
            );
            if (!ok || !context.mounted) return;
            final GoRouter router = GoRouter.of(context);
            Navigator.pop(context);
            await dao.remove(goal.id);
            if (router.canPop()) router.pop();
          },
        ),
      ],
    );
  }
}

/// Lembar Tambah setoran / Ambil.
Future<void> openDepositSheet(BuildContext context, GoalWithDeposits g, {bool take = false, int? amount, int? walletId}) =>
    showAppSheet<void>(
      context,
      title: g.goal.name,
      builder: (_) => _DepositSheet(g: g, take: take, amount: amount, walletId: walletId),
    );

class _DepositSheet extends ConsumerStatefulWidget {
  const _DepositSheet({required this.g, required this.take, this.amount, this.walletId});

  final GoalWithDeposits g;
  final bool take;
  final int? amount;
  final int? walletId;

  @override
  ConsumerState<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<_DepositSheet> {
  late bool _take = widget.take;
  late final TextEditingController _amount =
      TextEditingController(text: widget.amount == null ? '' : Rupiah.digits(widget.amount!));
  int? _walletId;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Bawaan: dompet setoran terakhir, lalu dompet pertama yang dihitung Jatah.
    _walletId = widget.walletId ?? widget.g.deposits.lastWhereOrNull((d) => d.walletId != null)?.walletId;
    if (_walletId == null) {
      final List<WalletBalance> ws = ref.read(walletBalancesProvider).valueOrNull ?? const [];
      final Set<int> counted = ref.read(_countedWalletsProvider);
      _walletId = (ws.where((w) => counted.contains(w.wallet.id)).firstOrNull ?? ws.firstOrNull)?.wallet.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final GoalWithDeposits g = widget.g;
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (amount <= 0) return setState(() => _error = 'Isi nominalnya.');
    if (_take && amount > g.saved) return setState(() => _error = 'Melebihi yang terkumpul ${Rupiah.format(g.saved)}.');
    final GoalsDao dao = ref.read(appDatabaseProvider).goalsDao;
    final DateTime now = ref.read(clockProvider)();
    final int after = _take
        ? await dao.withdraw(g.goal.id, amount: amount, at: now, walletId: _walletId)
        : await dao.deposit(g.goal.id, amount: amount, at: now, walletId: _walletId);
    if (!mounted) return;
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    nav.pop();
    final int? m = _take ? null : goalMilestoneCrossed(before: g.saved, after: after, target: g.goal.target);
    if (m == 100) {
      await router.push(Routes.targetTercapai(g.goal.id));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text(m != null
          ? 'Sudah $m%! Tinggal ${Rupiah.compact(g.goal.target - after)} lagi.'
          : _take
              ? '${Rupiah.format(amount)} diambil dari ${g.goal.name}'
              : '${Rupiah.format(amount)} disisihkan untuk ${g.goal.name}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    final Set<int> counted = ref.watch(_countedWalletsProvider);
    final int typed = RupiahInputFormatter.parse(_amount.text);
    final bool inJatah = _walletId != null && counted.contains(_walletId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSegmentedControl<bool>(
          options: const [false, true],
          selected: _take,
          labelOf: (v) => v ? 'Ambil' : 'Tambah setoran',
          onSurface: true,
          onChanged: (v) => setState(() {
            _take = v;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpace.x16),
        TextField(
          controller: _amount,
          autofocus: widget.amount == null,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
              labelText: 'Nominal', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        const SizedBox(height: AppSpace.x12),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final int v in const [50000, 100000, 250000])
              AppChip(
                label: Rupiah.compact(v),
                selected: typed == v,
                onTap: () => setState(() => _amount.text = Rupiah.digits(v)),
              ),
            if (_take && widget.g.saved > 0)
              AppChip(
                label: 'Semua ${Rupiah.compact(widget.g.saved)}',
                selected: typed == widget.g.saved,
                onTap: () => setState(() => _amount.text = Rupiah.digits(widget.g.saved)),
              ),
            if (!_take && widget.g.left > 0 && widget.g.left <= 10000000)
              AppChip(
                label: 'Sisanya ${Rupiah.compact(widget.g.left)}',
                selected: typed == widget.g.left,
                onTap: () => setState(() => _amount.text = Rupiah.digits(widget.g.left)),
              ),
          ],
        ),
        FieldLabel(_take ? 'Kembali jadi uang bebas di' : 'Disisihkan dari dompet'),
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
        const SizedBox(height: AppSpace.x12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8 + 2),
          decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.smAll),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(HiIcons.info, size: 16, color: c.muted),
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(
                child: Text(
                  _take
                      ? (inJatah
                          ? 'Uang yang diambil kembali jadi uang bebas dan dihitung lagi di Jatah hari ini.'
                          : 'Uang yang diambil kembali jadi uang bebas di dompet ini.')
                      : (_walletId == null
                          ? 'Pilih dompet tempat uangnya disimpan. Saldonya tidak berubah.'
                          : inJatah
                              ? 'Uangnya tetap di dompet, hanya ditandai untuk target. Jatah hari ini ikut turun supaya tidak terpakai.'
                              : 'Uangnya tetap di dompet ini. Dompet ini tidak dihitung di Jatah, jadi Jatah tidak berubah.'),
                  style: t.caption.copyWith(color: c.sub, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: typed > 0 ? '${_take ? 'Ambil' : 'Sisihkan'} ${Rupiah.format(typed)}' : (_take ? 'Ambil' : 'Sisihkan'),
          large: true,
          onPressed: _save,
        ),
      ],
    );
  }
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

/// Emoji pilihan ikon target.
const List<String> goalEmojis = ['🛟', '🏝️', '💍', '📱', '🏍️', '🎓', '🏠', '🎁', '💻', '🚗', '🕋', '👶'];

/// Form target baru / ubah.
Future<void> openGoalForm(BuildContext context, {Goal? existing}) => showAppSheet<void>(
      context,
      title: existing == null ? 'Target baru' : 'Ubah target',
      builder: (_) => _GoalForm(existing: existing),
    );

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final Goal? existing;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  late final Goal? _e = widget.existing;
  late String _emoji = _e?.emoji ?? goalEmojis.first;
  late final TextEditingController _name = TextEditingController(text: _e?.name ?? '');
  late final TextEditingController _target = TextEditingController(text: _e == null ? '' : Rupiah.digits(_e.target));
  late DateTime? _due = _e?.dueDate;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final DateTime now = ref.read(clockProvider)();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime(now.year, now.month + 6, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 30),
      helpText: 'Tanggal target',
    );
    if (d != null) setState(() => _due = d);
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int target = RupiahInputFormatter.parse(_target.text);
    if (name.isEmpty) return setState(() => _error = 'Isi nama targetnya.');
    if (target <= 0) return setState(() => _error = 'Isi nominal targetnya.');
    final GoalsDao dao = ref.read(appDatabaseProvider).goalsDao;
    if (_e == null) {
      final int id = await dao.add(name: name, target: target, emoji: _emoji, dueDate: _due);
      if (!mounted) return;
      final GoRouter router = GoRouter.of(context);
      Navigator.pop(context);
      await router.push(Routes.targetDetail(id));
    } else {
      await dao.edit(_e.copyWith(name: name, target: target, emoji: _emoji, dueDate: Value(_due)));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final int target = RupiahInputFormatter.parse(_target.text);
    final int saved = _e == null
        ? 0
        : ((ref.watch(goalsProvider).valueOrNull ?? const <GoalWithDeposits>[])
                .where((g) => g.goal.id == _e.id)
                .firstOrNull
                ?.saved ??
            0);
    final String hint = target <= 0
        ? 'Isi nominal untuk melihat berapa yang perlu disisihkan.'
        : _due == null
            ? 'Tanpa tanggal: perkiraan tercapai dihitung dari rata-rata setoranmu $goalPaceDays hari terakhir.'
            : switch (goalEstimate(target: target, saved: saved, dueDate: _due, deposits: const [], now: now)) {
                GoalPerWeek(:final int perWeek) =>
                  'Supaya ${Rupiah.format(target)} tercapai ${DateFmt.date(_due!, now: now)}, sisihkan sekitar ${Rupiah.compact(perWeek)} per minggu.',
                final GoalEstimate e => goalEstimateText(e, now: now),
              };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final String e in {...goalEmojis, _emoji})
              Semantics(
                selected: e == _emoji,
                child: Pressable(
                  onTap: () => setState(() => _emoji = e),
                  semanticLabel: 'Ikon $e',
                  child: Container(
                    width: AppSpace.touch,
                    height: AppSpace.touch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: e == _emoji ? c.accent : Colors.transparent, width: 2),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        TextField(
          controller: _name,
          autofocus: _e == null,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama target', hintText: 'mis. Dana darurat', counterText: ''),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _target,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
              labelText: 'Nominal target', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        const FieldLabel('Tanggal target (opsional)'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            AppChip(label: 'Tanpa tanggal', selected: _due == null, onTap: () => setState(() => _due = null)),
            AppChip(
              label: _due == null ? 'Pilih tanggal' : DateFmt.date(_due!, now: now),
              icon: HiIcons.calendar,
              selected: _due != null,
              onTap: _pickDue,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12 + 2, vertical: AppSpace.x12),
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.mdAll),
          child: Text(hint, style: t.caption.copyWith(color: c.ink, height: 1.5)),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: _e == null ? 'Buat target' : 'Simpan', large: true, onPressed: _save),
      ],
    );
  }
}

class _ProSheet extends StatelessWidget {
  const _ProSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Versi gratis bisa 1 target aktif. Selesaikan atau arsipkan target sekarang, atau buka Premium untuk target tanpa batas — sekali bayar, tanpa iklan.',
          style: t.body.copyWith(color: c.sub),
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Lihat Premium',
          large: true,
          onPressed: () {
            final NavigatorState nav = Navigator.of(context);
            nav.pop();
            openPremium(nav.context, ProReason.target);
          },
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(label: 'Nanti saja', variant: AppButtonVariant.soft, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
