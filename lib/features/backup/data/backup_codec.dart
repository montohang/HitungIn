import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Berkas bukan cadangan HitungIn, rusak, atau dari versi yang lebih baru.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Kata sandi salah (atau isi berkas sudah diubah).
class BackupPasswordException implements Exception {
  const BackupPasswordException();

  @override
  String toString() => 'Kata sandi salah atau berkas rusak';
}

/// Enkripsi berkas cadangan dengan kata sandi pilihan pengguna.
///
/// Susunan berkas (big-endian):
/// `HITUNGIN-BAK` (12) · versi (1) · iterasi (4) · garam (16) · nonce (12)
/// · ciphertext · MAC (16).
/// Isi = JSON → gzip → AES-256-GCM, kunci = PBKDF2-HMAC-SHA256(kata sandi).
/// Seluruh header ikut diautentikasi (AAD), jadi header yang diubah ditolak.
abstract final class BackupCodec {
  static const String extension = 'hitungin';
  static final Uint8List _magic = Uint8List.fromList(ascii.encode('HITUNGIN-BAK'));
  static const int _version = 1;
  static const int defaultIterations = 150000;
  static const int minPasswordLength = 8;
  static const int _headerLength = 12 + 1 + 4 + 16 + 12;

  static Future<Uint8List> encrypt(
    Map<String, Object?> data,
    String password, {
    int iterations = defaultIterations,
  }) async {
    final Uint8List salt = _random(16);
    final Uint8List nonce = _random(12);
    final Uint8List header = (BytesBuilder()
          ..add(_magic)
          ..addByte(_version)
          ..add(_uint32(iterations))
          ..add(salt)
          ..add(nonce))
        .toBytes();
    final List<int> plain = gzip.encode(utf8.encode(jsonEncode(data)));
    final SecretKey key = await _deriveKey(password, salt, iterations);
    final SecretBox box = await AesGcm.with256bits().encrypt(plain, secretKey: key, nonce: nonce, aad: header);
    return (BytesBuilder()
          ..add(header)
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .toBytes();
  }

  static Future<Map<String, Object?>> decrypt(Uint8List bytes, String password) async {
    if (bytes.length < _headerLength + 16 || !_startsWithMagic(bytes)) {
      throw const BackupFormatException('Ini bukan berkas cadangan HitungIn.');
    }
    if (bytes[12] > _version) {
      throw const BackupFormatException('Cadangan dibuat oleh versi HitungIn yang lebih baru. Perbarui aplikasi dulu.');
    }
    final int iterations = ByteData.sublistView(bytes, 13, 17).getUint32(0);
    if (iterations < 1 || iterations > 10000000) throw const BackupFormatException('Berkas cadangan rusak.');
    final Uint8List header = bytes.sublist(0, _headerLength);
    final Uint8List salt = bytes.sublist(17, 33);
    final Uint8List nonce = bytes.sublist(33, 45);
    final Uint8List cipher = bytes.sublist(_headerLength, bytes.length - 16);
    final Uint8List mac = bytes.sublist(bytes.length - 16);

    final SecretKey key = await _deriveKey(password, salt, iterations);
    final List<int> plain;
    try {
      plain = await AesGcm.with256bits().decrypt(SecretBox(cipher, nonce: nonce, mac: Mac(mac)), secretKey: key, aad: header);
    } on SecretBoxAuthenticationError {
      throw const BackupPasswordException();
    }
    try {
      final Object? json = jsonDecode(utf8.decode(gzip.decode(plain)));
      if (json is! Map<String, Object?>) throw const FormatException();
      return json;
    } on FormatException {
      throw const BackupFormatException('Isi cadangan rusak.');
    }
  }

  /// PBKDF2 berat — dijalankan di isolate supaya UI tidak macet.
  static Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) async {
    final List<int> bytes = await Isolate.run(() async {
      final SecretKey k = await Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKeyFromPassword(password: password, nonce: salt);
      return k.extractBytes();
    });
    return SecretKey(bytes);
  }

  static bool _startsWithMagic(Uint8List b) {
    for (int i = 0; i < _magic.length; i++) {
      if (b[i] != _magic[i]) return false;
    }
    return true;
  }

  static Uint8List _uint32(int v) => (ByteData(4)..setUint32(0, v)).buffer.asUint8List();

  static Uint8List _random(int n) {
    final Random rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rng.nextInt(256)));
  }
}
