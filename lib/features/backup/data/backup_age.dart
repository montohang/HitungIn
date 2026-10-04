/// Label umur cadangan terakhir untuk lencana Beranda & Lainnya.
/// null → belum pernah membuat cadangan.
({String label, bool fresh}) backupAge(DateTime? last, DateTime now) {
  if (last == null) return (label: 'belum ada backup', fresh: false);
  final DateTime a = DateTime(last.year, last.month, last.day);
  final DateTime b = DateTime(now.year, now.month, now.day);
  final int days = DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  final String label = switch (days) {
    <= 0 => 'hari ini',
    1 => 'kemarin',
    < 31 => '$days hari lalu',
    _ => 'lebih dari sebulan lalu',
  };
  // Lebih dari 2 minggu dianggap perlu dicadangkan lagi.
  return (label: label, fresh: days <= 14);
}
