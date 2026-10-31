import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saf_folder/saf_folder.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/security/secure_store.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../bills/reminder_scheduler.dart';
import '../security/app_gate.dart';
import '../security/pin_service.dart';
import '../security/widgets/pin_pad.dart';
import '../settings/widgets/settings_tile.dart' show confirmDialog, showAppSheet;
import 'auto_backup_worker.dart';
import 'data/auto_backup.dart';
import 'data/backup_codec.dart';
import 'widgets/backup_password_form.dart';

/// "1 KB", "1,2 MB".
String autoBackupSize(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / 1024 / 1024).toStringAsFixed(1).replaceAll('.', ',')} MB'
    : '${(bytes / 1024).ceil()} KB';

/// Backup otomatis (P3i, Claude Design › Backup otomatis).
class AutoBackupScreen extends ConsumerStatefulWidget {
  const AutoBackupScreen({super.key});

  @override
  ConsumerState<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends ConsumerState<AutoBackupScreen> {
  @override
  void initState() {
    super.initState();
    // Tugas latar belakang menulis status di luar aplikasi.
    Future.microtask(() => ref.invalidate(autoBackupProvider));
  }

  @override
  Widget build(BuildContext context) {
    final AutoBackupState? s = ref.watch(autoBackupProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: s == null
            ? const Center(child: CircularProgressIndicator())
            : s.enabled
                ? _Settings(state: s)
                : const _Setup(),
      ),
    );
  }
}

/// Catatan berlatar peringatan.
class _Note extends StatelessWidget {
  const _Note(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.mdAll),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon ?? HiIcons.warning, size: 18, color: c.warnInk),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.text.caption.copyWith(color: c.warnInk, height: 1.5))),
      ]),
    );
  }
}

class _Setup extends ConsumerStatefulWidget {
  const _Setup();

  @override
  ConsumerState<_Setup> createState() => _SetupState();
}

