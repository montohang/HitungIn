import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/pressable.dart';
import '../../transactions/data/transactions_dao.dart';

/// Satu potong donat. [category] null = gabungan "Lainnya".
typedef DonutSlice = ({String name, int total, int pct, Category? category});

/// Urutkan terbesar dulu; bila lebih dari [maxSlices] kategori, sisanya
/// digabung jadi "Lainnya". Persen dibulatkan (largest remainder) supaya
/// jumlahnya tepat 100.
List<DonutSlice> donutSlices(List<CategoryTotal> totals, {int maxSlices = 5}) {
  final List<CategoryTotal> sorted = [...totals.where((e) => e.total > 0)]..sort((a, b) => b.total.compareTo(a.total));
  if (sorted.isEmpty) return const [];
  final int sum = sorted.fold(0, (s, e) => s + e.total);
  final List<(String, int, Category?)> raw = sorted.length <= maxSlices
      ? [for (final e in sorted) (e.category.name, e.total, e.category)]
      : [
          for (final e in sorted.take(maxSlices - 1)) (e.category.name, e.total, e.category),
          ('Lainnya', sorted.skip(maxSlices - 1).fold(0, (s, e) => s + e.total), null),
        ];
  final List<double> exact = [for (final r in raw) r.$2 * 100 / sum];
  final List<int> pct = [for (final x in exact) x.floor()];
  int left = 100 - pct.fold(0, (s, p) => s + p);
  final List<int> order = List.generate(raw.length, (i) => i)
    ..sort((a, b) => (exact[b] - pct[b]).compareTo(exact[a] - pct[a]));
  for (final int i in order) {
    if (left <= 0) break;
    pct[i]++;
    left--;
  }
  return [for (final (int i, r) in raw.indexed) (name: r.$1, total: r.$2, pct: pct[i], category: r.$3)];
}

/// Warna kategori di donat (urutan tetap, dari desain); "Lainnya" abu.
const List<Color> _sliceColors = [Color(0xFFA79EF2), Color(0xFFE0A43A), Color(0xFF2E8F7F), Color(0xFFD26A8C)];
const Color _otherColor = Color(0xFFC9C5DA);

Color donutColor(BuildContext context, int index, DonutSlice s) =>
    s.category == null ? _otherColor : index == 0 ? context.colors.accent : _sliceColors[(index - 1) % _sliceColors.length];

/// Donat + legenda (Claude Design › Laporan). Ketuk legenda kategori → Riwayat.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.slices, required this.total, this.onTap});

  final List<DonutSlice> slices;
  final int total;
  final ValueChanged<Category>? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<Color> colors = [for (final (int i, s) in slices.indexed) donutColor(context, i, s)];
    return Row(
      children: [
        Semantics(
          label: 'Donat: ${[for (final s in slices) '${s.name} ${s.pct}%'].join(', ')}',
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: 140,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                curve: AppMotion.easeOut,
                builder: (context, v, _) => CustomPaint(
                  painter: _DonutPainter(
                    values: [for (final s in slices) s.total.toDouble()],
                    colors: colors,
                    track: c.chip,
                    progress: v,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total', style: t.label.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: c.muted)),
                        Text(Rupiah.compact(total), style: t.number.copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.x16),
        Expanded(
          child: Column(
            children: [
              for (final (int i, DonutSlice s) in slices.indexed)
                Pressable(
                  onTap: s.category == null || onTap == null ? null : () => onTap!(s.category!),
                  semanticLabel: '${s.name}, ${Rupiah.format(s.total)}, ${s.pct} persen',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: AppSpace.x8),
                        Expanded(
                          child: Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.caption.copyWith(fontWeight: FontWeight.w500, color: c.sub2),
                          ),
                        ),
                        Text('${s.pct}%', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                      ],
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

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.track, required this.progress});

  final List<double> values;
  final List<Color> colors;
  final Color track;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 180: r 70, tebal 24 → skala ke ukuran sebenarnya.
    final double scale = size.width / 180;
    final double stroke = 24 * scale;
    final Rect rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 70 * scale);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track);
    final double sum = values.fold(0, (s, v) => s + v);
    if (sum <= 0) return;
    final double gap = values.length > 1 ? 3 / (70 * scale) : 0; // celah 3 px antar potong
    double start = -math.pi / 2;
    final double full = math.pi * 2 * progress;
    for (int i = 0; i < values.length; i++) {
      final double sweep = values[i] / sum * full;
      final double draw = math.max(0, sweep - gap);
      if (draw > 0) {
        canvas.drawArc(rect, start, draw, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.values != values || old.colors != colors || old.track != track;
}
