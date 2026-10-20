import '../../../core/utils/rupiah.dart';
import '../../bills/data/bill_reminders.dart';
import 'goals_dao.dart';

/// Payload notifikasi pengingat setoran: `goal:<id>`.
const String goalPayloadPrefix = 'goal:';

/// Pemilik notifikasi target (lihat [billIdOfReminder]); di luar rentang
/// tagihan (< 500000), utang (500000+), rekap (800000+) & uji (900000+).
int goalReminderOwner(int goalId) => 600000 + goalId;

/// Pengingat setoran mingguan (P3b, gratis, bawaan mati): pada hari & jam
/// pilihan, untuk target yang belum diarsipkan dan belum tercapai.
List<ReminderPlan> planGoalReminders(List<GoalWithDeposits> goals, DateTime now) {
  final List<ReminderPlan> out = [];
  for (final GoalWithDeposits g in goals) {
    if (!g.goal.remind || !g.active || g.reached) continue;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int add = (g.goal.remindWeekday - today.weekday + 7) % 7;
    DateTime at = DateTime(today.year, today.month, today.day + add, g.goal.remindHour);
    if (!at.isAfter(now)) at = DateTime(today.year, today.month, today.day + add + 7, g.goal.remindHour);
    out.add((
      id: goalReminderOwner(g.goal.id) * 4,
      billId: 0,
      at: at,
      title: 'Waktunya menyisihkan untuk ${g.goal.name} ${g.goal.emoji}',
      body: 'Sudah ${g.percent}% · kurang ${Rupiah.format(g.left)} lagi.',
      payload: '$goalPayloadPrefix${g.goal.id}',
    ));
  }
  return out;
}
