import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import 'data/bill_reminders.dart';

/// Payload notifikasi tagihan: `bill:<id>`.
const String billPayloadPrefix = 'bill:';

/// Penjadwal notifikasi lokal. Dipisah supaya bisa dipalsukan di tes.
abstract interface class ReminderScheduler {
  /// Siapkan plugin & zona waktu. [onTap] dipanggil saat notifikasi diketuk
  /// (termasuk yang membuka aplikasi dari keadaan tertutup).
  Future<void> init({required void Function(String payload) onTap});

  /// Izin notifikasi Android 13+. True bila diizinkan.
  Future<bool> requestPermission();

  /// Notifikasi aplikasi ini sedang diizinkan.
  Future<bool> permissionGranted();
  Future<void> cancelAll();
  Future<void> schedule(List<ReminderPlan> plans);
}

class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'tagihan',
    'Pengingat tagihan',
    channelDescription: 'Pengingat jatuh tempo tagihan',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
    // Layar kunci yang aman: isi (nominal) disembunyikan.
    visibility: NotificationVisibility.private,
    icon: '@mipmap/ic_launcher_mono',
  );

  @override
  Future<void> init({required void Function(String payload) onTap}) => _ready ??= _init(onTap);

  Future<void> _init(void Function(String payload) onTap) async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } on Object catch (e) {
      debugPrint('Zona waktu tidak terbaca, pakai Asia/Jakarta: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher_mono')),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload != null) onTap(r.payload!);
      },
    );
    final NotificationAppLaunchDetails? launch = await _plugin.getNotificationAppLaunchDetails();
    final String? payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null) onTap(payload);
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async => await _androidPlugin?.requestNotificationsPermission() ?? true;

  @override
  Future<bool> permissionGranted() async => await _androidPlugin?.areNotificationsEnabled() ?? true;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(List<ReminderPlan> plans) async {
    for (final ReminderPlan p in plans) {
      await _plugin.zonedSchedule(
        id: p.id,
        scheduledDate: tz.TZDateTime(tz.local, p.at.year, p.at.month, p.at.day, p.at.hour, p.at.minute),
        notificationDetails: const NotificationDetails(android: _android),
        // Tanpa izin alarm tepat waktu; boleh meleset beberapa menit.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: p.title,
        body: p.body,
        payload: '$billPayloadPrefix${p.billId}',
      );
    }
  }
}

/// Untuk tes & platform tanpa notifikasi.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  Future<void> init({required void Function(String payload) onTap}) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> permissionGranted() async => false;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> schedule(List<ReminderPlan> plans) async {}
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

class ReminderSettingsController extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() => loadReminderSettings(ref.read(appDatabaseProvider).settingsDao);

  Future<void> set(ReminderSettings s) async {
    state = AsyncData(s);
    await saveReminderSettings(ref.read(appDatabaseProvider).settingsDao, s);
  }
}

final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsController, ReminderSettings>(ReminderSettingsController.new);

final notificationPermissionProvider =
    FutureProvider.autoDispose<bool>((ref) => ref.watch(reminderSchedulerProvider).permissionGranted());

/// Samakan notifikasi terjadwal dengan keadaan sekarang: semua dibatalkan
/// lalu dijadwalkan ulang. Mengembalikan jumlah yang dijadwalkan.
Future<int> syncBillReminders({
  required ReminderScheduler scheduler,
  required List<Bill> bills,
  required ReminderSettings settings,
  required bool isPro,
  required DateTime now,
}) async {
  await scheduler.cancelAll();
  if (!settings.enabled || !isPro) return 0;
  final List<ReminderPlan> plans = planBillReminders(bills, now, hour: settings.hour);
  await scheduler.schedule(plans);
  return plans.length;
}
