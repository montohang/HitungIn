import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_button.dart';
import '../security/app_gate.dart';
import '../security/auto_lock_setting.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/backup_codec.dart';
import 'data/backup_service.dart';
import 'data/csv_export.dart';

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
    final String? password = await _askPassword(confirm: true);
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
      if (saved != null && mounted) _toast('Cadangan tersimpan. Simpan kata sandinya baik-baik.');
    });
  }

  Future<void> _restore() async {
    final PlatformFile? file = await withAutoLockPaused(
      ref,
      () => FilePicker.pickFile(dialogTitle: 'Pilih berkas cadangan'),
    );
    if (file == null || !mounted) return;
    final Uint8List bytes = await file.xFile.readAsBytes();
    if (!mounted) return;
    final String? password = await _askPassword(confirm: false);
    if (password == null) return;

    await _run(() async {
      final Map<String, Object?> data;
      try {
        data = await BackupCodec.decrypt(bytes, password);
      } on BackupPasswordException {
        if (mounted) _toast('Kata sandi salah atau berkas rusak.');
        return;
      } on BackupFormatException catch (e) {
        if (mounted) _toast(e.message);
        return;
      }
      final AppDatabase db = ref.read(appDatabaseProvider);
      final BackupService service = BackupService(db);
      final BackupSummary s;
      try {
        s = service.inspect(data);
      } on FormatException catch (e) {
        if (mounted) _toast(e.message);
        return;
      }
      if (!mounted) return;
      final bool ok = await confirmDialog(
        context,
        title: 'Ganti semua data?',
        body: 'Cadangan ${DateFmt.longDate(s.createdAt)} berisi ${s.wallets} dompet, ${s.transactions} transaksi, '
            '${s.budgets} budget, dan ${s.bills} tagihan.\n\nSemua data di HP ini akan DIGANTI dengan isi cadangan. '
            'Tidak bisa dibatalkan.',
        confirm: 'Pulihkan',
        danger: true,
      );
      if (!ok) return;
      await service.restore(data);
      // Tema & kunci otomatis ikut dari cadangan.
      ref.read(themeControllerProvider.notifier).applyLoaded(await loadThemeSettings(db.settingsDao));
      await ref.read(autoLockProvider.notifier).set(await loadAutoLockDelay(db.settingsDao));
      if (mounted) _toast('Data dipulihkan.');
    });
  }

  Future<void> _exportCsv() async {
    await _run(() async {
      final items = await ref.read(appDatabaseProvider).transactionsDao.watchBetween(DateTime(1970), DateTime(9999)).first;
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

  Future<String?> _askPassword({required bool confirm}) => showAppSheet<String>(
        context,
        title: confirm ? 'Kata sandi cadangan' : 'Buka cadangan',
        builder: (_) => _PasswordForm(confirm: confirm),
      );

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
                  icon: Icons.save_alt,
                  title: 'Buat cadangan',
                  subtitle: 'Simpan berkas .hitungin ke penyimpanan atau Drive pilihanmu',
                  onTap: _createBackup,
                ),
                SettingsTile(
                  icon: Icons.settings_backup_restore,
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
                  icon: Icons.table_chart_outlined,
                  title: 'Ekspor transaksi (CSV)',
                  subtitle: 'Untuk Excel / Google Sheets — tidak terenkripsi',
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

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.confirm});

  final bool confirm;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final TextEditingController _pw = TextEditingController();
  final TextEditingController _pw2 = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() {
    final String pw = _pw.text;
    if (widget.confirm) {
      if (pw.length < BackupCodec.minPasswordLength) {
        return setState(() => _error = 'Minimal ${BackupCodec.minPasswordLength} karakter.');
      }
      if (pw != _pw2.text) return setState(() => _error = 'Kata sandi tidak sama.');
    } else if (pw.isEmpty) {
      return setState(() => _error = 'Isi kata sandi.');
    }
    Navigator.pop(context, pw);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            tooltip: _show ? 'Sembunyikan' : 'Tampilkan',
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.confirm)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.x12),
            child: Text('Kata sandi ini dibutuhkan untuk memulihkan. Tidak bisa direset.', style: t.caption.copyWith(color: c.muted)),
          ),
        TextField(
          controller: _pw,
          autofocus: true,
          obscureText: !_show,
          enableSuggestions: false,
          autocorrect: false,
          style: t.item,
          decoration: deco('Kata sandi'),
          onSubmitted: widget.confirm ? null : (_) => _submit(),
        ),
        if (widget.confirm) ...[
          const SizedBox(height: AppSpace.x12),
          TextField(
            controller: _pw2,
            obscureText: !_show,
            enableSuggestions: false,
            autocorrect: false,
            style: t.item,
            decoration: deco('Ulangi kata sandi'),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: widget.confirm ? 'Buat cadangan' : 'Buka', large: true, onPressed: _submit),
      ],
    );
  }
}
