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
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import 'data/backup_codec.dart';
import 'data/backup_service.dart';
import 'data/csv_export.dart';
import '../export/export_actions.dart' show unlockCsvExport;
import 'restore_flow.dart';
import 'widgets/backup_password_form.dart';
import '../../core/widgets/bottom_note_scroll_view.dart';
import '../../core/widgets/hi_icons.dart';
import 'data/backup_age.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/pressable.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import 'auto_backup_worker.dart';
import 'data/auto_backup.dart';
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

  @override
  void initState() {
    super.initState();
    // Tugas latar belakang menulis status di luar aplikasi.
    Future.microtask(() => ref.invalidate(autoBackupProvider));
  }

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
      final BackupService service = BackupService(db);
      final Map<String, Object?> snapshot = await service.snapshot();
      final Uint8List bytes = await BackupCodec.encrypt(snapshot, password);
      try {
        await service.verifyEncrypted(bytes, password, snapshot);
      } on Object {
        if (mounted) _toast('Cadangan gagal diperiksa. Tidak ada yang disimpan — coba lagi.');
        return;
      }
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

  Future<void> _exportCsv() async {
    if (!await unlockCsvExport(context, ref)) return;
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
    final DateTime? manual = ref.watch(lastBackupProvider).valueOrNull;
    final DateTime? last = ref.watch(effectiveLastBackupProvider);
    final bool isPro = ref.watch(isProProvider);
    final AutoBackupState auto = ref.watch(autoBackupProvider).valueOrNull ?? const AutoBackupState();
    final bool autoOn = auto.enabled && isPro;
    final bool autoFailed = autoOn && auto.error != null;
    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: BottomNoteScrollView(
            items: [
              const ScreenHeader(title: 'Backup', large: true),
              const SizedBox(height: AppSpace.x16),
              if (autoFailed) ...[
                _AutoFailedBanner(state: auto, onTap: () => context.push(Routes.backupOtomatis)),
                const SizedBox(height: AppSpace.x16),
              ],
              if (autoOn && !autoFailed && autoBackupCopyDue(auto, manual, now)) ...[
                _CopyReminder(
                  manual: manual,
                  now: now,
                  onLater: () async {
                    final store = ref.read(autoBackupStoreProvider);
                    await store.write((await store.read()).copyWith(copyDismissedAt: now));
                    ref.invalidate(autoBackupProvider);
                  },
                  onCopy: _createBackup,
                ),
                const SizedBox(height: AppSpace.x16),
              ],
              _StatusCard(
                last: last,
                autoFailed: autoFailed,
                autoLatest: autoOn && !autoFailed && auto.upToDateAt != null && auto.upToDateAt == last,
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
                child: Column(
                  children: [
                    const _InfoRow(
                        label: 'Password backup',
                        desc: 'Dipakai untuk membuka file backup',
                        value: 'Ditanya tiap backup'),
                    const _InfoRow(
                        label: 'Lokasi',
                        desc: 'Folder pilihanmu, bisa di Google Drive',
                        value: 'Dipilih saat menyimpan'),
                    _AutoRow(state: auto, isPro: isPro, now: now),
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
    this.autoFailed = false,
    this.autoLatest = false,
    required this.last,
    required this.now,
    required this.running,
    required this.justSavedBytes,
    required this.onBackup,
  });

  final bool autoFailed;
  final bool autoLatest;
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
                ? (autoFailed ? 'Perlu backup lagi' : 'Belum ada backup', 'Simpan cadangan supaya datamu aman kalau HP hilang atau rusak.')
                : (
                    autoFailed ? 'Perlu backup lagi' : (age.fresh ? 'Data aman' : 'Sudah lama tidak backup'),
                    '${autoLatest ? 'Backup otomatis terakhir' : 'Backup terakhir'} ${age.label} · ${DateFmt.date(lastAt, now: now)}, ${DateFmt.time(lastAt)}',
                  );
    final bool ok = done || (lastAt != null && age.fresh && !autoFailed);
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

class _AutoFailedBanner extends StatelessWidget {
  const _AutoFailedBanner({required this.state, required this.onTap});

  final AutoBackupState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      key: const Key('auto-gagal'),
      onTap: onTap,
      semanticLabel: 'Perbaiki backup otomatis',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: c.danger.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(HiIcons.warning, size: 22, color: c.danger),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Backup otomatis berhenti', style: t.item.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: c.danger)),
              const SizedBox(height: 2),
              Text(state.error?.message ?? '', style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.sub, height: 1.45)),
            ]),
          ),
          const SizedBox(width: AppSpace.x8),
          Text('Perbaiki', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.danger)),
        ]),
      ),
    );
  }
}

class _CopyReminder extends StatelessWidget {
  const _CopyReminder({required this.manual, required this.now, required this.onLater, required this.onCopy});

  final DateTime? manual;
  final DateTime now;
  final VoidCallback onLater;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime? m = manual;
    final String when = m == null ? 'Belum ada salinan ke luar HP' : 'Salinan terakhir ke luar HP ${now.difference(m).inDays} hari lalu';
    return Container(
      key: const Key('auto-salinan'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 14),
      decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.lgAll),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(HiIcons.copy, size: 22, color: c.warnInk),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Buat salinan ke luar HP', style: t.item.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: c.warnInk)),
              const SizedBox(height: 2),
              Text('Backup otomatis ada di HP ini. $when; kalau HP hilang, itu yang menolong.',
                  style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.warnInk, height: 1.45)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: onLater, child: Text('Nanti', style: TextStyle(color: c.warnInk))),
          const SizedBox(width: AppSpace.x8),
          AppButton(label: 'Buat salinan', expand: false, onPressed: onCopy),
        ]),
      ]),
    );
  }
}

class _AutoRow extends StatelessWidget {
  const _AutoRow({required this.state, required this.isPro, required this.now});

  final AutoBackupState state;
  final bool isPro;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool on = state.enabled && isPro;
    final bool failed = on && state.error != null;
    final DateTime? lastAt = state.lastAt;
    final String desc = failed
        ? 'Berhenti · perlu diperbaiki'
        : on
            ? lastAt == null
                ? 'Aktif · belum ada salinan'
                : 'Aktif · terakhir ${DateFmt.date(lastAt, now: now)}, ${DateFmt.time(lastAt)}'
            : 'Sekali sehari saat HP mengisi daya';
    return Pressable(
      key: const Key('auto-baris'),
      onTap: () => isPro ? context.push(Routes.backupOtomatis) : openPremium(context, ProReason.backupOtomatis),
      semanticLabel: 'Backup otomatis',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpace.x8, children: [
                Text('Backup otomatis', style: t.item.copyWith(fontSize: 14)),
                if (!isPro) const AppBadge.pro(),
              ]),
              const SizedBox(height: 2),
              Text(desc, style: t.label.copyWith(fontWeight: FontWeight.w500, color: failed ? c.danger : c.muted)),
            ]),
          ),
          const SizedBox(width: AppSpace.x8),
          if (on)
            Icon(HiIcons.forward, size: 16, color: c.muted)
          else
            IgnorePointer(child: Switch(value: false, onChanged: (_) {})),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.desc, required this.value});

  final String label;
  final String desc;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                const SizedBox(height: AppSpace.x2),
                Text(desc, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          Text(value, style: t.caption.copyWith(color: c.sub)),
        ],
      ),
    );
  }
}
