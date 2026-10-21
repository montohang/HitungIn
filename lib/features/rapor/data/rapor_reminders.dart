import '../../bills/data/bill_reminders.dart';
import '../../recap/data/recap_reminders.dart' show recapPayloadPrefix;

/// Pemilik notifikasi Rapor (lihat [billIdOfReminder]); di samping rekap (800000/1).
const int raporMonthlyOwner = 800002;

/// Payload: `recap:month` → layar Rapor.
const String raporPayload = '${recapPayloadPrefix}month';

/// Tanggal 1 berikutnya pukul 08.00: "Rapor Oktober sudah terbit".
List<ReminderPlan> planRaporReminder({required DateTime now, required bool enabled}) {
  if (!enabled) return const [];
  DateTime at = DateTime(now.year, now.month, 1, 8);
  if (!at.isAfter(now)) at = DateTime(now.year, now.month + 1, 1, 8);
  const List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  final String last = months[DateTime(at.year, at.month - 1).month - 1];
  return [
    (
      id: raporMonthlyOwner * 4,
      billId: 0,
      at: at,
      title: 'Rapor $last sudah terbit 📋',
      body: 'Lihat skor menabung, budget, tagihan & lainnya — plus saran untuk bulan ini.',
      payload: raporPayload,
    ),
  ];
}
