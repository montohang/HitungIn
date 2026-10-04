import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';

/// Kolom pengeluaran per hari dalam satu bulan (satu seri, satu warna).
/// Ketuk kolom untuk melihat nilainya; ketuk lagi untuk menutup.
class DailyExpenseChart extends StatefulWidget {
  const DailyExpenseChart({super.key, required this.month, required this.values, required this.now});

  final DateTime month;

  /// Kunci = tanggal 00.00.
  final Map<DateTime, int> values;
  final DateTime now;

  @override
  State<DailyExpenseChart> createState() => _DailyExpenseChartState();
}

class _DailyExpenseChartState extends State<DailyExpenseChart> {
  int? _selected; // tanggal 1..n

  int get _days => DateTime(widget.month.year, widget.month.month + 1, 0).day;

  int _valueOf(int day) => widget.values[DateTime(widget.month.year, widget.month.month, day)] ?? 0;

  @override
  void didUpdateWidget(DailyExpenseChart old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<int> values = [for (int d = 1; d <= _days; d++) _valueOf(d)];
    final int max = values.fold(0, math.max);
    final int top = niceCeil(max);
    final int? sel = _selected;
    final int? peakDay = max == 0 ? null : values.indexOf(max) + 1;

    final String caption = sel != null
        ? '${DateFmt.relativeDay(DateTime(widget.month.year, widget.month.month, sel), now: widget.now)} · ${Rupiah.format(_valueOf(sel))}'
        : peakDay != null
            ? 'Tertinggi ${DateFmt.date(DateTime(widget.month.year, widget.month.month, peakDay), now: widget.now)} · ${Rupiah.format(max)}'
            : 'Belum ada pengeluaran';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: t.caption.copyWith(color: sel != null ? c.ink : c.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpace.x12),
        Semantics(
          label: 'Grafik pengeluaran harian ${DateFmt.month(widget.month)}. $caption',
          child: LayoutBuilder(
            builder: (context, box) {
              const double height = 148;
              const double axisW = 44;
              final double plotW = box.maxWidth - axisW;
              final double slot = plotW / _days;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final double x = d.localPosition.dx - axisW;
                  if (x < 0) return;
                  final int day = (x / slot).floor() + 1;
                  if (day < 1 || day > _days) return;
                  setState(() => _selected = _selected == day ? null : day);
                },
                child: CustomPaint(
                  size: Size(box.maxWidth, height + 20),
                  painter: _ColumnsPainter(
                    values: values,
                    top: top,
                    selected: sel,
                    axisWidth: axisW,
                    plotHeight: height,
                    bar: c.accent,
                    dim: c.accent.withAlpha(0x66),
                    grid: c.line,
                    label: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500, fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Batas atas sumbu yang "bulat": 1, 2, 2.5, 5 × 10ⁿ.
int niceCeil(int v) {
  if (v <= 0) return 0;
  final double mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final double step in const [1, 2, 2.5, 5, 10]) {
    if (step * mag >= v) return (step * mag).round();
  }
  return (10 * mag).round();
}

class _ColumnsPainter extends CustomPainter {
  _ColumnsPainter({
    required this.values,
    required this.top,
    required this.selected,
    required this.axisWidth,
    required this.plotHeight,
    required this.bar,
    required this.dim,
    required this.grid,
    required this.label,
  });

  final List<int> values;
  final int top;
  final int? selected;
  final double axisWidth;
  final double plotHeight;
  final Color bar;
  final Color dim;
  final Color grid;
  final TextStyle label;

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, double width = 40}) {
    final TextPainter tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr, textAlign: align)
      ..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double plotW = size.width - axisWidth;
    final Paint line = Paint()
      ..color = grid
      ..strokeWidth = 1;

    // Garis bantu: tengah & atas (tipis, rata), lalu garis dasar.
    if (top > 0) {
      for (final double f in const [0.5, 1.0]) {
        final double y = plotHeight * (1 - f);
        canvas.drawLine(Offset(axisWidth, y), Offset(size.width, y), line);
        _text(canvas, Rupiah.compact((top * f).round()).replaceFirst('Rp', ''), Offset(0, y - 7));
      }
    }
    canvas.drawLine(Offset(axisWidth, plotHeight), Offset(size.width, plotHeight), line);
    _text(canvas, '0', Offset(0, plotHeight - 7));

    final double slot = plotW / values.length;
    const double gap = 2;
    final double w = math.min(24, slot - gap);
    for (int i = 0; i < values.length; i++) {
      final int v = values[i];
      final double x = axisWidth + slot * i + (slot - w) / 2;
      if (v > 0 && top > 0) {
        final double h = math.max(2, plotHeight * v / top);
        final double r = math.min(4, w / 2);
        final RRect rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, plotHeight - h, w, h),
          topLeft: Radius.circular(r),
          topRight: Radius.circular(r),
        );
        canvas.drawRRect(rect, Paint()..color = selected == null || selected == i + 1 ? bar : dim);
      }
      // Label tanggal: 1, 8, 15, 22, 29.
      if (i % 7 == 0) {
        _text(canvas, '${i + 1}', Offset(axisWidth + slot * i + slot / 2 - 10, plotHeight + 4), align: TextAlign.center, width: 20);
      }
    }
  }

  @override
  bool shouldRepaint(_ColumnsPainter old) =>
      old.values != values || old.top != top || old.selected != selected || old.bar != bar || old.grid != grid;
}
