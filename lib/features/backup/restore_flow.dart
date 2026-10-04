import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/date_format.dart';
import '../security/app_gate.dart';
import '../security/auto_lock_setting.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/backup_codec.dart';
import 'data/backup_service.dart';
import 'widgets/backup_password_form.dart';

/// Pulihkan dari berkas cadangan: pilih berkas → kata sandi cadangan →
/// ringkasan isi → konfirmasi → ganti data. Dipakai dari Pengaturan →
/// Cadangan dan dari sapaan ("Sudah pernah pakai?").
///
/// [onboarding]: teks konfirmasi untuk HP baru (belum ada data sendiri).
/// Mengembalikan true bila data berhasil dipulihkan.
Future<bool> runRestoreFlow(BuildContext context, WidgetRef ref, {bool onboarding = false}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  void toast(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));

  final PlatformFile? file = await withAutoLockPaused(
    ref,
    () => FilePicker.pickFile(dialogTitle: 'Pilih berkas cadangan'),
  );
  if (file == null || !context.mounted) return false;
  final Uint8List bytes = await file.xFile.readAsBytes();
  if (!context.mounted) return false;
  final String? password = await askBackupPassword(context, confirm: false);
  if (password == null || !context.mounted) return false;

  final Map<String, Object?> data;
  try {
    data = await _withProgress(context, () => BackupCodec.decrypt(bytes, password));
  } on BackupPasswordException {
    toast('Kata sandi cadangan salah, atau berkasnya rusak.');
    return false;
  } on BackupFormatException catch (e) {
    toast(e.message);
    return false;
  }

  final AppDatabase db = ref.read(appDatabaseProvider);
  final BackupService service = BackupService(db);
  final BackupSummary s;
  try {
    s = service.inspect(data);
  } on FormatException catch (e) {
    toast(e.message);
    return false;
  }
  if (!context.mounted) return false;
  final String isi = '${s.wallets} dompet, ${s.transactions} transaksi, ${s.budgets} budget, '
      '${s.bills} tagihan, dan ${s.recurring} transaksi berulang';
  final bool ok = await confirmDialog(
    context,
    title: onboarding ? 'Pulihkan data ini?' : 'Ganti semua data?',
    body: onboarding
        ? 'Cadangan ${DateFmt.longDate(s.createdAt)} berisi $isi.\n\nSetelah ini kamu membuat PIN baru untuk HP ini.'
        : 'Cadangan ${DateFmt.longDate(s.createdAt)} berisi $isi.\n\nSemua data di HP ini akan DIGANTI dengan isi cadangan. '
            'Tidak bisa dibatalkan.',
    confirm: 'Pulihkan',
    danger: !onboarding,
  );
  if (!ok || !context.mounted) return false;

  await _withProgress(context, () => service.restore(data));
  // Tema & kunci otomatis ikut dari cadangan.
  ref.read(themeControllerProvider.notifier).applyLoaded(await loadThemeSettings(db.settingsDao));
  await ref.read(autoLockProvider.notifier).set(await loadAutoLockDelay(db.settingsDao));
  toast(onboarding ? 'Data dipulihkan. Buat PIN untuk HP ini.' : 'Data dipulihkan.');
  return true;
}

/// Tampilkan indikator selama [task] berjalan (dekripsi PBKDF2 ± 1 detik).
Future<T> _withProgress<T>(BuildContext context, Future<T> Function() task) async {
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator(color: context.colors.accent)),
    ),
  );
  try {
    return await task();
  } finally {
    nav.pop();
  }
}
