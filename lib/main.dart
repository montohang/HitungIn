import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/app_database.dart';
import 'core/db/connection.dart';
import 'core/db/providers.dart';
import 'core/security/secure_store.dart';
import 'core/theme/theme_controller.dart';
import 'features/security/app_gate.dart';
import 'features/security/pin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Dibaca sebelum frame pertama supaya tema & layar awal langsung benar.
  final AppDatabase db = AppDatabase(openEncryptedConnection());
  final ThemeSettings theme = await loadThemeSettings(db.settingsDao);
  final GateState gate = await loadGateState(db.settingsDao, PinService(const FlutterSecureStore()));

  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      initialThemeSettingsProvider.overrideWithValue(theme),
      initialGateProvider.overrideWithValue(gate),
    ],
    child: const HitungInApp(),
  ));
}
