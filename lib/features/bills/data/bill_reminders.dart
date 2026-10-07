import '../../../core/db/app_database.dart';
import '../../../core/utils/rupiah.dart';
import '../../settings/data/settings_dao.dart';

/// Satu notifikasi yang akan dijadwalkan. [at] = waktu lokal HP.
typedef ReminderPlan = ({int id, int billId, DateTime at, String title, String body});

/// Pengaturan pengingat tagihan.
typedef ReminderSettings = ({bool enabled, int hour});

const ReminderSettings defaultReminderSettings = (enabled: true, hour: 9);

/// Pilihan jam pengingat di layar Tagihan.
const List<int> reminderHours = [7, 9, 12, 19];

/// Batas jumlah notifikasi terjadwal (Android membatasi ~500 alarm per aplikasi).
const int maxScheduledReminders = 64;

Future<ReminderSettings> loadReminderSettings(SettingsDao dao) async {
  final String? enabled = await dao.read(SettingKeys.billReminders);
  final int? hour = int.tryParse(await dao.read(SettingKeys.billReminderHour) ?? '');
  return (
    enabled: enabled == null ? defaultReminderSettings.enabled : enabled == 'true',
    hour: hour != null && hour >= 0 && hour <= 23 ? hour : defaultReminderSettings.hour,
  );
}

Future<void> saveReminderSettings(SettingsDao dao, ReminderSettings s) async {
  await dao.write(SettingKeys.billReminders, '${s.enabled}');
  await dao.write(SettingKeys.billReminderHour, '${s.hour}');
}

/// ID notifikasi stabil per tagihan: 0 = H-n, 1 = hari H.
int reminderId(int billId, int slot) => billId * 4 + slot;

/// Kebalikan [reminderId].
int billIdOfReminder(int id) => id ~/ 4;

/// Tagihan aktif yang sudah masuk masa pengingat (H-n sampai lewat jatuh tempo)
/// dan belum dibayar — notifikasinya yang sudah tampil boleh tetap ada.
Set<int> billsInReminderWindow(List<Bill> bills, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  return {
    for (final Bill b in bills)
      if (b.active &&
          !DateTime(b.nextDue.year, b.nextDue.month, b.nextDue.day - b.remindDaysBefore).isAfter(today))
        b.id,
  };
}

/// Rencana notifikasi untuk tagihan aktif: H-[Bill.remindDaysBefore] dan hari H,
/// pada jam [hour]. Waktu yang sudah lewat dilewati (tagihan terlambat cukup
/// ditandai di dalam aplikasi, tidak dikirimi notifikasi berulang).
List<ReminderPlan> planBillReminders(List<Bill> bills, DateTime now, {required int hour}) {
  final List<ReminderPlan> out = [];
  for (final Bill b in bills) {
    if (!b.active) continue;
    final DateTime due = DateTime(b.nextDue.year, b.nextDue.month, b.nextDue.day);
    final String amount = Rupiah.format(b.amount);
    final String title = 'Tagihan: ${b.name}';
    final int n = b.remindDaysBefore;
    if (n > 0) {
      final DateTime at = DateTime(due.year, due.month, due.day - n, hour);
      if (at.isAfter(now)) {
        out.add((
          id: reminderId(b.id, 0),
          billId: b.id,
          at: at,
          title: title,
          body: '${n == 1 ? 'Jatuh tempo besok' : 'Jatuh tempo $n hari lagi'} · $amount',
        ));
      }
    }
    final DateTime onDue = DateTime(due.year, due.month, due.day, hour);
    if (onDue.isAfter(now)) {
      out.add((id: reminderId(b.id, 1), billId: b.id, at: onDue, title: title, body: 'Jatuh tempo hari ini · $amount'));
    }
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.length > maxScheduledReminders ? out.sublist(0, maxScheduledReminders) : out;
}
