import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

import '../../core/db/providers.dart';
import '../../core/platform/share_text.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../ads/ad_policy.dart';
import '../ads/ads_service.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'data/export_report.dart';
import 'data/pdf_report.dart';
import 'pdf_preview_screen.dart';

/// Versi gratis: tawarkan iklan berhadiah (1× ekspor CSV) atau Pro.
Future<bool> unlockCsvExport(BuildContext context, WidgetRef ref) async {
  if (ref.read(isProProvider)) return true;
  final bool canAd = AdPolicy.offerRewarded(isPro: false, adsReady: ref.read(adsReadyProvider));
  final String? choice = await showAppSheet<String>(
    context,
    title: 'Ekspor CSV',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          canAd
              ? 'Ekspor CSV adalah fitur Pro. Tonton satu iklan singkat untuk ekspor sekali, atau upgrade ke Pro.'
              : 'Ekspor CSV adalah fitur Pro. Iklan sedang tidak tersedia — coba lagi nanti atau upgrade ke Pro.',
          style: context.text.body.copyWith(color: context.colors.sub),
        ),
        const SizedBox(height: AppSpace.x16),
        if (canAd) ...[
          AppButton(
              label: 'Tonton iklan & ekspor', icon: HiIcons.play, large: true, onPressed: () => Navigator.pop(context, 'ad')),
          const SizedBox(height: AppSpace.x8),
        ],
        AppButton(
            label: 'Lihat HitungIn Pro', variant: AppButtonVariant.soft, onPressed: () => Navigator.pop(context, 'pro')),
      ],
    ),
  );
  if (!context.mounted) return false;
  if (choice == 'pro') openPremium(context, ProReason.csv);
  if (choice != 'ad') return false;
  final bool earned = await withAutoLockPaused(ref, () => ref.read(adsServiceProvider).showRewarded());
  if (!earned && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Iklan belum selesai ditonton, ekspor dibatalkan.')));
  }
  return FreeLimits.canExportCsv(isPro: false, rewardEarned: earned);
}

/// Font aplikasi untuk PDF (tetap offline, dibundel).
Future<PdfFonts> loadPdfFonts() async => (
      regular: await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
      bold: await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
      display: await rootBundle.load('assets/fonts/BricolageGrotesque-Bold.ttf'),
    );

Future<Directory> _shareDir() async {
  final Directory dir = Directory('${(await getTemporaryDirectory()).path}/share');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

/// Hapus sisa berkas export di cache/share (dipanggil sebelum & sesudah berbagi).
Future<void> purgeExportFiles() async {
  try {
    final Directory dir = await _shareDir();
    for (final FileSystemEntity e in dir.listSync()) {
      final String name = e.uri.pathSegments.last;
      if (name.startsWith('hitungin-')) e.deleteSync();
    }
  } on Object {
    // Cache tidak bisa dibaca: tidak ada yang perlu dibersihkan.
  }
}

/// Bagikan berkas lewat menu Bagikan Android; berkas sementara dihapus sesudahnya.
Future<bool> shareExportFile(WidgetRef ref, Uint8List bytes, String fileName, String mime) async {
  await purgeExportFiles();
  final File f = File('${(await _shareDir()).path}/$fileName');
  await f.writeAsBytes(bytes, flush: true);
  try {
    return await withAutoLockPaused(ref, () => ShareText.file(f.path, mime: mime, title: 'Bagikan $fileName'));
  } finally {
    await purgeExportFiles();
  }
}

/// Simpan ke folder pilihan (Storage Access Framework). True bila tersimpan.
Future<bool> saveExportFile(WidgetRef ref, Uint8List bytes, String fileName, String mime) async {
  final Uri? saved = await withAutoLockPaused(
    ref,
    () => FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mime, dialogTitle: 'Simpan $fileName'),
  );
  return saved != null;
}

/// Bangun PDF laporan dengan warna aksen tema.
Future<Uint8List> buildPdfBytes(ExportInput x, {required bool attachment, required Color accent, required PdfFonts fonts}) =>
    PdfReport.build(x, attachment: attachment, accent: PdfColor.fromInt(accent.toARGB32()), fonts: fonts);

/// Buat PDF laporan lalu buka pratinjaunya. Versi gratis: bulan berjalan saja.
Future<void> openPdfReport(
  BuildContext context,
  WidgetRef ref, {
  required DateRange range,
  int? walletId,
  bool attachment = true,
}) async {
  final DateTime now = ref.read(clockProvider)();
  if (!ref.read(isProProvider) && !exportAllowedFree(ExportFormat.pdf, range, now)) {
    openPremium(context, ProReason.export);
    return;
  }
  final Color accent = context.colors.accent;
  final ExportInput x = await loadExportInput(ref.read(appDatabaseProvider), range: range, now: now, walletId: walletId);
  final Uint8List bytes = await buildPdfBytes(x, attachment: attachment, accent: accent, fonts: await loadPdfFonts());
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
    builder: (_) => PdfPreviewScreen(bytes: bytes, fileName: exportFileName(ExportFormat.pdf, range), periodLabel: x.periodLabel),
  ));
}