class _SetupState extends ConsumerState<_Setup> {
  final TextEditingController _pw = TextEditingController();
  final TextEditingController _pw2 = TextEditingController();
  ({String tree, String label})? _folder;
  bool _show = false;
  bool _noted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final picked = await withAutoLockPaused(ref, () => ref.read(safFolderProvider).pick());
      if (picked != null && mounted) setState(() => _folder = picked);
    } on SafFolderException {
      if (mounted) setState(() => _error = 'Folder itu tidak bisa dipakai. Coba folder lain.');
    }
  }

  bool get _ready => _folder != null && _noted && _pw.text.isNotEmpty && _pw2.text.isNotEmpty && !_busy;

  Future<void> _turnOn() async {
    if (_pw.text.length < BackupCodec.minPasswordLength) {
      return setState(() => _error = 'Password minimal ${BackupCodec.minPasswordLength} karakter.');
    }
    if (_pw.text != _pw2.text) return setState(() => _error = 'Password tidak sama.');
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(autoBackupStoreProvider).enable(
          tree: _folder!.tree,
          label: _folder!.label,
          password: _pw.text,
          now: ref.read(clockProvider)(),
        );
    await ref.read(autoBackupSchedulerProvider).enable();
    // Notifikasi hanya untuk kegagalan; tanpa izin, kegagalan tetap terlihat di layar ini.
    await withAutoLockPaused(ref, () => ref.read(reminderSchedulerProvider).requestPermission());
    await ref.read(autoBackupRunnerProvider)(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ({String tree, String label})? folder = _folder;
    Widget title(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
          child: Text(text, style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub)),
        );
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            tooltip: _show ? 'Sembunyikan' : 'Tampilkan',
            icon: Icon(_show ? HiIcons.eyeOff : HiIcons.eye, size: 20),
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return Column(children: [
      Expanded(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            const ScreenHeader(title: 'Backup otomatis'),
            const SizedBox(height: AppSpace.x12),
            const _Note('Backup ini tersimpan di HP-mu. Kalau HP hilang, yang menolong hanya salinan di luar HP.'),
            const SizedBox(height: AppSpace.x12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: 6),
              decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
              child: Column(children: [
                for (final (IconData icon, String text) in [
                  (HiIcons.bolt, 'Sekali sehari saat HP mengisi daya'),
                  (HiIcons.copy, 'Menyimpan $autoBackupCopies salinan terakhir'),
                  (HiIcons.lock, 'Terkunci password, tetap tanpa internet'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Icon(icon, size: 18, color: c.accentText),
                      const SizedBox(width: AppSpace.x12),
                      Expanded(child: Text(text, style: t.caption.copyWith(color: c.sub))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 14),
            title('1. Pilih folder'),
            const SizedBox(height: AppSpace.x8),
            Pressable(
              key: const Key('auto-pilih-folder'),
              onTap: _pick,
              semanticLabel: 'Pilih folder',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.x12),
                decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line2)),
                child: Row(children: [
                  Icon(HiIcons.folder, size: 20, color: c.accentText),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(child: Text(folder?.label ?? 'Belum dipilih', style: t.item.copyWith(fontSize: 14))),
                  Text(folder == null ? 'Pilih' : 'Ganti', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.accentText)),
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.x8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              child: Text('Android tidak mengizinkan folder Download. Buat folder baru, misalnya HitungIn di Documents.',
                  style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
            ),
            const SizedBox(height: 14),
            title('2. Buat password'),
            const SizedBox(height: AppSpace.x8),
            TextField(
              key: const Key('auto-password'),
              controller: _pw,
              obscureText: !_show,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: deco('Password (minimal ${BackupCodec.minPasswordLength} karakter)'),
            ),
            const SizedBox(height: AppSpace.x8),
            TextField(
              key: const Key('auto-password2'),
              controller: _pw2,
              obscureText: !_show,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: deco('Ulangi password'),
            ),
            const SizedBox(height: AppSpace.x12),
            CheckboxListTile(
              key: const Key('auto-sudah-catat'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _noted,
              onChanged: (v) => setState(() => _noted = v ?? false),
              title: Text('Sudah kucatat passwordnya', style: t.item.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text('Tanpa password ini, backup tidak bisa dibuka. Tim HitungIn pun tidak bisa membantu.',
                  style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.x4),
              Text(_error!, style: t.label.copyWith(color: c.danger)),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
        child: AppButton(
          key: const Key('auto-nyalakan'),
          label: _busy ? 'Menyiapkan…' : 'Nyalakan backup otomatis',
          large: true,
          onPressed: _ready ? _turnOn : null,
        ),
      ),
    ]);
  }
}

class _Settings extends ConsumerStatefulWidget {
  const _Settings({required this.state});

  final AutoBackupState state;

  @override
  ConsumerState<_Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<_Settings> {
  late Future<List<String>?> _copies = _loadCopies();
  bool _busy = false;

  Future<List<String>?> _loadCopies() async {
    final String? tree = widget.state.tree;
    if (tree == null) return null;
    try {
      return autoBackupFiles((await ref.read(safFolderProvider).list(tree)).map((f) => f.name));
    } on SafFolderException {
      return null;
    }
  }

  @override
  void didUpdateWidget(_Settings old) {
    super.didUpdateWidget(old);
    if (old.state.lastAt != widget.state.lastAt || old.state.tree != widget.state.tree) _copies = _loadCopies();
  }

  Future<void> _changeFolder() async {
    final SafFolder folder = ref.read(safFolderProvider);
    final AutoBackupStore store = ref.read(autoBackupStoreProvider);
    final ({String tree, String label})? picked;
    try {
      picked = await withAutoLockPaused(ref, () => folder.pick());
    } on SafFolderException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Folder itu tidak bisa dipakai. Coba folder lain.')));
      return;
    }
    if (picked == null) return;
    setState(() => _busy = true);
    final AutoBackupState s = await store.read();
    final String? old = s.tree;
    await store.write(s.copyWith(tree: picked.tree, label: picked.label, clearError: true));
    if (old != null && old != picked.tree) {
      try {
        await folder.release(old);
      } on SafFolderException {
        // Izin folder lama memang sudah tidak ada.
      }
    }
    await ref.read(autoBackupRunnerProvider)(force: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reveal() async {
    final String? pw = await ref.read(autoBackupStoreProvider).password();
    if (!mounted) return;
    await showAppSheet<void>(context, title: 'Lihat password', builder: (_) => _RevealForm(password: pw ?? ''));
  }

  Future<void> _changePassword() async {
    final String? pw = await showAppSheet<String>(
      context,
      title: 'Ganti password',
      builder: (_) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Note('Salinan yang sudah ada tetap memakai password lama. Simpan password lama sampai salinan itu tergantikan.'),
        SizedBox(height: AppSpace.x12),
        BackupPasswordForm(confirm: true),
      ]),
    );
    if (pw == null) return;
    setState(() => _busy = true);
    await ref.read(autoBackupStoreProvider).setPassword(pw);
    await ref.read(autoBackupRunnerProvider)(force: true);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _turnOff() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Matikan backup otomatis?',
      body: 'Salinan yang sudah ada tetap di folder dan masih bisa dipulihkan. '
          'Password yang tersimpan di HP dihapus, jadi pastikan sudah kamu catat.',
      confirm: 'Matikan',
      danger: true,
    );
    if (!ok) return;
    final String? tree = widget.state.tree;
    await ref.read(autoBackupSchedulerProvider).disable();
    await ref.read(autoBackupStoreProvider).clear();
    if (tree != null) {
      try {
        await ref.read(safFolderProvider).release(tree);
      } on SafFolderException {
        // Izin folder memang sudah tidak ada.
      }
    }
    ref.invalidate(autoBackupProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final AutoBackupState s = widget.state;
    final DateTime now = ref.watch(clockProvider)();
    final AutoBackupError? error = s.error;
    final DateTime? lastAt = s.lastAt;
    final String last = lastAt == null
        ? 'Belum ada salinan'
        : 'Terakhir ${DateFmt.date(lastAt, now: now)}, ${DateFmt.time(lastAt)}'
            '${s.lastSize == null ? '' : ' · ${autoBackupSize(s.lastSize!)}'} · terenkripsi';
    return Column(children: [
      Expanded(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            const ScreenHeader(title: 'Backup otomatis'),
            const SizedBox(height: AppSpace.x12),
            Container(
              key: const Key('auto-status'),
              padding: const EdgeInsets.all(AppSpace.x16),
              decoration: BoxDecoration(
                color: error == null ? c.surface : c.dangerSoft,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: error == null ? c.line : c.danger.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: error == null ? c.goodSoft : c.surface, shape: BoxShape.circle),
                  child: _busy
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.4))
                      : Icon(error == null ? HiIcons.check : HiIcons.warning, size: 22, color: error == null ? c.goodInk : c.danger),
                ),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(error == null ? 'Backup otomatis aktif' : 'Backup otomatis berhenti',
                        style: t.section.copyWith(fontSize: 16, color: error == null ? null : c.danger)),
                    const SizedBox(height: 2),
                    Text(error == null ? last : '${error.message} $last', style: t.caption.copyWith(color: error == null ? c.muted : c.sub)),
                  ]),
                ),
              ]),
            ),
            if (error == AutoBackupError.folder) ...[
              const SizedBox(height: AppSpace.x8),
              AppButton(label: 'Pilih folder lagi', onPressed: _busy ? null : _changeFolder),
            ],
            const SizedBox(height: 14),
            _Group(children: [
              _Row(
                icon: HiIcons.folder,
                label: 'Folder',
                desc: s.label ?? '-',
                action: 'Ganti',
                onTap: _busy ? null : _changeFolder,
              ),
              FutureBuilder<List<String>?>(
                future: _copies,
                builder: (_, snap) {
                  final int? n = snap.data?.length;
                  return _Row(
                    icon: HiIcons.copy,
                    label: 'Salinan',
                    desc: n == null ? 'Menyimpan $autoBackupCopies salinan terakhir' : '$n dari $autoBackupCopies salinan',
                  );
                },
              ),
              const _Row(icon: HiIcons.bolt, label: 'Jadwal', desc: 'Sekali sehari saat mengisi daya, kalau datanya berubah', last: true),
            ]),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              child: Text('Password backup', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub)),
            ),
            const SizedBox(height: AppSpace.x8),
            _Group(children: [
              _Row(icon: HiIcons.eye, label: 'Lihat password', desc: 'Perlu PIN', onTap: _reveal),
              _Row(icon: HiIcons.lock, label: 'Ganti password', onTap: _busy ? null : _changePassword, last: true),
            ]),
            const SizedBox(height: 14),
            const _Note('Salinan ini ada di HP. Sesekali buat backup manual ke Google Drive atau tempat lain lewat layar Backup.',
                icon: HiIcons.copy),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
        child: AppButton(label: 'Matikan backup otomatis', variant: AppButtonVariant.danger, onPressed: _busy ? null : _turnOff),
      ),
    ]);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
        decoration: BoxDecoration(
            color: context.colors.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: context.colors.line)),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.desc, this.action, this.onTap, this.last = false});

  final IconData icon;
  final String label;
  final String? desc;
  final String? action;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Icon(icon, size: 20, color: c.accentText),
        const SizedBox(width: AppSpace.x12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: t.item.copyWith(fontSize: 14)),
            if (desc != null) ...[
              const SizedBox(height: 2),
              Text(desc!, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ],
          ]),
        ),
        if (action != null) Text(action!, style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.accentText)),
      ]),
    );
    return onTap == null ? row : Pressable(onTap: onTap!, semanticLabel: label, child: row);
  }
}

