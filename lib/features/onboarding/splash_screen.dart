import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/logo_mark.dart';
import '../security/app_gate.dart';

/// Splash singkat: koin jatuh ke palang huruf H, lalu router memilih
/// tujuan (onboarding, layar kunci, atau beranda).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(vsync: this, duration: AppMotion.fill);
  late final Animation<double> _coin = CurvedAnimation(parent: _drop, curve: Curves.bounceOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_drop.isAnimating || _drop.isCompleted) return;
    if (context.reduceMotion) {
      _drop.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
    } else {
      _drop.forward().whenComplete(_next);
    }
  }

  void _next() {
    if (mounted) context.go(Routes.home);
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMark(size: 88, coinDrop: _coin),
            const SizedBox(height: AppSpace.x16),
            Text('HitungIn', style: context.text.greeting),
          ],
        ),
      ),
    );
  }
}
