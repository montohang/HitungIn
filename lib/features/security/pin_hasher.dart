import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PIN tidak pernah disimpan apa adanya — hanya hasil PBKDF2-HMAC-SHA256
/// dengan garam acak. Format: `pbkdf2-sha256$<iterasi>$<garam>$<hash>`
/// (base64). Jumlah iterasi ikut disimpan supaya bisa dinaikkan nanti.
abstract final class PinHasher {
  static const int defaultIterations = 60000;
  static const String _scheme = 'pbkdf2-sha256';

  /// Dijalankan di isolate terpisah agar UI tidak tersendat
  /// ([useIsolate] = false hanya untuk widget test).
  static Future<String> hash(String pin, {int iterations = defaultIterations, bool useIsolate = true}) async {
    final Uint8List salt = _randomBytes(16);
    String run() => _encode(iterations, salt, _pbkdf2(utf8.encode(pin), salt, iterations));
    return useIsolate ? Isolate.run(run) : run();
  }

  static Future<bool> verify(String pin, String encoded, {bool useIsolate = true}) async {
    final List<String> parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final int? iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1) return false;
    final Uint8List salt = base64.decode(parts[2]);
    final Uint8List expected = base64.decode(parts[3]);
    Uint8List run() => _pbkdf2(utf8.encode(pin), salt, iterations);
    final Uint8List actual = useIsolate ? await Isolate.run(run) : run();
    return _constantTimeEquals(actual, expected);
  }

  static String _encode(int iterations, Uint8List salt, Uint8List hash) =>
      '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(hash)}';

  /// PBKDF2 satu blok (32 byte = panjang SHA-256).
  static Uint8List _pbkdf2(List<int> password, Uint8List salt, int iterations) {
    final Hmac hmac = Hmac(sha256, password);
    List<int> u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final Uint8List out = Uint8List.fromList(u);
    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Uint8List _randomBytes(int n) {
    final Random rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rng.nextInt(256)));
  }
}