/// PIN lalu password. Aturan percobaan sama dengan layar kunci.
class _RevealForm extends ConsumerStatefulWidget {
  const _RevealForm({required this.password});

  final String password;

  @override
  ConsumerState<_RevealForm> createState() => _RevealFormState();
}

class _RevealFormState extends ConsumerState<_RevealForm> {
  String _pin = '';
  bool _shown = false;
  bool _checking = false;
  String? _error;
  int _shake = 0;

  Future<void> _digit(String d) async {
    if (_checking || _pin.length >= PinService.pinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < PinService.pinLength) return;
    setState(() => _checking = true);
    final PinResult r = await ref.read(pinServiceProvider).verify(_pin);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _pin = '';
      switch (r) {
        case PinOk():
          _shown = true;
        case PinWrong(:final int attemptsLeft):
          _shake++;
          _error = 'PIN salah. Sisa $attemptsLeft percobaan.';
        case PinLockedOut(:final DateTime until):
          _shake++;
          _error = 'Terlalu banyak percobaan. Coba lagi ${DateFmt.time(until)}.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (_shown) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.x16),
          decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.mdAll),
          child: SelectableText(widget.password,
              key: const Key('auto-password-terlihat'),
              textAlign: TextAlign.center,
              style: t.section.copyWith(fontSize: 18, letterSpacing: 0.4)),
        ),
        const SizedBox(height: AppSpace.x12),
        Text('Catat di tempat aman di luar HP ini. Password dipakai untuk membuka backup saat dipulihkan.',
            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
        const SizedBox(height: AppSpace.x12),
        AppButton(label: 'Selesai', onPressed: () => Navigator.pop(context)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_error ?? 'Masukkan PIN untuk melihat password.', style: t.caption.copyWith(color: _error == null ? c.muted : c.danger)),
      const SizedBox(height: AppSpace.x16),
      Center(child: PinDots(filled: _pin.length, style: PinPadStyle.light, shakeKey: _shake)),
      const SizedBox(height: AppSpace.x16),
      PinKeypad(
        style: PinPadStyle.light,
        enabled: !_checking,
        onDigit: _digit,
        onBackspace: () {
          if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        },
      ),
    ]);
  }
}
