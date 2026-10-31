import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saf_folder/saf_folder.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/db/app_database.dart';
import '../../core/db/connection.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../premium/data/entitlement_store.dart';
import '../premium/pro_controller.dart';
import '../settings/data/settings_dao.dart';
import 'data/auto_backup.dart';

const String autoBackupPayload = 'backup';
const int _noticeId = 910001;

const String _taskBackup = 'hitungin.auto.backup';
const String _taskWatch = 'hitungin.auto.watch';
const String _taskNow = 'hitungin.auto.now';

/// Titik masuk tugas latar belakang: mesin Flutter terpisah dari aplikasi.
@pragma('vm:entry-point')
void autoBackupDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? input) async {
    const SecureStore secure = FlutterSecureStore();
    const AutoBackupStore store = AutoBackupStore(secure);
    try {
      if (!(await store.read()).enabled) return true;
      if (!await EntitlementStore(secure).isPro()) return true;
      final AppDatabase db = AppDatabase(openEncryptedConnection());
      try {
        final DateTime now = DateTime.now();
        if (task != _taskWatch) {
          await runAutoBackup(db: db, store: store, folder: const SafFolder(), now: now, force: task == _taskNow);
        }
        await showAutoBackupNotice(db, store, now);
      } finally {
        await db.close();
      }
    } on Object catch (e) {
      debugPrint('Backup otomatis: $e');
    }
    // Jadwal harian tetap berjalan; kegagalan sudah tercatat di status.
    return true;
  });
}

/// Tampilkan notifikasi yang sudah waktunya (lancar berarti diam). Isinya tidak memuat data keuangan.
Future<void> showAutoBackupNotice(AppDatabase db, AutoBackupStore store, DateTime now) async {
  final AutoBackupState s = await store.read();
  final DateTime? manual = DateTime.tryParse(await db.settingsDao.read(SettingKeys.lastBackupAt) ?? '');
  final AutoBackupNotice? notice = autoBackupNotice(s, manual, now);
  if (notice == null) return;
  final (String title, String body, AutoBackupState next) = switch (notice) {
    AutoBackupNotice.failed => (
        'Backup otomatis berhenti',
        '${s.error?.message ?? 'Ada masalah.'} Ketuk untuk memperbaiki.',
        s.copyWith(failNoticeAt: now),
      ),
    AutoBackupNotice.stalled => (
        'Backup otomatis belum berjalan',
        'Sudah $autoBackupStallDays hari lebih. Buka HitungIn untuk mencadangkan.',
        s.copyWith(stallNoticeAt: now),
      ),
    AutoBackupNotice.copy => (
        'Buat salinan ke luar HP',
        'Backup otomatis ada di HP ini. Kalau HP hilang, yang menolong hanya salinan di luar HP.',
        s.copyWith(copyNoticeAt: now),
      ),
  };
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notif')),
  );
  await plugin.show(
    id: _noticeId,
    title: title,
    body: body,
    payload: autoBackupPayload,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'backup',
        'Backup otomatis',
        channelDescription: 'Hanya muncul kalau backup otomatis bermasalah atau perlu salinan ke luar HP',
        importance: Importance.defaultImportance,
        icon: '@drawable/ic_notif',
      ),
    ),
  );
  await store.write(next);
}

/// Jadwal Android. Dipisah supaya bisa dipalsukan di tes.
abstract interface class AutoBackupScheduler {
  /// Pastikan jadwal terpasang (jadwal yang sudah ada dibiarkan).
  Future<void> enable();
  Future<void> disable();

  /// Debug: jalankan tugas latar belakang sekali, sekarang.
  Future<void> runNow();
}

class WorkmanagerAutoBackupScheduler implements AutoBackupScheduler {
  static Future<void>? _ready;

  Future<void> _init() => _ready ??= Workmanager().initialize(autoBackupDispatcher);

  @override
  Future<void> enable() async {
    await _init();
    await Workmanager().registerPeriodicTask(
      _taskBackup,
      _taskBackup,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired, requiresCharging: true),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    // Tanpa syarat mengisi daya: yang berhenti berjalan tetap terlihat.
    await Workmanager().registerPeriodicTask(
      _taskWatch,
      _taskWatch,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  @override
  Future<void> disable() async {
    await _init();
    await Workmanager().cancelByUniqueName(_taskBackup);
    await Workmanager().cancelByUniqueName(_taskWatch);
  }

  @override
  Future<void> runNow() async {
    await _init();
    await Workmanager().registerOneOffTask(_taskNow, _taskNow, existingWorkPolicy: ExistingWorkPolicy.replace);
  }
}

final autoBackupSchedulerProvider = Provider<AutoBackupScheduler>((ref) => WorkmanagerAutoBackupScheduler());

final autoBackupStoreProvider = Provider<AutoBackupStore>((ref) => AutoBackupStore(ref.watch(secureStoreProvider)));

final safFolderProvider = Provider<SafFolder>((ref) => const SafFolder());

/// Status backup otomatis; invalidate sesudah berubah.
final autoBackupProvider = FutureProvider<AutoBackupState>((ref) => ref.watch(autoBackupStoreProvider).read());

/// Jalankan dari aplikasi (penyiapan, ganti folder, waktu terlewat).
final autoBackupRunnerProvider = Provider<Future<AutoBackupOutcome> Function({bool force})>((ref) {
  return ({bool force = false}) async {
    final AutoBackupOutcome out = await runAutoBackup(
      db: ref.read(appDatabaseProvider),
      store: ref.read(autoBackupStoreProvider),
      folder: ref.read(safFolderProvider),
      now: ref.read(clockProvider)(),
      force: force,
    );
    ref.invalidate(autoBackupProvider);
    return out;
  };
});

/// Backup terakhir manual atau otomatis, untuk lencana umur backup.
final effectiveLastBackupProvider = Provider<DateTime?>((ref) {
  final DateTime? manual = ref.watch(lastBackupProvider).valueOrNull;
  final AutoBackupState? auto = ref.watch(autoBackupProvider).valueOrNull;
  final DateTime? at = auto != null && auto.enabled && auto.error == null && ref.watch(isProProvider) ? auto.upToDateAt : null;
  if (manual == null) return at;
  if (at == null) return manual;
  return at.isAfter(manual) ? at : manual;
});
