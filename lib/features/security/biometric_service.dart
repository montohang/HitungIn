import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Sidik jari / wajah. Antarmuka dipisah supaya bisa dipalsukan di tes.
abstract interface class BiometricService {
  /// HP punya sensor biometrik dan pengguna sudah mendaftarkannya.
  Future<bool> isAvailable();

  /// True bila berhasil. Gagal/dibatalkan → false (tidak melempar).
  Future<bool> authenticate(String reason);
}

class LocalBiometricService implements BiometricService {
  LocalBiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Buka HitungIn',
            signInHint: 'Sentuh sensor sidik jari',
            cancelButton: 'Pakai PIN',
          ),
        ],
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) => LocalBiometricService());
