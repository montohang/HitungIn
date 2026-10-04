import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kunci enkripsi database (256-bit acak), disimpan di Android Keystore
/// lewat flutter_secure_storage. Kunci tidak pernah keluar dari HP;
/// cadangan data memakai kata sandi terpisah (tahap Backup).
class DbKeyStore {
  DbKeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _storageKey = 'hitungin.db_key.v1';

  final FlutterSecureStorage _storage;

  /// Kunci dalam bentuk hex 64 karakter. Dibuat sekali saat pertama dipakai.
  Future<String> readOrCreate() async {
    final String? existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.length == 64) return existing;
    final String key = generate();
    await _storage.write(key: _storageKey, value: key);
    return key;
  }

  static String generate() {
    final Random rng = Random.secure();
    return List<String>.generate(32, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
