import 'dart:typed_data';
import 'dart:ui' as ui;

import 'accent_color.dart';

/// Saran warna aksen dari foto (P2b, Pro): foto diperkecil ke 16×16 lalu
/// diambil warna-warna menonjolnya ([paletteFromRgba]).
Future<List<ui.Color>> paletteFromImageBytes(Uint8List bytes, {int n = 4}) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 16, targetHeight: 16);
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData? rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  codec.dispose();
  return rgba == null ? const [] : paletteFromRgba(rgba.buffer.asUint8List(), n: n);
}
