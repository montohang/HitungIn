import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';

/// Status warna progress budget.
enum BudgetLevel { normal, warn, over }

BudgetLevel budgetLevelOf(double ratio) {
  if (ratio > 1) return BudgetLevel.over;
  if (ratio >= 0.8) return BudgetLevel.warn;
  return BudgetLevel.normal;
}

/// Progress bar pil yang terisi pelan dari nol saat pertama tampil
/// (900 ms, ease-out). Warna otomatis: aksen → oranye (≥80%) → merah (>100%).
class AppProgressBar extends StatefulWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.delay = Duration.zero,
    this.color,
    this.autoLevel = true,
  });

  /// Rasio pemakaian, boleh > 1.
  final double value;
  final double height;

  /// Penundaan untuk efek berurutan antar baris (70 ms per baris).
  final Duration delay;

  /// Paksa warna tertentu (mis. alokasi budget).
  final Color? color;

  /// Ubah warna sesuai [BudgetLevel].
  final bool autoLevel;

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 80) + widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool reduce = context.reduceMotion;
    final Color bar = widget.color ??
        (!widget.autoLevel
            ? c.accent
            : switch (budgetLevelOf(widget.value)) {
                BudgetLevel.normal => c.accent,
                BudgetLevel.warn => c.warnBar,
                BudgetLevel.over => c.dangerBar,
              });
    final double target = widget.value.clamp(0.0, 1.0);

    return Semantics(
      value: '${(widget.value * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: Container(
          height: widget.height,
          color: c.track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (_shown || reduce) ? target : 0),
            duration: reduce ? Duration.zero : AppMotion.fill,
            curve: AppMotion.easeOut,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: bar, borderRadius: AppRadius.pillAll),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
