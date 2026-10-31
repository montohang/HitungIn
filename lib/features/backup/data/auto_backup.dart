import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:saf_folder/saf_folder.dart';

import '../../../core/db/app_database.dart';
import '../../../core/security/secure_store.dart';
import 'backup_codec.dart';
import 'backup_service.dart';

/// Salinan otomatis yang disimpan di folder.
const int autoBackupCopies = 7;

/// Terlewat lebih dari ini → dijalankan saat aplikasi dibuka.
const int autoBackupCatchUpDays = 3;

/// Tidak berjalan selama ini → peringatan.
const int autoBackupStallDays = 7;

/// Pengingat salinan ke luar HP, dihitung dari backup manual terakhir.
const int autoBackupCopyDays = 30;

/// Sebab gagal yang ditampilkan ke pengguna.
enum AutoBackupError {
  folder('Folder tidak ditemukan atau izinnya dicabut.'),
  space('Penyimpanan HP penuh.'),
  other('Berkas tidak bisa dibuat.');

  const AutoBackupError(this.message);
  final String message;
}

/// Status backup otomatis di perangkat ini. Disimpan di Keystore, bukan di
/// database, supaya tidak ikut cadangan dan tidak mengubah isi data.
class AutoBackupState {
  const AutoBackupState({
    this.enabled = false,
    this.tree,
    this.label,
    this.enabledAt,
    this.lastAt,
    this.lastSize,
    this.lastCheckAt,
    this.fingerprint,
    this.error,
    this.failNoticeAt,
    this.stallNoticeAt,
    this.copyNoticeAt,
    this.copyDismissedAt,
  });

  final bool enabled;

  /// Alamat folder (izin permanen) & namanya, mis. "Documents/HitungIn".
  final String? tree;
  final String? label;
  final DateTime? enabledAt;

  /// Berkas terakhir ditulis.
  final DateTime? lastAt;
  final int? lastSize;

  /// Terakhir berjalan sampai selesai, termasuk bila data tidak berubah.
  final DateTime? lastCheckAt;
  final String? fingerprint;
  final AutoBackupError? error;
  final DateTime? failNoticeAt;
  final DateTime? stallNoticeAt;
  final DateTime? copyNoticeAt;
  final DateTime? copyDismissedAt;

  /// Sampai kapan salinan terbaru masih sama dengan data.
  DateTime? get upToDateAt => lastAt == null ? null : (lastCheckAt ?? lastAt);

  AutoBackupState copyWith({
    bool? enabled,
    String? tree,
    String? label,
    DateTime? enabledAt,
    DateTime? lastAt,
    int? lastSize,
    DateTime? lastCheckAt,
    String? fingerprint,
    AutoBackupError? error,
    bool clearError = false,
    DateTime? failNoticeAt,
    DateTime? stallNoticeAt,
    DateTime? copyNoticeAt,
    DateTime? copyDismissedAt,
  }) =>
      AutoBackupState(
        enabled: enabled ?? this.enabled,
        tree: tree ?? this.tree,
        label: label ?? this.label,
        enabledAt: enabledAt ?? this.enabledAt,
        lastAt: lastAt ?? this.lastAt,
        lastSize: lastSize ?? this.lastSize,
        lastCheckAt: lastCheckAt ?? this.lastCheckAt,
        fingerprint: fingerprint ?? this.fingerprint,
        error: clearError ? null : (error ?? this.error),
        failNoticeAt: failNoticeAt ?? this.failNoticeAt,
        stallNoticeAt: stallNoticeAt ?? this.stallNoticeAt,
        copyNoticeAt: copyNoticeAt ?? this.copyNoticeAt,
        copyDismissedAt: copyDismissedAt ?? this.copyDismissedAt,
      );

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'tree': tree,
        'label': label,
        'enabledAt': enabledAt?.toIso8601String(),
        'lastAt': lastAt?.toIso8601String(),
        'lastSize': lastSize,
        'lastCheckAt': lastCheckAt?.toIso8601String(),
        'fingerprint': fingerprint,
        'error': error?.name,
        'failNoticeAt': failNoticeAt?.toIso8601String(),
        'stallNoticeAt': stallNoticeAt?.toIso8601String(),
        'copyNoticeAt': copyNoticeAt?.toIso8601String(),
        'copyDismissedAt': copyDismissedAt?.toIso8601String(),
      };

  static AutoBackupState fromJson(Map<String, Object?> j) {
    DateTime? at(String k) => DateTime.tryParse('${j[k]}');
    return AutoBackupState(
      enabled: j['enabled'] == true,
      tree: j['tree'] as String?,
      label: j['label'] as String?,
      enabledAt: at('enabledAt'),
      lastAt: at('lastAt'),
      lastSize: j['lastSize'] as int?,
      lastCheckAt: at('lastCheckAt'),
      fingerprint: j['fingerprint'] as String?,
      error: AutoBackupError.values.where((e) => e.name == j['error']).firstOrNull,
      failNoticeAt: at('failNoticeAt'),
      stallNoticeAt: at('stallNoticeAt'),
      copyNoticeAt: at('copyNoticeAt'),
      copyDismissedAt: at('copyDismissedAt'),
    );
  }
}

