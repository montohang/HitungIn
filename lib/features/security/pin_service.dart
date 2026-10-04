import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/secure_store.dart';
import 'pin_hasher.dart';

/// Hasil memasukkan PIN di layar kunci.
sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  const PinOk();
}

class PinWrong extends PinResult {
  const PinWrong(this.attemptsLeft);

  /// Sisa percobaan sebelum dikunci sementara.
  final int attemptsLeft;
}

class PinLockedOut extends PinResult {
  const PinLockedOut(this.until);
  final DateTime until;
}

/// Menyimpan & memeriksa PIN, menghitung percobaan gagal, dan menunda
/// percobaan setelah terlalu sering salah: 5 kali salah → tunggu 30 detik,
/// lalu berlipat (1 mnt, 2 mnt, …) sampai maksimal 15 menit. Hitungan
/// disimpan di SecureStore supaya tidak hilang saat aplikasi ditutup paksa.
class PinService {
  PinService(
    this._store, {
    DateTime Function()? clock,
    this.iterations = PinHasher.defaultIterations,
    this.useIsolate = true,
  }) : _now = clock ?? DateTime.now;

  static const int pinLength = 6;
  static const int attemptsPerRound = 5;
  static const Duration firstLockout = Duration(seconds: 30);
  static const Duration maxLockout = Duration(minutes: 15);

  static const String _kHash = 'hitungin.pin.hash';
  static const String _kFailed = 'hitungin.pin.failed';
  static const String _kLockedUntil = 'hitungin.pin.lockedUntil';
  static const String _kBiometric = 'hitungin.pin.biometric';

  final SecureStore _store;
  final DateTime Function() _now;
  final int iterations;
  final bool useIsolate;

  Future<bool> hasPin() async => await _store.read(_kHash) != null;

  Future<void> setPin(String pin) async {
    if (!isValidFormat(pin)) throw ArgumentError('PIN harus $pinLength digit angka');
    await _store.write(_kHash, await PinHasher.hash(pin, iterations: iterations, useIsolate: useIsolate));
    await _resetAttempts();
  }

  static bool isValidFormat(String pin) => RegExp('^[0-9]{$pinLength}\$').hasMatch(pin);

  /// Jangan izinkan PIN yang terlalu mudah ditebak.
  static bool isTooSimple(String pin) {
    if (pin.split('').toSet().length == 1) return true; // 111111
    const String up = '01234567890';
    const String down = '09876543210';
    return up.contains(pin) || down.contains(pin); // 123456, 654321
  }

  /// Kapan boleh mencoba lagi, bila sedang dikunci sementara.
  Future<DateTime?> lockedUntil() async {
    final DateTime? until = DateTime.tryParse(await _store.read(_kLockedUntil) ?? '');
    if (until == null || !until.isAfter(_now())) return null;
    return until;
  }

  Future<PinResult> verify(String pin) async {
    final DateTime? until = await lockedUntil();
    if (until != null) return PinLockedOut(until);

    final String? hash = await _store.read(_kHash);
    if (hash != null && await PinHasher.verify(pin, hash, useIsolate: useIsolate)) {
      await _resetAttempts();
      return const PinOk();
    }

    final int failed = int.parse(await _store.read(_kFailed) ?? '0') + 1;
    await _store.write(_kFailed, '$failed');
    if (failed % attemptsPerRound != 0) return PinWrong(attemptsPerRound - failed % attemptsPerRound);

    final int round = failed ~/ attemptsPerRound; // 1, 2, 3, …
    final Duration wait = firstLockout * (1 << (round - 1).clamp(0, 10));
    final DateTime lockUntil = _now().add(wait > maxLockout ? maxLockout : wait);
    await _store.write(_kLockedUntil, lockUntil.toIso8601String());
    return PinLockedOut(lockUntil);
  }

  /// Ganti PIN: PIN lama diperiksa dengan aturan percobaan yang sama
  /// seperti layar kunci. PIN baru hanya disimpan bila hasilnya [PinOk].
  Future<PinResult> changePin(String oldPin, String newPin) async {
    if (!isValidFormat(newPin)) throw ArgumentError('PIN harus $pinLength digit angka');
    final PinResult r = await verify(oldPin);
    if (r is PinOk) await setPin(newPin);
    return r;
  }

  Future<bool> biometricEnabled() async => await _store.read(_kBiometric) == 'true';

  Future<void> setBiometricEnabled(bool value) => _store.write(_kBiometric, '$value');

  /// Dipanggil setelah buka kunci lewat biometrik.
  Future<void> resetAttempts() => _resetAttempts();

  Future<void> _resetAttempts() async {
    await _store.delete(_kFailed);
    await _store.delete(_kLockedUntil);
  }
}

final pinServiceProvider = Provider<PinService>(
  (ref) => PinService(ref.watch(secureStoreProvider), clock: ref.watch(clockProvider)),
);
