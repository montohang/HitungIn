import '../db/tables.dart';

/// Utilitas tanggal yang dipakai lapisan data. Semua memakai waktu lokal HP.
abstract final class Dates {
  /// Tanggal saja (jam 00.00).
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Awal bulan dari [d] (inklusif) dan awal bulan berikutnya (eksklusif).
  static (DateTime, DateTime) monthRange(DateTime d) => (DateTime(d.year, d.month), DateTime(d.year, d.month + 1));

  /// Jumlah hari di bulan tersebut.
  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// Jatuh tempo berikutnya setelah [from].
  ///
  /// [anchorDay] adalah tanggal asli tagihan (1–31). Bila bulan tujuan
  /// lebih pendek, dipakai hari terakhir bulan itu — tetapi bulan
  /// berikutnya kembali ke [anchorDay] (31 Jan → 28 Feb → 31 Mar).
  /// Mengembalikan null untuk [BillRepeat.sekali].
  static DateTime? nextDue(DateTime from, BillRepeat repeat, {required int anchorDay}) {
    switch (repeat) {
      case BillRepeat.sekali:
        return null;
      case BillRepeat.mingguan:
        return day(from).add(const Duration(days: 7));
      case BillRepeat.bulanan:
        return _clamped(from.year, from.month + 1, anchorDay);
      case BillRepeat.tahunan:
        return _clamped(from.year + 1, from.month, anchorDay);
    }
  }

  static DateTime _clamped(int year, int month, int dayOfMonth) {
    final DateTime first = DateTime(year, month);
    final int last = daysInMonth(first.year, first.month);
    return DateTime(first.year, first.month, dayOfMonth > last ? last : dayOfMonth);
  }
}
