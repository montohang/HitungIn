/// Format tanggal gaya Indonesia tanpa bergantung pada data locale intl,
/// supaya hasilnya sama di semua HP dan di tes.
abstract final class DateFmt {
  static const List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Senin = 1 … Minggu = 7 (sama dengan `DateTime.weekday`).
  static const List<String> weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  /// `Oktober 2026`.
  static String month(DateTime d) => '${months[d.month - 1]} ${d.year}';

  /// `19 Okt 2026` (tahun disembunyikan bila tahun ini).
  static String date(DateTime d, {DateTime? now}) {
    final DateTime n = now ?? DateTime.now();
    final String base = '${d.day} ${monthsShort[d.month - 1]}';
    return d.year == n.year ? base : '$base ${d.year}';
  }

  /// `Minggu, 19 Oktober`.
  static String longDate(DateTime d, {DateTime? now}) {
    final DateTime n = now ?? DateTime.now();
    final String base = '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
    return d.year == n.year ? base : '$base ${d.year}';
  }

  /// `Hari ini, 19 Okt`, `Kemarin, 18 Okt`, atau `Jumat, 16 Okt` (isian Tanggal di Catat).
  static String dayLabel(DateTime d, {DateTime? now}) {
    final String rel = relativeDay(d, now: now);
    return rel == 'Hari ini' || rel == 'Kemarin' ? '$rel, ${date(d, now: now)}' : rel;
  }

  /// `Hari ini`, `Kemarin`, atau `Senin, 19 Okt`.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final DateTime n = now ?? DateTime.now();
    final DateTime today = DateTime(n.year, n.month, n.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${weekdays[d.weekday - 1]}, ${date(d, now: n)}';
  }

  /// `08.42`.
  static String time(DateTime d) => '${_two(d.hour)}.${_two(d.minute)}';

  /// Kunci bulan untuk URL: `2026-10`.
  static String monthKey(DateTime d) => '${d.year}-${_two(d.month)}';

  static DateTime? parseMonthKey(String? s) {
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(s ?? '');
    if (m == null) return null;
    final int month = int.parse(m.group(2)!);
    if (month < 1 || month > 12) return null;
    return DateTime(int.parse(m.group(1)!), month);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
