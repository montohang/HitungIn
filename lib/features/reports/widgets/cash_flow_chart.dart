import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../transactions/data/transactions_dao.dart';

/// Arus kas per bulan: batang Masuk (hijau) & Keluar (aksen) berdampingan
/// (Claude Design › Laporan). Bulan terakhir tampil penuh, lainnya sedikit pudar.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key, required this.data, this.onTapMonth});

  final List<MonthTotal> data;
  final ValueChanged<DateTime>? onTapMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int max = data.fold(0, (m, e) => math.max(m, math.max(e.income, e.expense)));
    final bool dense = data.length > 6;
    final double barW = dense ? 8 : 14;
    return Column(
      children: [
        Container(
          height: 132,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (int i, MonthTotal e) in data.indexed)
                Expanded(
                  child: Semantics(
                    button: onTapMonth != null,
                    label: '${DateFmt.month(e.month)}: masuk ${Rupiah.format(e.income)}, '
                        'keluar ${Rupiah.format(e.expense)}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTapMonth == null ? null : () => onTapMonth!(e.month),
                      child: Opacity(
                        opacity: i == data.length - 1 ? 1 : 0.85,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(value: e.income, max: max, width: barW, color: c.good, delay: Duration.zero),
                            SizedBox(width: dense ? 2 : 4),
                            _Bar(value: e.expense, max: max, width: barW, color: c.accent, delay: const Duration(milliseconds: 80)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.x8),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final (int i, MonthTotal e) in data.indexed)
                Expanded(
                  child: Text(
                    dense && i.isOdd && i != data.length - 1 ? '' : DateFmt.monthsShort[e.month.month - 1],
                    textAlign: TextAlign.center,
                    style: t.label.copyWith(
                      fontWeight: i == data.length - 1 ? FontWeight.w700 : FontWeight.w500,
                      color: i == data.length - 1 ? c.ink : c.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.max, required this.width, required this.color, required this.delay});

  final int value;
  final int max;
  final double width;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final double h = max == 0 || value == 0 ? 0 : math.max(3, 124 * value / max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: context.reduceMotion ? h : 0, end: h),
      duration: AppMotion.fill + delay,
      curve: Interval(delay.inMilliseconds / (AppMotion.fill + delay).inMilliseconds, 1, curve: AppMotion.easeOut),
      builder: (context, v, _) => Container(
        width: width,
        height: v,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
        ),
      ),
    );
  }
}
