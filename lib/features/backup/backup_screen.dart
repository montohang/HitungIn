import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../ads/ad_policy.dart';
import '../ads/ads_service.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/backup_codec.dart';
import 'data/backup_service.dart';
import 'data/csv_export.dart';
import 'restore_flow.dart';
import 'widgets/backup_password_form.dart';
import '../../core/widgets/hi_icons.dart';

/// Cadangan terenkripsi (simpan & pulihkan) dan ekspor CSV.
/// Berkas disimpan lewat pemilih berkas sistem — HitungIn tidak
/// mengunggah apa pun.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  String _stamp() {
    final DateTime n = ref.read(clockProvider)();
    return '${DateFmt.monthKey(n)}-${n.day.toString().padLeft(2, '0')}';
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackup() async {
    final String? password = await askBackupPassword(context, confirm: true);
    if (password == null) return;
    await _run(() async {
      final AppDatabase db = ref.read(appDatabaseProvider);
      final Uint8List bytes = await BackupCodec.encrypt(await BackupService(db).snapshot(), password);
      final Uri? saved = await withAutoLockPaused(
        ref,
        () => FilePicker.saveFile(
          fileName: 'hitungin-${_stamp()}.${BackupCodec.extension}',
          bytes: bytes,
          dialogTitle: 'Simpan cadangan',
        ),
      );
      if (saved == null) return;
      await db.settingsDao.write(SettingKeys.lastBackupAt, ref.read(clockProvider)().toIso8601String());
      if (mounted) _toast('Cadangan tersimpan. Simpan kata sandinya baik-baik.');
    });
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await runRestoreFlow(context, ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Versi gratis: tawarkan iklan berhadiah (1× ekspor) atau Pro.
  Future<bool> _unlockCsv() async {
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
            AppButton(label: 'Tonton iklan & ekspor', icon: HiIcons.play, large: true, onPressed: () => Navigator.pop(context, 'ad')),
            const SizedBox(height: AppSpace.x8),
          ],
          AppButton(label: 'Lihat HitungIn Pro', variant: AppButtonVariant.soft, onPressed: () => Navigator.pop(context, 'pro')),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'pro') openPremium(context, ProReason.csv);
    if (choice != 'ad') return false;
    final bool earned = await withAutoLockPaused(ref, () => ref.read(adsServiceProvider).showRewarded());
    if (!earned && mounted) _toast('Iklan belum selesai ditonton, ekspor dibatalkan.');
    return FreeLimits.canExportCsv(isPro: false, rewardEarned: earned);
  }

  Future<void> _exportCsv() async {
    if (!await _unlockCsv()) return;
    await _run(() async {
      final items = await ref.read(appDatabaseProvider).transactionsDao.allDetails();
      if (items.isEmpty) {
        if (mounted) _toast('Belum ada transaksi untuk diekspor.');
        return;
      }
      final Uri? saved = await withAutoLockPaused(
        ref,
        () => FilePicker.saveFile(
          fileName: 'hitungin-transaksi-${_stamp()}.csv',
          bytes: CsvExport.bytes(items),
          mimeType: 'text/csv',
          dialogTitle: 'Simpan CSV',
        ),
      );
      if (saved != null && mounted) _toast('${items.length} transaksi diekspor. Berkas CSV tidak terenkripsi.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      appBar: AppBar(title: Text('Cadangan & ekspor', style: t.screenTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: AppSpace.screen.copyWith(top: AppSpace.x8),
          children: [
            if (_busy) ...[
              LinearProgressIndicator(color: c.accent, backgroundColor: c.track),
              const SizedBox(height: AppSpace.x16),
            ],
            SettingsGroup(
              title: 'Cadangan terenkripsi',
              children: [
                SettingsTile(
                  icon: HiIcons.download,
                  title: 'Buat cadangan',
                  subtitle: 'Simpan berkas .hitungin ke penyimpanan atau Drive pilihanmu',
                  onTap: _createBackup,
                ),
                SettingsTile(
                  icon: HiIcons.restore,
                  title: 'Pulihkan dari cadangan',
                  subtitle: 'Mengganti semua data di HP ini',
                  onTap: _restore,
                ),
              ],
            ),
            SettingsGroup(
              title: 'Ekspor',
              children: [
                SettingsTile(
                  icon: HiIcons.table,
                  title: 'Ekspor transaksi (CSV)',
                  subtitle: 'Untuk Excel / Google Sheets — tidak terenkripsi',
                  trailing: ref.watch(isProProvider) ? null : const AppBadge.pro(),
                  onTap: _exportCsv,
                ),
              ],
            ),
            Text(
              'Cadangan dienkripsi AES-256 dengan kata sandi yang kamu buat. HitungIn tidak menyimpan kata sandi itu — '
              'kalau lupa, cadangan tidak bisa dibuka. PIN tidak ikut dicadangkan.',
              style: t.caption.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