/// Penyimpanan status & password backup otomatis.
class AutoBackupStore {
  const AutoBackupStore(this._store);

  static const String _kState = 'hitungin.auto_backup.state.v1';
  static const String _kPassword = 'hitungin.auto_backup.password.v1';

  final SecureStore _store;

  Future<AutoBackupState> read() async {
    final String? raw = await _store.read(_kState);
    if (raw == null) return const AutoBackupState();
    try {
      return AutoBackupState.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
    } on FormatException {
      return const AutoBackupState();
    }
  }

  Future<void> write(AutoBackupState s) => _store.write(_kState, jsonEncode(s.toJson()));

  Future<String?> password() => _store.read(_kPassword);

  Future<void> setPassword(String password) => _store.write(_kPassword, password);

  /// Nyalakan. Sidik data dikosongkan supaya salinan pertama selalu dibuat.
  Future<void> enable({required String tree, required String label, required String password, required DateTime now}) async {
    await setPassword(password);
    await write(AutoBackupState(enabled: true, tree: tree, label: label, enabledAt: now));
  }

  /// Matikan: status & password dihapus, berkas di folder tetap ada.
  Future<void> clear() async {
    await _store.delete(_kPassword);
    await _store.delete(_kState);
  }
}

/// Nama berkas salinan otomatis; dipakai juga untuk mengenali berkas yang boleh dirotasi.
String autoBackupFileName(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'hitungin-auto-${at.year}-${two(at.month)}-${two(at.day)}.${BackupCodec.extension}';
}

final RegExp _autoName = RegExp(r'^hitungin-auto-\d{4}-\d{2}-\d{2}\.' + BackupCodec.extension + r'$');

/// Berkas otomatis di antara [names] (nama lain, termasuk backup manual, diabaikan).
List<String> autoBackupFiles(Iterable<String> names) => [for (final n in names) if (_autoName.hasMatch(n)) n];

/// Yang dihapus supaya tersisa [keep] salinan terbaru.
List<String> autoBackupVictims(Iterable<String> names, {int keep = autoBackupCopies}) {
  final List<String> auto = autoBackupFiles(names)..sort((a, b) => b.compareTo(a));
  return auto.length <= keep ? const [] : auto.sublist(keep);
}

/// Sidik isi data. Waktu pembuatan & jam catatan kekayaan diabaikan, jadi
/// membuka aplikasi tanpa mengubah data tidak melahirkan salinan baru.
String autoBackupFingerprint(Map<String, Object?> snapshot) {
  final Map<String, Object?> tables = Map<String, Object?>.from(snapshot['tables']! as Map);
  tables['netSnapshots'] = [
    for (final r in tables['netSnapshots'] as List? ?? const []) Map<String, Object?>.from(r as Map)..remove('updatedAt'),
  ];
  return sha256.convert(utf8.encode(jsonEncode(tables))).toString();
}

enum AutoBackupOutcome { written, unchanged, off, failed }

