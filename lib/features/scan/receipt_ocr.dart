import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/utils/date_format.dart';
import '../settings/data/settings_dao.dart';
import 'data/receipt_parser.dart';

/// Pengenal teks di HP (ML Kit, model Latin dibundel — offline).
abstract interface class ReceiptOcr {
  Future<List<OcrLine>> read(String imagePath);
}

class MlKitReceiptOcr implements ReceiptOcr {
  @override
  Future<List<OcrLine>> read(String imagePath) async {
    final TextRecognizer recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText text = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return [
        for (final TextBlock b in text.blocks)
          for (final TextLine l in b.lines)
            (text: l.text, left: l.boundingBox.left, top: l.boundingBox.top, right: l.boundingBox.right, bottom: l.boundingBox.bottom),
      ];
    } finally {
      await recognizer.close();
    }
  }
}

final receiptOcrProvider = Provider<ReceiptOcr>((ref) => MlKitReceiptOcr());

/// Scan yang sudah dipakai bulan [now] (versi gratis).
Future<int> scansUsed(SettingsDao dao, DateTime now) async {
  if (await dao.read(SettingKeys.scanMonth) != DateFmt.monthKey(now)) return 0;
  return int.tryParse(await dao.read(SettingKeys.scanCount) ?? '') ?? 0;
}

/// Catat satu scan berhasil; reset otomatis saat ganti bulan.
Future<void> countScan(SettingsDao dao, DateTime now) async {
  final int used = await scansUsed(dao, now);
  await dao.write(SettingKeys.scanMonth, DateFmt.monthKey(now));
  await dao.write(SettingKeys.scanCount, '${used + 1}');
}

final scansUsedProvider = FutureProvider.autoDispose<int>((ref) {
  final dao = ref.watch(appDatabaseProvider).settingsDao;
  return scansUsed(dao, ref.read(clockProvider)());
});
