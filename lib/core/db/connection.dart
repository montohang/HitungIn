import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'db_key.dart';

const String dbFileName = 'hitungin.db';

/// Membuka database terenkripsi SQLCipher di folder data aplikasi.
/// SQLCipher dibundel lewat `hooks.user_defines.sqlite3.source` di pubspec.
QueryExecutor openEncryptedConnection({DbKeyStore? keyStore}) {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationSupportDirectory();
    final File file = File(p.join(dir.path, dbFileName));
    final String hexKey = await (keyStore ?? DbKeyStore()).readOrCreate();
    return NativeDatabase.createInBackground(file, setup: (db) => applyCipherKey(db, hexKey));
  });
}

/// Wajib dipanggil sebelum perintah lain apa pun pada koneksi baru.
void applyCipherKey(Database db, String hexKey) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hexKey)) {
    throw ArgumentError('Kunci database tidak valid');
  }
  // Pastikan yang termuat benar-benar SQLCipher — jangan sampai data
  // tersimpan tanpa enkripsi karena salah konfigurasi build.
  if (db.select('PRAGMA cipher_version').isEmpty) {
    throw StateError('SQLCipher tidak tersedia; periksa hooks.user_defines di pubspec.yaml');
  }
  db.execute('PRAGMA key = "x\'$hexKey\'"');
  // Gagal di sini berarti kunci salah atau file rusak.
  db.select('SELECT count(*) FROM sqlite_master');
}
