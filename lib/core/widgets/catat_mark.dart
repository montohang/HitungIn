import 'package:flutter/widgets.dart';

/// Isi tombol Catat di nav bawah — tanda khas HitungIn (konsep B, Okt 2026):
/// dua tiang putih logo + koin emas bertanda "+" berwarna [accent]. Bentuk
/// tombol tetap kotak membulat; hanya warnanya yang ikut aksen.
class CatatMark extends StatelessWidget {
  const CatatMark({super.key, required this.accent, this.size = 58});

  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _CatatMarkPainter(accent));
}

class _CatatMarkPainter extends CustomPainter {
  const _CatatMarkPainter(this.accent);

  final Color accent;
  static const Color _coin = Color(0xFFF2C14E);

  @override
  void paint(Canvas canvas, Size size) {
    // Digambar di kotak 58×58 lalu diskalakan.
    canvas.scale(size.width / 58);
    final Paint white = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(RRect.fromLTRBR(17, 15, 23, 43, const Radius.circular(3)), white);
    canvas.drawRRect(RRect.fromLTRBR(35, 15, 41, 43, const Radius.circular(3)), white);
    canvas.drawCircle(const Offset(29, 29), 8, Paint()..color = _coin);
    final Paint plus = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(29, 25), const Offset(29, 33), plus);
    canvas.drawLine(const Offset(25, 29), const Offset(33, 29), plus);
  }

  @override
  bool shouldRepaint(_CatatMarkPainter old) => old.accent != accent;
}
