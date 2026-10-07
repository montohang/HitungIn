import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../security/app_gate.dart';
import 'data/bill_reminders.dart';

/// Payload notifikasi tagihan: `bill:<id>`.
const String billPayloadPrefix = 'bill:';

/// Layar tujuan untuk payload notifikasi, atau null bila tidak dikenal.
String? routeForNotification(String payload) => payload.startsWith(billPayloadPrefix) ? Routes.tagihan : null;

/// Layar dari notifikasi yang diketuk, menunggu dibuka oleh shell setelah
/// layar kunci lewat (push saat terkunci membuat layar kunci ganda).
final pendingNotificationRouteProvider = StateProvider<String?>((ref) => null);

/// Penerima ketukan notifikasi. Hidup sepanjang aplikasi (bukan milik shell,
/// yang dibuang setiap kali aplikasi terkunci).
final notificationTapHandlerProvider = Provider<void Function(String payload)>((ref) {
  return (String payload) {
    final String? route = routeForNotification(payload);
    if (route != null) ref.read(pendingNotificationRouteProvider.notifier).state = route;
  };
});

/// Penjadwal notifikasi lokal. Dipisah supaya bisa dipalsukan di tes.
abstract interface class ReminderScheduler {
  /// Siapkan plugin & zona waktu. [onTap] dipanggil saat notifikasi diketuk
  /// (termasuk yang membuka aplikasi dari keadaan tertutup).
  Future<void> init({required void Function(String payload) onTap});

  /// Izin notifikasi Android 13+. True bila diizinkan.
  Future<bool> requestPermission();

  /// Notifikasi aplikasi ini sedang diizinkan.
  Future<bool> permissionGranted();

  /// Batalkan jadwal yang belum berbunyi. Notifikasi yang sudah tampil dibiarkan.
  Future<void> cancelPending();

  /// Tutup notifikasi tagihan yang sedang tampil, kecuali milik [keepBillIds].
  Future<void> dismissShown({required Set<int> keepBillIds});
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

  // Jangan pakai cancelAll(): itu juga menghapus notifikasi yang sedang tampil,
  // padahal sinkronisasi berjalan setiap kali daftar tagihan dimuat ulang.
  @override
  Future<void> cancelPending() async {
    for (final PendingNotificationRequest r in await _plugin.pendingNotificationRequests()) {
      if (r.id < _debugIdBase) await _plugin.cancel(id: r.id);
    }
  }

  @override
  Future<void> dismissShown({required Set<int> keepBillIds}) async {
    for (final ActiveNotification n in await _plugin.getActiveNotifications()) {
      final int? id = n.id;
      if (id == null || id >= _debugIdBase) continue;
      if (!keepBillIds.contains(billIdOfReminder(id))) await _plugin.cancel(id: id);
    }
  }

  static const int _debugIdBase = 900000;

  /// Build debug saja: notifikasi uji sekarang ([inMinutes] null) atau
  /// dijadwalkan beberapa menit lagi (menguji saat aplikasi ditutup).
  Future<void> debugTest({required int billId, required String title, required String body, int? inMinutes}) async {
    if (!kDebugMode) return;
    const NotificationDetails details = NotificationDetails(android: _android);
    final String payload = '$billPayloadPrefix$billId';
    if (inMinutes == null) {
      // Pakai id pengingat asli supaya ikut diuji oleh sinkronisasi.
      await _plugin.show(id: billId > 0 ? reminderId(billId, 0) : _debugIdBase + 1, title: title, body: body, notificationDetails: details, payload: payload);
      return;
    }
    final DateTime at = DateTime.now().add(Duration(minutes: inMinutes));
    await _plugin.zonedSchedule(
      id: _debugIdBase + 2,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

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
  Future<void> cancelPending() async {}

  @override
  Future<void> dismissShown({required Set<int> keepBillIds}) async {}

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

/// Samakan notifikasi dengan keadaan sekarang: jadwal lama dibatalkan lalu
/// dijadwalkan ulang; notifikasi yang sudah tampil tetap ada selama tagihannya
/// belum dibayar. Mengembalikan jumlah yang dijadwalkan.
Future<int> syncBillReminders({
  required ReminderScheduler scheduler,
  required List<Bill> bills,
  required ReminderSettings settings,
  required bool isPro,
  required DateTime now,
}) async {
  final bool on = settings.enabled && isPro;
  await scheduler.cancelPending();
  await scheduler.dismissShown(keepBillIds: on ? billsInReminderWindow(bills, now) : const {});
  if (!on) return 0;
  final List<ReminderPlan> plans = planBillReminders(bills, now, hour: settings.hour);
  await scheduler.schedule(plans);
  return plans.length;
}
