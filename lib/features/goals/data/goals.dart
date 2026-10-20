import '../../../core/utils/date_format.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/rupiah.dart';

/// Satu setoran (+) atau ambil (−) untuk hitungan murni.
typedef DepositFact = ({int amount, int? walletId, DateTime at});

/// Persen terkumpul, dibulatkan ke bawah, 0–100.
int goalPercent(int saved, int target) {
  if (target <= 0 || saved <= 0) return 0;
  return (saved * 100 ~/ target).clamp(0, 100);
}

/// Tonggak yang baru saja dilewati dari [before] ke [after] (25/50/75/100),
/// yang tertinggi bila sekaligus melewati beberapa; null bila tidak ada.
int? goalMilestoneCrossed({required int before, required int after, required int target}) {
  final int a = goalPercent(before, target);
  final int b = goalPercent(after, target);
  for (final int m in const [100, 75, 50, 25]) {
    if (a < m && b >= m) return m;
  }
  return null;
}

/// Perkiraan tercapai sebuah target.
sealed class GoalEstimate {
  const GoalEstimate();
}

/// Sudah tercapai.
final class GoalDone extends GoalEstimate {
  const GoalDone();
}

/// Ada tanggal target di depan: perlu disisihkan [perWeek] tiap minggu.
final class GoalPerWeek extends GoalEstimate {
  const GoalPerWeek(this.perWeek, this.due);
  final int perWeek;
  final DateTime due;
}

/// Tanggal target sudah lewat padahal belum tercapai.
final class GoalOverdue extends GoalEstimate {
  const GoalOverdue(this.due);
  final DateTime due;
}

/// Tanpa tanggal: dari rata-rata setoran 60 hari terakhir, tercapai sekitar [eta].
final class GoalEta extends GoalEstimate {
  const GoalEta(this.eta, this.perMonth);
  final DateTime eta;
  final int perMonth;
}

/// Tanpa tanggal & belum ada setoran bersih 60 hari terakhir.
final class GoalNoPace extends GoalEstimate {
  const GoalNoPace();
}

/// Rentang rata-rata setoran untuk perkiraan tanpa tanggal.
const int goalPaceDays = 60;

/// Bulatkan ke atas ke ribuan (anjuran setoran tidak berakhir receh).
int _ceil1000(int v) => v <= 0 ? 0 : ((v + 999) ~/ 1000) * 1000;

GoalEstimate goalEstimate({
  required int target,
  required int saved,
  required DateTime? dueDate,
  required List<DepositFact> deposits,
  required DateTime now,
}) {
  final int left = target - saved;
  if (left <= 0) return const GoalDone();
  final DateTime today = Dates.day(now);
  if (dueDate != null) {
    final DateTime due = Dates.day(dueDate);
    if (due.isBefore(today)) return GoalOverdue(due);
    // Termasuk hari ini dan hari target; minggu terakhir yang tidak penuh tetap dihitung.
    final int days = due.difference(today).inDays + 1;
    final int weeks = (days + 6) ~/ 7;
    return GoalPerWeek(_ceil1000((left + weeks - 1) ~/ weeks), due);
  }
  final DateTime from = today.subtract(const Duration(days: goalPaceDays - 1));
  final int net = deposits.where((d) => !Dates.day(d.at).isBefore(from)).fold(0, (s, d) => s + d.amount);
  if (net <= 0) return const GoalNoPace();
  final int daysNeeded = (left * goalPaceDays + net - 1) ~/ net;
  return GoalEta(today.add(Duration(days: daysNeeded)), net * 30 ~/ goalPaceDays);
}

/// Kalimat perkiraan untuk daftar & detail target.
String goalEstimateText(GoalEstimate e, {required DateTime now}) => switch (e) {
      GoalDone() => 'Target tercapai',
      GoalPerWeek(:final int perWeek, :final DateTime due) =>
        'Sisihkan ${Rupiah.compact(perWeek)} per minggu supaya tercapai ${DateFmt.date(due, now: now)}',
      GoalOverdue(:final DateTime due) => 'Tanggal target ${DateFmt.date(due, now: now)} sudah lewat',
      GoalEta(:final DateTime eta, :final int perMonth) =>
        'Dengan kecepatan sekarang (${Rupiah.compact(perMonth)}/bln), tercapai sekitar '
            '${DateFmt.monthsShort[eta.month - 1]} ${eta.year}',
      GoalNoPace() => 'Mulai menyisihkan untuk melihat perkiraan tercapai',
    };

/// Total disisihkan dari dompet [counted] (dompet yang ikut Jatah). Per
/// target tidak pernah negatif.
int setAsideFrom(Iterable<List<DepositFact>> goals, Set<int> counted) {
  int total = 0;
  for (final List<DepositFact> ds in goals) {
    final int net = ds.where((d) => d.walletId != null && counted.contains(d.walletId)).fold(0, (s, d) => s + d.amount);
    if (net > 0) total += net;
  }
  return total;
}
