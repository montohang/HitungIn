import 'package:flutter/material.dart';

import '../theme/context_ext.dart';

/// Logo resmi HitungIn — konsep A "Koin-H": dua batang huruf H dengan
/// koin emas sebagai palang tengah. Digambar dengan kode supaya tajam di
/// semua ukuran dan bisa mengikuti warna aksen.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 48,
    this.background,
    this.foreground = const Color(0xFFFFFFFF),
    this.coin = const Color(0xFFF2C14E),
    this.ring = const Color(0xFFD9A21F),
    this.radiusFactor = 0.28,
    this.contentScale = 1,
    this.coinDrop,
  });

  /// Versi satu warna (ikon bertema Android 13+).
  const LogoMark.mono({
    super.key,
    this.size = 48,
    required Color this.background,
    required this.foreground,
    this.radiusFactor = 0.5,
    this.contentScale = 0.82,
  })  : coin = foreground,
        ring = background,
        coinDrop = null;

  final double size;

  /// Default: warna aksen tema.
  final Color? background;
  final Color foreground;
  final Color coin;
  final Color ring;

  /// 0.28 = kotak membulat, 0.5 = lingkaran.
  final double radiusFactor;

  /// < 1 untuk zona aman ikon adaptif (0.82).
  final double contentScale;

  /// Animasi 0→1 untuk koin jatuh di splash (null = diam).
  final Animation<double>? coinDrop;

  @override
  Widget build(BuildContext context) {
    final Color bg = background ?? context.colors.accent;
    Widget paint(double drop) => CustomPaint(
          size: Size.square(size),
          painter: _LogoPainter(
            bg: bg,
            fg: foreground,
            coin: coin,
            ring: ring,
            radiusFactor: radiusFactor,
            scale: contentScale,
            coinOffset: drop,
          ),
        );
    return Semantics(
      label: 'Logo HitungIn',
      image: true,
      child: coinDrop == null
          ? paint(0)
          : AnimatedBuilder(
              animation: coinDrop!,
              builder: (context, _) => paint(1 - coinDrop!.value),
            ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.bg,
    required this.fg,
    required this.coin,
    required this.ring,
    required this.radiusFactor,
    required this.scale,
    required this.coinOffset,
  });

  final Color bg;
  final Color fg;
  final Color coin;
  final Color ring;
  final double radiusFactor;
  final double scale;

  /// 0 = koin di tempat, 1 = koin 70 unit di atas.
  final double coinOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width / 100;
    final RRect frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * radiusFactor),
    );
    canvas.drawRRect(frame, Paint()..color = bg);
    canvas.save();
    canvas.clipRRect(frame);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);

    final Paint bar = Paint()..color = fg;
    canvas.drawRRect(RRect.fromLTRBR(24 * u, 22 * u, 40 * u, 78 * u, Radius.circular(8 * u)), bar);
    canvas.drawRRect(RRect.fromLTRBR(60 * u, 22 * u, 76 * u, 78 * u, Radius.circular(8 * u)), bar);

    final Offset center = Offset(50 * u, (50 - 70 * coinOffset) * u);
    canvas.drawCircle(center, 15 * u, Paint()..color = coin);
    canvas.drawCircle(
      center,
      8 * u,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.bg != bg ||
      old.fg != fg ||
      old.coin != coin ||
      old.ring != ring ||
      old.radiusFactor != radiusFactor ||
      old.scale != scale ||
      old.coinOffset != coinOffset;
}
