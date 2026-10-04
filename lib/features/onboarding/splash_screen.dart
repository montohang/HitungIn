import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/logo_mark.dart';
import '../security/app_gate.dart';

/// Splash (Claude Design › Splash Screen): logo "pop", koin jatuh ke palang H,
/// tulisan Hitung**In**, lalu tagline. Setelah itu router memilih tujuan
/// (sapaan, layar kunci, atau beranda).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 1500);
  late final AnimationController _c = AnimationController(vsync: this, duration: _total);

  // Waktu mengikuti desain: pop 0–600 ms, koin 350–1050, tulisan 650–1150, tagline 900–1400.
  Animation<double> _interval(int fromMs, int toMs, Curve curve) => CurvedAnimation(
        parent: _c,
        curve: Interval(fromMs / _total.inMilliseconds, toMs / _total.inMilliseconds, curve: curve),
      );

  late final Animation<double> _pop = _interval(0, 600, const _PopCurve());
  late final Animation<double> _coin = _interval(350, 1050, Curves.bounceOut);
  late final Animation<double> _word = _interval(650, 1150, AppMotion.easeOut);
  late final Animation<double> _tagline = _interval(900, 1400, AppMotion.easeOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (context.reduceMotion) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
    } else {
      _c.forward().whenComplete(_next);
    }
  }

  void _next() {
    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _rise(Animation<double> a, Widget child) => AnimatedBuilder(
        animation: a,
        builder: (context, child) => Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 12 * (1 - a.value)), child: child),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    const Color base = Color(0xFF1A1733);
    final Color ink = dark ? Colors.white : c.ink;
    final Color muted = dark ? const Color(0xFFB9B4D6) : c.muted;
    final Color accentText = dark ? Color.lerp(c.accent, Colors.white, 0.45)! : c.accent;

    return Scaffold(
      backgroundColor: dark ? base : c.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark
              ? RadialGradient(
                  center: const Alignment(0, -0.16),
                  radius: 1.1,
                  stops: const [0, 0.6],
                  colors: [Color.lerp(base, c.accent, 0.28)!, base],
                )
              : null,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pop,
                      builder: (context, child) => Opacity(
                        opacity: (_pop.value * 1.8).clamp(0.0, 1.0),
                        child: Transform.scale(scale: 0.6 + 0.4 * _pop.value, child: child),
                      ),
                      child: LogoMark(size: 128, coinDrop: _coin),
                    ),
                    const SizedBox(height: AppSpace.x24),
                    _rise(
                      _word,
                      Text.rich(
                        TextSpan(text: 'Hitung', children: [TextSpan(text: 'In', style: TextStyle(color: accentText))]),
                        style: t.greeting.copyWith(fontSize: 36, color: ink, letterSpacing: -1.08),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: _rise(
                  _tagline,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: muted),
                      const SizedBox(width: AppSpace.x8),
                      Text('Data tersimpan di HP-mu', style: t.caption.copyWith(fontWeight: FontWeight.w600, color: muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skala 0 → 1.06 → 1 (desain: keyframe 55% = 1.06), dinormalisasi agar
/// nilai akhirnya 1.
class _PopCurve extends Curve {
  const _PopCurve();

  @override
  double transformInternal(double t) {
    const double peak = 0.55;
    if (t < peak) return Curves.easeOut.transform(t / peak) * 1.15; // → ≈1.06 setelah dipetakan 0.6+0.4v
    return 1.15 - 0.15 * Curves.easeOut.transform((t - peak) / (1 - peak));
  }
}
