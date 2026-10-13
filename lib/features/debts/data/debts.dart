import '../../../core/db/tables.dart';
import '../../../core/utils/dates.dart';

/// Status satu catatan utang-piutang (P2-2).
enum DebtStatus {
  belumLunas('Belum lunas'),
  dicicil('Dicicil'),
  lunas('Lunas');

  const DebtStatus(this.label);
  final String label;
}

/// Kebutuhan hitungan yang tidak bergantung pada kelas Drift, supaya mudah dites.
typedef DebtFacts = ({DebtDirection direction, int amount, int paid, DateTime? dueDate});

int debtLeft(DebtFacts d) => d.amount - d.paid < 0 ? 0 : d.amount - d.paid;

DebtStatus debtStatus(DebtFacts d) => debtLeft(d) == 0
    ? DebtStatus.lunas
    : d.paid > 0
        ? DebtStatus.dicicil
        : DebtStatus.belumLunas;

/// Lewat jatuh tempo: ada jatuh tempo sebelum hari ini dan belum lunas.
bool debtOverdue(DebtFacts d, DateTime now) =>
    d.dueDate != null && debtLeft(d) > 0 && Dates.day(d.dueDate!).isBefore(Dates.day(now));

/// Ringkasan di atas layar Utang-piutang.
typedef DebtTotals = ({int owedToMe, int owedToMeCount, int iOwe, int iOweCount, int overdue});

DebtTotals debtTotals(Iterable<DebtFacts> all, DateTime now) {
  int owedToMe = 0, owedToMeCount = 0, iOwe = 0, iOweCount = 0, overdue = 0;
  for (final DebtFacts d in all) {
    final int left = debtLeft(d);
    if (left == 0) continue;
    if (d.direction == DebtDirection.piutang) {
      owedToMe += left;
      owedToMeCount++;
    } else {
      iOwe += left;
      iOweCount++;
    }
    if (debtOverdue(d, now)) overdue++;
  }
  return (owedToMe: owedToMe, owedToMeCount: owedToMeCount, iOwe: iOwe, iOweCount: iOweCount, overdue: overdue);
}

/// Jenis transaksi dompet untuk pinjaman awal ([payment] = false) atau
/// pembayarannya. Meminjamkan & membayar utang = uang keluar.
TxKind debtTxKind(DebtDirection direction, {required bool payment}) =>
    (direction == DebtDirection.piutang) != payment ? TxKind.utangKeluar : TxKind.utangMasuk;

/// Teks di Riwayat untuk transaksi utang-piutang.
String debtTxNote(DebtDirection direction, String name, {required bool payment}) => switch ((direction, payment)) {
      (DebtDirection.piutang, false) => 'Dipinjamkan ke $name',
      (DebtDirection.piutang, true) => 'Dibayar $name',
      (DebtDirection.utang, false) => 'Pinjam dari $name',
      (DebtDirection.utang, true) => 'Bayar utang ke $name',
    };

/// Pesan pengingat sopan untuk "Tagih lewat WhatsApp" (bisa diubah pengguna).
String debtReminderText({required String name, required int left, required int paid, required DateTime date, required String Function(int) rupiah, required String Function(DateTime) day}) =>
    paid > 0
        ? 'Halo $name, cuma mengingatkan sisa pinjaman ${rupiah(left)} (pinjam tgl ${day(date)}) ya. Makasih banyak 🙏'
        : 'Halo $name, cuma mengingatkan pinjaman ${rupiah(left)} tgl ${day(date)} ya. Makasih banyak 🙏';
