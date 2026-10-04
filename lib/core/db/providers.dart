import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'connection.dart';

/// Satu instance database untuk seluruh aplikasi. Di tes, override
/// dengan `AppDatabase(NativeDatabase.memory())`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase(openEncryptedConnection());
  ref.onDispose(db.close);
  return db;
});
