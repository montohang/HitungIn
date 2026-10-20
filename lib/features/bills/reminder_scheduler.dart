import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/platform/launch_routes.dart';
import '../security/app_gate.dart';
import '../debts/data/debt_reminders.dart';
import '../recap/data/recap_reminders.dart';
import '../debts/data/debts_dao.dart';
import 'data/bill_reminders.dart';

export 'data/bill_reminders.dart' show billPayloadPrefix, debtPayloadPrefix;

/// Layar tujuan untuk payload notifikasi, atau null bila tidak dikenal.
String? routeForNotification(String payload) {
  if (payload.startsWith(billPayloadPrefix)) return Routes.tagihan;
  if (payload == '${recapPayloadPrefix}week') return '${Routes.rekap}?minggu=1';
  if (payload == '${recapPayloadPrefix}evening') return Routes.catat;
  if (payload.startsWith(debtPayloadPrefix)) {
    final int? id = int.tryParse(payload.substring(debtPayloadPrefix.length));
    return id == null ? Routes.utang : Uri(path: Routes.utang, queryParameters: {'id': '$id'}).toString();
  }
  return null;
}

/// Layar dari notifikasi yang diketuk, menunggu dibuka oleh shell setelah
/// layar kunci lewat (push saat terkunci membuat layar kunci ganda).
final pendingNotificationRouteProvider = StateProvider<String?>((ref) => null);

/// Penerima ketukan notifikasi. Hidup sepanjang aplikasi (bukan milik shell,
/// yang dibuang setiap kali aplikasi terkunci).
/// Route dari widget/tile/pintasan ikon (P1-2), lewat jalur yang sama
/// dengan ketukan notifikasi: dibuka setelah layar kunci lewat.
final launchRouteHandlerProvider = Provider<void Function(String route)>((ref) {
  return (String route) {
    if (isAllowedLaunchRoute(route)) ref.read(pendingNotificationRouteProvider.notifier).state = route;
  };
});

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

  /// [color] = warna aksen tema pilihan pengguna (lingkaran ikon notifikasi).
  Future<void> schedule(List<ReminderPlan> plans, {Color? color});
}

/// Warna bawaan notifikasi bila tema belum terbaca (aksen Indigo).
const Color defaultReminderColor = Color(0xFF5B4BDB);

class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  static AndroidNotificationDetails _android(Color color) => AndroidNotificationDetails(
    'tagihan',
    'Pengingat tagihan',
    channelDescription: 'Pengingat jatuh tempo tagihan',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
    // Layar kunci yang aman: isi (nominal) disembunyikan.
    visibility: NotificationVisibility.private,
    // Siluet logo penuh 24dp (ikon launcher mono terlalu kecil karena padding adaptif).
    icon: '@drawable/ic_notif',
    // Aksen tema pilihan pengguna; tanpa ini Samsung memakai biru sistem.
    color: color,
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
      settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_notif')),
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
      if (!isDebugReminderId(r.id)) await _plugin.cancel(id: r.id);
    }
  }

  @override
  Future<void> dismissShown({required Set<int> keepBillIds}) async {
    for (final ActiveNotification n in await _plugin.getActiveNotifications()) {
      final int? id = n.id;
      if (id == null || isDebugReminderId(id)) continue;
      if (!keepBillIds.contains(billIdOfReminder(id))) await _plugin.cancel(id: id);
    }
  }

  static const int _debugIdBase = 900000;

  /// Build debug saja: notifikasi uji sekarang ([inMinutes] null) atau
  /// dijadwalkan beberapa menit lagi (menguji saat aplikasi ditutup).
  /// [debtId] diisi = notifikasi utang-piutang (payload `debt:<id>`).
  Future<void> debugTest({
    required int billId,
    required String title,
    required String body,
    int? inMinutes,
    int? debtId,
    Color color = defaultReminderColor,
  }) async {
    if (!kDebugMode) return;
    final NotificationDetails details = NotificationDetails(android: _android(color));
    final String payload = debtId != null ? '$debtPayloadPrefix$debtId' : '$billPayloadPrefix$billId';
    if (inMinutes == null) {
      // Pakai id pengingat asli supaya ikut diuji oleh sinkronisasi.
      final int id = debtId != null
          ? debtReminderOwner(debtId) * 4
          : billId > 0
              ? reminderId(billId, 0)
              : _debugIdBase + 1;
      await _plugin.show(id: id, title: title, body: body, notificationDetails: details, payload: payload);
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
  Future<void> schedule(List<ReminderPlan> plans, {Color? color}) async {
    final NotificationDetails details = NotificationDetails(android: _android(color ?? defaultReminderColor));
    for (final ReminderPlan p in plans) {
      await _plugin.zonedSchedule(
        id: p.id,
        scheduledDate: tz.TZDateTime(tz.local, p.at.year, p.at.month, p.at.day, p.at.hour, p.at.minute),
        notificationDetails: details,
        // Tanpa izin alarm tepat waktu; boleh meleset beberapa menit.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: p.title,
        body: p.body,
        payload: p.payload,
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
  Future<void> schedule(List<ReminderPlan> plans, {Color? color}) async {}
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
  List<DebtWithPayments> debts = const [],
  Color? color,
  List<ReminderPlan> recap = const [],
  bool loggedToday = false,
}) async {
  final bool on = settings.enabled && isPro;
  await scheduler.cancelPending();
  await scheduler.dismissShown(keepBillIds: {
    if (on) ...billsInReminderWindow(bills, now),
    if (on) ...debtsInReminderWindow(debts, now),
    // Rekap Senin tetap; pengingat malam ditutup begitu hari ini sudah dicatat.
    recapWeeklyOwner,
    if (!loggedToday) recapEveningOwner,
  });
  final List<ReminderPlan> all = [
    if (on) ...planBillReminders(bills, now, hour: settings.hour),
    if (on) ...planDebtReminders(debts, now, hour: settings.hour),
    // Notifikasi rekap gratis: tidak bergantung Pro / pengingat tagihan.
    ...recap,
  ]..sort((a, b) => a.at.compareTo(b.at));
  final List<ReminderPlan> plans = all.length > maxScheduledReminders ? all.sublist(0, maxScheduledReminders) : all;
  await scheduler.schedule(plans, color: color);
  return plans.length;
}