/// Jalankan sekali. Tidak pernah melempar: kegagalan dicatat di status.
/// Salinan terlama baru dihapus sesudah salinan baru berhasil tersimpan.
Future<AutoBackupOutcome> runAutoBackup({
  required AppDatabase db,
  required AutoBackupStore store,
  required SafFolder folder,
  required DateTime now,
  bool force = false,
}) async {
  AutoBackupState state = await store.read();
  final String? tree = state.tree;
  final String? password = await store.password();
  if (!state.enabled || tree == null || password == null) return AutoBackupOutcome.off;
  Future<AutoBackupOutcome> fail(AutoBackupError e) async {
    await store.write(state.copyWith(error: e));
    return AutoBackupOutcome.failed;
  }

  try {
    if (!await folder.accessible(tree)) return fail(AutoBackupError.folder);
    final BackupService service = BackupService(db, clock: () => now);
    final Map<String, Object?> snapshot = await service.snapshot();
    final String print = autoBackupFingerprint(snapshot);
    final List<SafFile> before = await folder.list(tree);
    if (!force && print == state.fingerprint && autoBackupFiles(before.map((f) => f.name)).isNotEmpty) {
      await store.write(state.copyWith(lastCheckAt: now, clearError: true));
      return AutoBackupOutcome.unchanged;
    }
    final Uint8List bytes = await BackupCodec.encrypt(snapshot, password);
    await service.verifyEncrypted(bytes, password, snapshot);
    await folder.write(tree, autoBackupFileName(now), bytes);
    state = state.copyWith(lastAt: now, lastSize: bytes.length, lastCheckAt: now, fingerprint: print, clearError: true);
    await store.write(state);
    // Rotasi gagal tidak membatalkan salinan yang sudah tersimpan.
    try {
      final List<SafFile> after = await folder.list(tree);
      final Set<String> victims = autoBackupVictims(after.map((f) => f.name)).toSet();
      for (final f in after) {
        if (victims.contains(f.name)) await folder.delete(f.doc);
      }
    } on SafFolderException {
      // Dicoba lagi pada giliran berikutnya.
    }
    return AutoBackupOutcome.written;
  } on SafFolderException catch (e) {
    return fail(switch (e.code) {
      'no_permission' || 'not_found' => AutoBackupError.folder,
      'no_space' => AutoBackupError.space,
      _ => AutoBackupError.other,
    });
  } on Object {
    return fail(AutoBackupError.other);
  }
}

int _daysSince(DateTime at, DateTime now) => now.difference(at).inDays;

/// Waktu terlewat: dijalankan saat aplikasi dibuka.
bool autoBackupNeedsCatchUp(AutoBackupState s, DateTime now) {
  if (!s.enabled) return false;
  final DateTime? last = s.lastCheckAt ?? s.enabledAt;
  return last == null || _daysSince(last, now) > autoBackupCatchUpDays;
}

/// Kartu "Buat salinan ke luar HP" di layar Backup.
bool autoBackupCopyDue(AutoBackupState s, DateTime? lastManual, DateTime now) {
  if (!s.enabled) return false;
  final DateTime? since = lastManual ?? s.enabledAt;
  if (since == null || _daysSince(since, now) <= autoBackupCopyDays) return false;
  final DateTime? dismissed = s.copyDismissedAt;
  return dismissed == null || _daysSince(dismissed, now) > autoBackupCopyDays;
}

enum AutoBackupNotice { failed, stalled, copy }

/// Notifikasi yang perlu tampil sekarang; paling penting dulu dan tidak berulang terlalu sering.
AutoBackupNotice? autoBackupNotice(AutoBackupState s, DateTime? lastManual, DateTime now) {
  if (!s.enabled) return null;
  if (s.error != null) {
    final DateTime? told = s.failNoticeAt;
    if (told == null || _daysSince(told, now) >= 1) return AutoBackupNotice.failed;
    return null;
  }
  final DateTime? last = s.lastCheckAt ?? s.enabledAt;
  if (last != null && _daysSince(last, now) >= autoBackupStallDays) {
    final DateTime? told = s.stallNoticeAt;
    if (told == null || _daysSince(told, now) >= autoBackupStallDays) return AutoBackupNotice.stalled;
  }
  final DateTime? since = lastManual ?? s.enabledAt;
  if (since != null && _daysSince(since, now) > autoBackupCopyDays) {
    final DateTime? told = s.copyNoticeAt;
    if (told == null || _daysSince(told, now) > autoBackupCopyDays) return AutoBackupNotice.copy;
  }
  return null;
}
