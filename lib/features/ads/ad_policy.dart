/// Aturan kapan iklan boleh tampil. Murni, supaya mudah dites.
abstract final class AdPolicy {
  /// Tab di AppShell yang memuat banner: Beranda (0), Riwayat (1), Laporan (2).
  /// Budget (3) dan semua layar lain (Catat, kunci, onboarding, pengaturan,
  /// cadangan) tidak pernah menampilkan iklan.
  static const Set<int> bannerTabs = {0, 1, 2};

  static bool showBanner({required int tab, required bool isPro, required bool adsReady}) =>
      !isPro && adsReady && bannerTabs.contains(tab);

  /// Iklan berhadiah hanya ditawarkan, tidak pernah diputar otomatis.
  static bool offerRewarded({required bool isPro, required bool adsReady}) => !isPro && adsReady;
}
