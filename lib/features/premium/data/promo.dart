import '../../../core/utils/date_format.dart';

/// Hari terakhir promo perkenalan (P4), diisi saat build produksi:
/// `--dart-define=PROMO_END=2027-02-28`. Kosong = tanpa promo.
const String promoEndDefine = String.fromEnvironment('PROMO_END');

/// Harga Pro sesudah promo & harga perkenalan (cadangan bila Google Play belum mengirim harga).
const String normalProPrice = 'Rp39.000';
const String introProPrice = 'Rp29.000';

enum PromoPhase {
  /// Tanpa promo (build tanpa tanggal, atau harga perkenalan sudah lewat).
  none,

  /// Semua fitur Pro gratis.
  active,

  /// Masih gratis, tinggal 7 hari atau kurang.
  endingSoon,

  /// Promo selesai; harga perkenalan berlaku 30 hari.
  intro;

  /// Fitur Pro terbuka untuk semua.
  bool get unlocksPro => this == active || this == endingSoon;
}

/// Masa promo perkenalan. Tanpa server: tanggal tertanam di aplikasi.
class Promo {
  const Promo(this.lastDay);

  /// Dari `PROMO_END` (yyyy-mm-dd); null bila kosong atau tidak valid.
  factory Promo.fromDefine([String raw = promoEndDefine]) {
    final DateTime? d = DateTime.tryParse(raw);
    return Promo(d == null ? null : DateTime(d.year, d.month, d.day));
  }

  static const int endingSoonDays = 7;
  static const int introDays = 30;

  /// Kartu "promo sudah selesai" tampil sekian hari pertama sesudahnya.
  static const int justEndedDays = 7;

  /// Hari terakhir promo (gratis sampai hari ini habis).
  final DateTime? lastDay;

  DateTime? get _end => lastDay == null ? null : DateTime(lastDay!.year, lastDay!.month, lastDay!.day + 1);

  /// Hari terakhir harga perkenalan.
  DateTime? get introLastDay => lastDay == null ? null : DateTime(lastDay!.year, lastDay!.month, lastDay!.day + introDays);

  PromoPhase phase(DateTime now) {
    final DateTime? end = _end;
    if (end == null) return PromoPhase.none;
    if (now.isBefore(end)) {
      return now.isBefore(DateTime(end.year, end.month, end.day - endingSoonDays)) ? PromoPhase.active : PromoPhase.endingSoon;
    }
    return now.isBefore(DateTime(end.year, end.month, end.day + introDays)) ? PromoPhase.intro : PromoPhase.none;
  }

  bool unlocksPro(DateTime now) => phase(now).unlocksPro;

  /// 7 hari pertama sesudah promo berakhir.
  bool justEnded(DateTime now) {
    final DateTime? end = _end;
    return end != null && !now.isBefore(end) && now.isBefore(DateTime(end.year, end.month, end.day + justEndedDays));
  }

  /// Sisa hari promo, termasuk hari ini (1 = hari terakhir).
  int daysLeft(DateTime now) {
    final DateTime? end = _end;
    if (end == null) return 0;
    final int d = end.difference(DateTime(now.year, now.month, now.day)).inDays;
    return d < 0 ? 0 : d;
  }
}

/// "28 Feb 2027".
String promoDate(DateTime d) => '${d.day} ${DateFmt.monthsShort[d.month - 1]} ${d.year}';
