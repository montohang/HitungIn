import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../settings/data/settings_dao.dart';

/// Pilihan "Kunci otomatis" di Pengaturan.
enum AutoLockDelay {
  segera('Segera', Duration.zero),
  detik30('Setelah 30 detik', Duration(seconds: 30)),
  menit1('Setelah 1 menit', Duration(minutes: 1)),
  menit5('Setelah 5 menit', Duration(minutes: 5));

  const AutoLockDelay(this.label, this.duration);
  final String label;
  final Duration duration;

  static const AutoLockDelay fallback = AutoLockDelay.detik30;

  static AutoLockDelay parse(String? name) =>
      AutoLockDelay.values.where((d) => d.name == name).firstOrNull ?? fallback;
}

Future<AutoLockDelay> loadAutoLockDelay(SettingsDao dao) async => AutoLockDelay.parse(await dao.read(SettingKeys.autoLock));

/// Dibaca sebelum `runApp`. Di tes dibiarkan default.
final initialAutoLockProvider = Provider<AutoLockDelay>((ref) => AutoLockDelay.fallback);

class AutoLockController extends Notifier<AutoLockDelay> {
  @override
  AutoLockDelay build() => ref.read(initialAutoLockProvider);

  Future<void> set(AutoLockDelay delay) async {
    state = delay;
    await ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.autoLock, delay.name);
  }
}

final autoLockProvider = NotifierProvider<AutoLockController, AutoLockDelay>(AutoLockController.new);
