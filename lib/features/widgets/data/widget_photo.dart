import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Foto latar widget (P2b): diperkecil (sisi terpanjang ≤ [maxSide]), disimpan
/// sebagai PNG di folder internal aplikasi, dan diukur kecerahannya untuk
/// memilih warna teks otomatis. Foto tidak pernah keluar dari HP.
Future<({String path, double luma})> saveWidgetPhoto(
  Uint8List bytes, {
  required Directory dir,
  required int widgetId,
  int maxSide = 1080,
}) async {
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final ui.ImageDescriptor desc = await ui.ImageDescriptor.encoded(buffer);
  final double scale = maxSide / (desc.width > desc.height ? desc.width : desc.height);
  final ui.Codec codec = await desc.instantiateCodec(
    targetWidth: scale < 1 ? (desc.width * scale).round() : desc.width,
    targetHeight: scale < 1 ? (desc.height * scale).round() : desc.height,
  );
  final ui.Image image = (await codec.getNextFrame()).image;
  final double luma = await imageLuma(image);
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  codec.dispose();
  if (png == null) throw StateError('Foto tidak bisa dibaca');
  await dir.create(recursive: true);
  final File out = File('${dir.path}/w${widgetId}_${DateTime.now().millisecondsSinceEpoch}.png');
  await out.writeAsBytes(png.buffer.asUint8List(), flush: true);
  return (path: out.path, luma: luma);
}

/// Kecerahan rata-rata 0–1 (dari gambar yang diperkecil ke 16×16).
Future<double> imageLuma(ui.Image image) async {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  ui.Canvas(rec).drawImageRect(
    image,
    ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    const ui.Rect.fromLTWH(0, 0, 16, 16),
    ui.Paint()..filterQuality = ui.FilterQuality.low,
  );
  final ui.Image small = await rec.endRecording().toImage(16, 16);
  final ByteData? rgba = await small.toByteData(format: ui.ImageByteFormat.rawRgba);
  small.dispose();
  if (rgba == null) return 0.5;
  return lumaOfRgba(rgba.buffer.asUint8List());
}

/// Rata-rata luminans relatif dari piksel RGBA (bisa dites tanpa dart:ui).
double lumaOfRgba(Uint8List rgba) {
  if (rgba.length < 4) return 0.5;
  double sum = 0;
  int n = 0;
  for (int i = 0; i + 3 < rgba.length; i += 4) {
    sum += (0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2]) / 255;
    n++;
  }
  return sum / n;
}

/// Hapus foto yang tidak dipakai widget mana pun lagi.
Future<void> deleteWidgetPhoto(String? path) async {
  if (path == null) return;
  try {
    final File f = File(path);
    if (await f.exists()) await f.delete();
  } on FileSystemException {
    // Sudah tidak ada; abaikan.
  }
}
