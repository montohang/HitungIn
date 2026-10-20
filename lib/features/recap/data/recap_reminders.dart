import '../../bills/data/bill_reminders.dart';

/// Payload notifikasi rekap (P3a): `recap:week` / `recap:evening`.
const String recapPayloadPrefix = 'recap:';

/// Pemilik notifikasi rekap (lihat [billIdOfReminder]); di luar rentang tagihan & utang.
const int recapWeeklyOwner = 800000;
const int recapEveningOwner = 800001;

/// Rencana notifikasi rekap (gratis, tidak bergantung Pro/pengingat tagihan):
/// - Senin berikutnya pukul 08.00: "Rekap minggumu sudah siap".
/// - Hari ini pukul 20.00 bila belum ada catatan dan streak ≥ 3.
List<ReminderPlan> planRecapReminders({
  required DateTime now,
  required bool weekly,
  required bool evening,
  required int streak,
  required bool loggedToday,
}) {
  final List<ReminderPlan> out = [];
  if (weekly) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int add = (DateTime.monday - today.weekday + 7) % 7;
    DateTime at = DateTime(today.year, today.month, today.day + add, 8);
    if (!at.isAfter(now)) at = DateTime(today.year, today.month, today.day + add + 7, 8);
    out.add((
      id: recapWeeklyOwner * 4,
      billId: 0,
      at: at,
      title: 'Rekap minggumu sudah siap',
      body: 'Lihat pengeluaran Senin–Minggu, hari paling boros, dan streak mencatatmu.',
      payload: '${recapPayloadPrefix}week',
    ));
  }
  if (evening && streak >= 3 && !loggedToday) {
    final DateTime at = DateTime(now.year, now.month, now.day, 20);
    if (at.isAfter(now)) {
      out.add((
        id: recapEveningOwner * 4,
        billId: 0,
        at: at,
        title: 'Streak $streak hari 🔥',
        body: 'Belum ada catatan hari ini. Catat sebentar supaya streak-mu lanjut.',
        payload: '${recapPayloadPrefix}evening',
      ));
    }
  }
  return out;
}
