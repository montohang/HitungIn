import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/data_providers.dart';
import '../../core/platform/share_capture.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/goals_dao.dart';
import 'goals_provider.dart';

/// "8 bln" / "12 hari" dari dibuat sampai tercapai.
String goalDurationLabel(DateTime from, DateTime to) {
  final int days = DateTime(to.year, to.month, to.day).difference(DateTime(from.year, from.month, from.day)).inDays;
  if (days < 31) return '${math.max(1, days)} hari';
  final int months = (to.year - from.year) * 12 + to.month - from.month - (to.day < from.day ? 1 : 0);
  return '${math.max(1, months)} bln';
}

/// Layar perayaan target tercapai (Claude Design › Target Tercapai).
class GoalAchievedScreen extends ConsumerStatefulWidget {
  const GoalAchievedScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<GoalAchievedScreen> createState() => _GoalAchievedScreenState();
}

class _GoalAchievedScreenState extends ConsumerState<GoalAchievedScreen> with TickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_anim.isAnimating && _anim.value == 0) {
      context.reduceMotion ? _anim.value = 1 : _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final GoalWithDeposits? g =
        (ref.watch(goalsProvider).valueOrNull ?? const <GoalWithDeposits>[]).where((x) => x.goal.id == widget.id).firstOrNull;
    if (g == null) return const Scaffold(body: SizedBox.shrink());
    final DateTime done = g.goal.achievedAt ?? DateTime.now();
    final int deposits = g.deposits.where((d) => d.amount > 0).length;
    final String duration = goalDurationLabel(g.goal.createdAt, done);
    final bool hidden = ref.watch(hideBalanceProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: c.surface,
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: Curves.easeOut.transform((_anim.value * 3).clamp(0, 1)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        c.accent.withValues(alpha: 0.18),
                        c.gold.withValues(alpha: 0.16),
                        c.goodSoft,
                        c.accent.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!context.reduceMotion)
              Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _Confetti(_anim.value, c.accent)))),
            child!,
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSpace.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pressable(
                    onTap: () => context.pop(),
                    semanticLabel: 'Tutup',
                    child: Container(
                      width: AppSpace.touch,
                      height: AppSpace.touch,
                      decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.8), borderRadius: AppRadius.smAll),
                      child: Icon(HiIcons.close, size: 20, color: c.ink),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                Center(
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: _anim, curve: const Interval(0.05, 0.35, curve: Curves.easeOutBack)),
                    child: _Jar(emoji: g.goal.emoji),
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                FadeTransition(
                  opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.2, 0.45)),
                  child: Column(
                    children: [
                      Text('TARGET TERCAPAI',
                          style: t.label.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.6, color: c.accentText)),
                      const SizedBox(height: AppSpace.x8),
                      Text('${g.goal.name} terkumpul!',
                          textAlign: TextAlign.center, style: t.pageTitle.copyWith(fontSize: 28, height: 1.15)),
                      const SizedBox(height: AppSpace.x8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
                        duration: AppMotion.countUp,
                        curve: AppMotion.easeOut,
                        builder: (_, v, __) => Text(
                          hidden ? 'Rp••••' : Rupiah.format((g.goal.target * v / 1000).round() * 1000),
                          style: t.amountXL.copyWith(fontSize: 38, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: AppSpace.x8),
                      Text(
                        'Kamu menabung $duration dengan $deposits setoran. Hebat — ini hasil disiplinmu sendiri.',
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.sub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                Container(
                  padding: const EdgeInsets.all(AppSpace.x16),
                  decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.9), borderRadius: AppRadius.lgAll),
                  child: Row(
                    children: [
                      for (final (String v, String k, bool good) in [
                        (duration, 'Durasi', false),
                        ('$deposits×', 'Setoran', false),
                        ('100%', 'Tercapai', true),
                      ])
                        Expanded(
                          child: Column(
                            children: [
                              Text(v, style: t.section.copyWith(fontWeight: FontWeight.w800, color: good ? c.good : c.ink)),
                              Text(k, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Buat target baru',
                  large: true,
                  onPressed: () => context.pushReplacement('${Routes.target}?baru=1'),
                ),
                const SizedBox(height: AppSpace.x8),
                AppButton(
                  label: 'Bagikan pencapaian',
                  variant: AppButtonVariant.soft,
                  onPressed: () => showAppSheet<void>(
                    context,
                    title: 'Bagikan pencapaian',
                    builder: (_) => _ShareSheet(g: g, duration: duration, deposits: deposits),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Celengan berisi koin, emoji target di tutupnya.
class _Jar extends StatelessWidget {
  const _Jar({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 200,
      height: 160,
      child: CustomPaint(
        painter: _JarPainter(accent: c.accent, surface: c.surface),
        child: Align(alignment: const Alignment(0, -0.95), child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter({required this.accent, required this.surface});

  final Color accent;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 200;
    canvas.scale(s);
    canvas.drawOval(const Rect.fromLTWH(26, 143, 148, 14), Paint()..color = const Color(0x1417152B));
    final RRect body = RRect.fromRectAndRadius(const Rect.fromLTWH(54, 40, 92, 106), const Radius.circular(24));
    canvas.drawRRect(body, Paint()..color = surface);
    canvas.drawRRect(body, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, 22, 72, 22), const Radius.circular(7)), Paint()..color = accent);
    const List<(double, double, int)> coins = [
      (78, 126, 0xFFD9A21F), (104, 128, 0xFFF2C14E), (126, 122, 0xFFD9A21F), (90, 104, 0xFFF6D27A),
      (116, 100, 0xFFF2C14E), (76, 80, 0xFFF2C14E), (102, 76, 0xFFF6D27A), (126, 74, 0xFFD9A21F),
    ];
    for (final (double x, double y, int col) in coins) {
      canvas.drawCircle(Offset(x, y), 13, Paint()..color = Color(col));
    }
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.accent != accent || old.surface != surface;
}

class _Confetti extends CustomPainter {
  _Confetti(this.t, this.accent);

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Color> colors = [accent, const Color(0xFFF2C14E), const Color(0xFF2FA37A), const Color(0xFFA79EF2), const Color(0xFFE0A43A)];
    for (int i = 0; i < 18; i++) {
      final double delay = (i % 7) * 0.05;
      final double p = ((t - delay) / 0.8).clamp(0, 1);
      if (p <= 0 || p >= 1) continue;
      final double x = ((i * 29 + 11) % 100) / 100 * size.width;
      final double y = -20 + p * size.height * 0.75;
      final Paint paint = Paint()..color = colors[i % colors.length].withValues(alpha: p > 0.8 ? (1 - p) * 5 : 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * 5.6);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 5, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -7, 8, 14), const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => old.t != t;
}

/// Kartu bagikan 4:5 (nominal bawaan disembunyikan).
class GoalShareCard extends StatelessWidget {
  const GoalShareCard({super.key, required this.g, required this.duration, required this.deposits, required this.showAmount, required this.accent});

  final GoalWithDeposits g;
  final String duration;
  final int deposits;
  final bool showAmount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final TextStyle white = TextStyle(color: Colors.white, fontFamily: t.body.fontFamily);
    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, const Color(0xFFF2C14E), 0.45)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogoMark(size: 32, background: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 10),
            Text('HitungIn · Target tercapai', style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 28),
          Text(g.goal.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text('${g.goal.name} terkumpul! 🎉',
              style: t.screenTitle.copyWith(color: Colors.white, fontSize: 30, height: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          for (final (String k, String v) in [
            if (showAmount) ('Terkumpul', Rupiah.format(g.goal.target)),
            ('Lama menabung', duration),
            ('Setoran', '$deposits kali'),
          ])
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Text(k, style: white.copyWith(fontSize: 14))),
                Text(v, style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
          const Spacer(),
          Text('Dicatat offline, tanpa akun · HitungIn',
              style: white.copyWith(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.g, required this.duration, required this.deposits});

  final GoalWithDeposits g;
  final String duration;
  final int deposits;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final GlobalKey _card = GlobalKey();
  bool _amount = false;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final NavigatorState nav = Navigator.of(context);
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final bool ok = await shareBoundaryPng(
        _card,
        fileName: 'target-hitungin.png',
        title: 'Bagikan pencapaian lewat',
        wrap: (share) => withAutoLockPaused(ref, share),
      );
      nav.pop();
      if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Menu Bagikan tidak tersedia di perangkat ini.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 248,
              height: 310,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _card,
                  child: GoalShareCard(
                    g: widget.g,
                    duration: widget.duration,
                    deposits: widget.deposits,
                    showAmount: _amount,
                    accent: c.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _amount,
          activeTrackColor: c.accent,
          title: Text('Tampilkan nominal', style: t.item.copyWith(fontSize: 14)),
          subtitle: Text('Mati: kartu hanya berisi nama target, lama menabung & jumlah setoran',
              style: t.caption.copyWith(color: c.muted)),
          onChanged: (v) => setState(() => _amount = v),
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(label: _busy ? 'Menyiapkan…' : 'Bagikan', large: true, onPressed: _busy ? null : _share),
      ],
    );
  }
}
