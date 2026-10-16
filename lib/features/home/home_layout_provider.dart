import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import '../premium/pro_controller.dart';
import '../settings/data/settings_dao.dart';
import 'data/home_layout.dart';

/// Susunan tersimpan (apa pun status Pro).
final savedHomeLayoutProvider = StreamProvider<HomeLayout>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.homeLayout).map(HomeLayout.decode),
);

/// Susunan yang dipakai Beranda: kustom hanya untuk Pro.
final homeLayoutProvider = Provider<HomeLayout>((ref) {
  if (!ref.watch(isProProvider)) return HomeLayout.standard;
  return ref.watch(savedHomeLayoutProvider).valueOrNull ?? HomeLayout.standard;
});

Future<void> saveHomeLayout(SettingsDao dao, HomeLayout layout) => dao.write(SettingKeys.homeLayout, layout.encode());
