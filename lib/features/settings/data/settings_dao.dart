import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'settings_dao.g.dart';

/// Kunci pengaturan yang dikenal. Tambahkan di sini, jangan menulis
/// string kunci langsung di layar.
abstract final class SettingKeys {
  static const String themeMode = 'theme.mode';
  static const String themeAccent = 'theme.accent';
  static const String themeGradientCard = 'theme.gradientCard';
  static const String onboardingDone = 'onboarding.done';
  static const String userName = 'user.name';
  static const String autoLock = 'security.autoLock';
  static const String billReminders = 'bills.reminders';
  static const String lastBackupAt = 'backup.lastAt';
  static const String hideBalance = 'home.hideBalance';
  static const String billReminderHour = 'bills.reminderHour';
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
