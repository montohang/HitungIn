import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'settings_dao.g.dart';

/// Kunci pengaturan yang dikenal. Tambahkan di sini, jangan menulis
/// string kunci langsung di layar.
abstract final class SettingKeys {
  static const String themeMode = 'theme.mode';
  static const String themeAccent = 'theme.accent';

  /// Asal aksen: preset / wallpaper / custom, dan warna bebasnya (ARGB) (P2b).
  static const String themeAccentSource = 'theme.accentSource';
  static const String themeAccentCustom = 'theme.accentCustom';

  /// Ikon di dalam aplikasi (P2b).
  static const String themeIconStyle = 'theme.iconStyle';
  static const String themeIconWrap = 'theme.iconWrap';
  static const String themeTabLabels = 'theme.tabLabels';
  static const String themeGradientCard = 'theme.gradientCard';
  static const String onboardingDone = 'onboarding.done';
  static const String userName = 'user.name';
  static const String autoLock = 'security.autoLock';
  static const String billReminders = 'bills.reminders';
  static const String lastBackupAt = 'backup.lastAt';
  static const String hideBalance = 'home.hideBalance';

  /// Peringatan budget di 80% (kartu peringatan & chip di Beranda). Default aktif.
  static const String budgetWarn80 = 'budget.warn80';

  /// Template budget (P3f): pilihan terakhir (JSON [TemplateChoice]), saran
  /// setoran tabungan per bulan dari template, dan bulan (yyyy-mm) yang
  /// sisanya sudah diproses.
  static const String budgetTemplate = 'budget.template';
  static const String budgetSavingPlan = 'budget.savingPlan';
  static const String budgetLeftoverDone = 'budget.leftoverDone';
  static const String billReminderHour = 'bills.reminderHour';

  /// Tanggal gajian 1–31 untuk Jatah hari ini (bawaan 1 = bulan kalender).
  static const String allowancePayday = 'allowance.payday';

  /// ID dompet yang tidak ikut dihitung di Jatah hari ini, dipisah koma.
  static const String allowanceExcluded = 'allowance.excludedWallets';

  /// Favorit "Sekali ketuk" yang dipasang manual (JSON) dan kunci favorit
  /// otomatis yang disembunyikan (JSON).
  static const String favoritesPinned = 'favorites.pinned';
  static const String favoritesHidden = 'favorites.hidden';

  /// Gaya widget layar utama per id widget (JSON, P2b).
  static const String widgetStyles = 'widget.styles';

  /// Urutan & kartu Beranda yang disembunyikan (JSON, P2b Pro).
  static const String homeLayout = 'home.layout';

  /// Rekap mingguan (P3a): notifikasi Senin, pengingat malam, minggu yang
  /// kartu rekapnya ditutup di Beranda (yyyy-mm-dd Senin).
  static const String recapWeekly = 'recap.weekly';
  static const String recapEvening = 'recap.evening';
  static const String recapDismissed = 'recap.dismissed';

  /// Info transfer patungan terakhir ("BCA 123… a.n. …") dan apakah disertakan (P3c).
  static const String splitTransfer = 'split.transfer';
  static const String splitTransferOn = 'split.transferOn';

  /// Rapor bulanan (P3d): notifikasi tanggal 1 (bawaan menyala) & bulan
  /// yang kartu Rapor-nya ditutup di Beranda (yyyy-mm).
  static const String raporMonthly = 'rapor.monthly';
  static const String raporDismissed = 'rapor.dismissed';

  /// Kuota Scan struk versi gratis (P3e): bulan (yyyy-mm) & jumlah dipakai.
  static const String scanMonth = 'scan.month';
  static const String scanCount = 'scan.count';

  /// Kartu kenalan Scan struk di Beranda sudah ditutup / scan pernah dipakai.
  static const String scanIntro = 'scan.intro';
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<String?> read(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).map((s) => s.value).getSingleOrNull();

  Stream<String?> watch(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).map((s) => s.value).watchSingleOrNull();

  Future<Map<String, String>> readAll() async => {for (final Setting s in await select(settings).get()) s.key: s.value};

  Future<void> write(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> remove(String key) => (delete(settings)..where((s) => s.key.equals(key))).go();
}
