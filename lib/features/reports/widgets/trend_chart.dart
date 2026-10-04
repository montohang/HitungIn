import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../transactions/data/transactions_dao.dart';
import 'daily_chart.dart' show niceCeil;

/// Kolom pengeluaran per bulan (satu seri, satu warna aksen). Bulan terakhir
/// (yang sedang dilihat) diberi warna penuh; bulan lain sedikit lebih pudar
/// supaya fokus tetap jelas. Nilai lengkap ada di tabel di bawahnya.
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({super.key, required this.data});

  final List<MonthTotal> data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int max = data.fold(0, (m, e) => math.max(m, e.expense));
    final String summary = data.isEmpty
        ? ''
        : 'Grafik pengeluaran ${DateFmt.month(data.first.month)} sampai ${DateFmt.month(data.last.month)}. '
            'Tertinggi ${Rupiah.format(max)}.';
    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: const Size(double.infinity, 168),
          painter: _TrendPainter(
            data: data,
            top: niceCeil(max),
            bar: c.accent,
            dim: c.accent.withAlpha(0x8C),
            grid: c.line,
            label: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.data, required this.top, required this.bar, required this.dim, required this.grid, required this.label});

  final List<MonthTotal> data;
  final int top;
  final Color bar;
  final Color dim;
  final Color grid;
  final TextStyle label;

  static const double _axisW = 44;
  static const double _bottom = 20;

  void _text(Canvas canvas, String s, Offset at, {double width = 40, TextAlign align = TextAlign.left}) {
    final TextPainter tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr, textAlign: align)
      ..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final double plotH = size.height - _bottom;
    final double plotW = size.width - _axisW;
    final Paint line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    if (top > 0) {
      for (final double f in const [0.5, 1.0]) {
        final double y = plotH * (1 - f);
        canvas.drawLine(Offset(_axisW, y), Offset(size.width, y), line);
        _text(canvas, Rupiah.compact((top * f).round()).replaceFirst('Rp', ''), Offset(0, y - 7));
      }
    }
    canvas.drawLine(Offset(_axisW, plotH), Offset(size.width, plotH), line);
    _text(canvas, '0', Offset(0, plotH - 7));

    final double slot = plotW / data.length;
    final double w = math.min(24, slot - 2);
    final bool everyOther = data.length > 6;
    for (int i = 0; i < data.length; i++) {
      final MonthTotal e = data[i];
      final double x = _axisW + slot * i + (slot - w) / 2;
      if (e.expense > 0 && top > 0) {
        final double h = math.max(2, plotH * e.expense / top);
        final double r = math.min(4, w / 2);
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTWH(x, plotH - h, w, h), topLeft: Radius.circular(r), topRight: Radius.circular(r)),
          Paint()..color = i == data.length - 1 ? bar : dim,
        );
      }
      if (!everyOther || i.isEven || i == data.length - 1) {
        _text(canvas, DateFmt.monthsShort[e.month.month - 1], Offset(_axisW + slot * i + slot / 2 - 16, plotH + 4),
            width: 32, align: TextAlign.center);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.data != data || old.top != top || old.bar != bar || old.grid != grid;
}
