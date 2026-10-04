import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import '../utils/rupiah.dart';

/// Nominal yang "menghitung naik" dari 0 (1.100 ms, ease-out kubik),
/// dibulatkan ke ribuan selama animasi. Langsung tampil bila
/// "kurangi gerakan" aktif. Ganti [replayKey] untuk mengulang.
class CountUpRupiah extends StatelessWidget {
  const CountUpRupiah({
    super.key,
    required this.amount,
    required this.style,
    this.replayKey,
  });

  final int amount;
  final TextStyle style;
  final Object? replayKey;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return Text(Rupiah.format(amount), style: style);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object?>(replayKey),
      tween: Tween(begin: 0, end: amount.toDouble()),
      duration: AppMotion.countUp,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final int shown = v >= amount ? amount : (v / 1000).round() * 1000;
        return Text(
          Rupiah.format(shown),
          style: style,
          semanticsLabel: Rupiah.format(amount),
        );
      },
    );
  }
}
