/// Batas versi gratis. Semua keputusan "boleh / harus Pro" lewat sini
/// supaya mudah dites dan diubah di satu tempat.
abstract final class FreeLimits {
  /// Budget per kategori (budget total selalu boleh).
  static const int categoryBudgets = 2;

  /// Tagihan aktif.
  static const int activeBills = 3;

  /// Laporan: bulan berjalan + sekian bulan sebelumnya.
  static const int reportMonthsBack = 1;

  static bool canAddCategoryBudget({required int existing, required bool isPro}) => isPro || existing < categoryBudgets;

  static bool canAddBill({required int active, required bool isPro}) => isPro || active < activeBills;

  /// [month] dan [now] cukup tahun & bulannya.
  static bool canViewReport(DateTime month, DateTime now, {required bool isPro}) {
    if (isPro) return true;
    final int diff = (now.year - month.year) * 12 + (now.month - month.month);
    return diff <= reportMonthsBack;
  }

  /// Ekspor CSV: Pro, atau sekali setelah menonton iklan berhadiah.
  static bool canExportCsv({required bool isPro, required bool rewardEarned}) => isPro || rewardEarned;
}

/// Alasan pengguna diarahkan ke layar Pro — ditampilkan sebagai judul.
enum ProReason {
  umum('Dukung HitungIn & nikmati semua fitur'),
  budget('Budget per kategori tanpa batas'),
  tagihan('Tagihan tanpa batas'),
  laporan('Laporan semua bulan'),
  csv('Ekspor CSV kapan saja'),
  iklan('Tanpa iklan'),
  berulang('Transaksi berulang otomatis'),
  tema('Aksen & ikon aplikasi tambahan');

  const ProReason(this.headline);
  final String headline;

  static ProReason parse(String? s) => ProReason.values.where((r) => r.name == s).firstOrNull ?? umum;
}
