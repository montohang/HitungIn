import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'share_text.dart';

/// Potret [boundary] (RepaintBoundary) jadi PNG lalu buka menu Bagikan.
/// [pixelRatio] 3 untuk kartu 360×450 → 1080×1350. Berkas sementara dihapus
/// sesudahnya. [wrap] membungkus pemanggilan menu (mis. menunda kunci otomatis).
Future<bool> shareBoundaryPng(
  GlobalKey boundary, {
  required String fileName,
  required String title,
  required Future<bool> Function(Future<bool> Function() share) wrap,
  double pixelRatio = 3,
}) async {
  final RenderRepaintBoundary r = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await r.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final Directory dir = Directory('${(await getTemporaryDirectory()).path}/share');
  await dir.create(recursive: true);
  final File f = File('${dir.path}/$fileName');
  await f.writeAsBytes(data!.buffer.asUint8List(), flush: true);
  try {
    return await wrap(() => ShareText.image(f.path, title: title));
  } finally {
    if (await f.exists()) await f.delete();
  }
}
