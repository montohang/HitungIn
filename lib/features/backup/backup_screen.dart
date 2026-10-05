import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
import '../../core/widgets/bottom_note_scroll_view.dart';
import '../../core/widgets/hi_icons.dart';
import 'data/backup_age.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/db/data_providers.dart';

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

  /// Cadangan sedang dibuat (bukan pulihkan/CSV) → kartu status menampilkan progres.
  bool _backingUp = false;

  /// Ukuran cadangan yang baru saja disimpan (kartu "Backup selesai").
  int? _justSavedBytes;

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
    setState(() => _backingUp = true);
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
      if (mounted) setState(() => _justSavedBytes = bytes.length);
      if (mounted) _toast('Cadangan tersimpan. Simpan kata sandinya baik-baik.');
    });
    if (mounted) setState(() => _backingUp = false);
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
            AppButton(
                label: 'Tonton iklan & ekspor',
                icon: HiIcons.play,
                large: true,
                onPressed: () => Navigator.pop(context, 'ad')),
            const SizedBox(height: AppSpace.x8),
          ],
          AppButton(
              label: 'Lihat HitungIn Pro',
              variant: AppButtonVariant.soft,
              onPressed: () => Navigator.pop(context, 'pro')),
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
    final DateTime now = ref.watch(clockProvider)();
    final DateTime? last = ref.watch(lastBackupProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: BottomNoteScrollView(
            items: [
              const ScreenHeader(title: 'Backup', large: true),
              const SizedBox(height: AppSpace.x16),
              _StatusCard(
                last: last,
                now: now,
                running: _backingUp,
                justSavedBytes: _justSavedBytes,
                onBackup: _createBackup,
              ),
              const SizedBox(height: AppSpace.x16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                decoration:
                    BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                child: const Column(
                  children: [
                    _InfoRow(
                        label: 'Password backup',
                        desc: 'Dipakai untuk membuka file backup',
                        value: 'Ditanya tiap backup'),
                    _InfoRow(
                        label: 'Lokasi',
                        desc: 'Folder pilihanmu, bisa di Google Drive',
                        value: 'Dipilih saat menyimpan'),
                    _InfoRow(
                      label: 'Backup otomatis',
                      desc: 'Berjalan diam-diam saat HP mengisi daya',
                      value: 'Segera',
                      pro: true,
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x16),
              Row(
                children: [
                  Expanded(
                    child:
                        AppButton(label: 'Pulihkan dari file', variant: AppButtonVariant.outline, onPressed: _restore),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: AppButton(
                      label: 'Export CSV',
                      variant: AppButtonVariant.outline,
                      onPressed: _exportCsv,
                    ),
                  ),
                ],
              ),
            ],
            footer: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
              decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.mdAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(HiIcons.lock, size: 18, color: c.warnInk),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: Text(
                      'File backup dikunci (AES-256) dengan password backup-mu. Tanpa password itu, file tidak bisa '
                      'dibuka siapa pun, termasuk tim HitungIn. PIN tidak ikut dicadangkan. File CSV tidak terenkripsi.',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, height: 1.5, color: c.sub),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _hex(Color x) => '#${(x.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Kartu status: ilustrasi + lencana, "Data aman / Belum ada backup", progres, tombol Backup.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.last,
    required this.now,
    required this.running,
    required this.justSavedBytes,
    required this.onBackup,
  });

  final DateTime? last;
  final DateTime now;
  final bool running;
  final int? justSavedBytes;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime? lastAt = last;
    final ({String label, bool fresh}) age = backupAge(lastAt, now);
    final bool done = justSavedBytes != null && !running;
    final (String title, String sub) = running
        ? ('Mencadangkan…', 'Jangan tutup HitungIn dulu')
        : done
            ? ('Backup selesai', 'Barusan · ${_size(justSavedBytes!)} · terenkripsi')
            : lastAt == null
                ? ('Belum ada backup', 'Simpan cadangan supaya datamu aman kalau HP hilang atau rusak.')
                : (
                    age.fresh ? 'Data aman' : 'Sudah lama tidak backup',
                    'Backup terakhir ${age.label} · ${DateFmt.date(lastAt, now: now)}, ${DateFmt.time(lastAt)}',
                  );
    final bool ok = done || (lastAt != null && age.fresh);
    final Color badge = running ? c.accent : (ok ? c.good : c.warnBar);
    final IconData badgeIcon = running ? HiIcons.download : (ok ? HiIcons.check : HiIcons.warning);
    final String art = '<svg width="96" height="96" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">'
        '<ellipse cx="60" cy="108" rx="40" ry="5" fill="${_hex(c.track)}"/>'
        '<rect x="30" y="14" width="60" height="86" rx="12" fill="${_hex(c.accentSoft)}" stroke="${_hex(c.accent)}" stroke-width="3"/>'
        '<rect x="42" y="30" width="36" height="6" rx="3" fill="${_hex(c.accent)}" fill-opacity="0.5"/>'
        '<rect x="42" y="44" width="28" height="6" rx="3" fill="${_hex(c.accent)}" fill-opacity="0.3"/>'
        '<path d="M60 56l16 6v10c0 9-7 15-16 17-9-2-16-8-16-17V62z" fill="${_hex(c.surface)}" '
        'stroke="${_hex(c.accent)}" stroke-width="3" stroke-linejoin="round"/>'
        '</svg>';
    return Container(
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            width: 120,
            child: Stack(
              children: [
                Center(child: ExcludeSemantics(child: SvgPicture.string(art, width: 96, height: 96))),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: badge,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 3),
                    ),
                    child: Icon(badgeIcon, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x12),
          Text(title, textAlign: TextAlign.center, style: t.section.copyWith(fontSize: 17)),
          const SizedBox(height: AppSpace.x4),
          Text(sub, textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted)),
          if (running) ...[
            const SizedBox(height: AppSpace.x12),
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(minHeight: 8, color: c.accent, backgroundColor: c.track),
            ),
          ],
          const SizedBox(height: AppSpace.x16),
          AppButton(
            label: running
                ? 'Sedang berjalan…'
                : done || lastAt != null
                    ? 'Backup lagi'
                    : 'Backup sekarang',
            onPressed: running ? null : onBackup,
          ),
        ],
      ),
    );
  }

  static String _size(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / 1024 / 1024).toStringAsFixed(1).replaceAll('.', ',')} MB'
      : '${(bytes / 1024).ceil()} KB';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.desc, required this.value, this.pro = false, this.last = false});

  final String label;
  final String desc;
  final String value;
  final bool pro;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(label,
                          style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                    ),
                    if (pro) ...[const SizedBox(width: AppSpace.x8), const AppBadge.pro()],
                  ],
                ),
                const SizedBox(height: AppSpace.x2),
                Text(desc, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          Text(value, style: t.caption.copyWith(color: pro ? c.muted : c.sub)),
        ],
      ),
    );
  }
}
