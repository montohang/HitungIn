import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan kecil yang dienkripsi Keystore (PIN, percobaan gagal).
/// Dibuat sebagai antarmuka supaya bisa diganti versi memori di tes.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Untuk tes.
class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

final secureStoreProvider = Provider<SecureStore>((ref) => const FlutterSecureStore());

/// Jam yang bisa diganti di tes.
final clockProvider = Provider<DateTime Function()>((ref) {
  final Duration shift = ref.watch(debugClockShiftProvider);
  return shift == Duration.zero ? DateTime.now : () => DateTime.now().add(shift);
});

/// Geser jam aplikasi untuk uji di HP (menu debug "Lompat ke tanggal 1 bulan
/// depan"). Tanggal HP tidak diubah. Selalu nol di build rilis.
final debugClockShiftProvider = StateProvider<Duration>((ref) => Duration.zero);
