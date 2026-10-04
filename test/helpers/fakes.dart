import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/providers.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/security/app_gate.dart';
import 'package:hitungin/features/security/biometric_service.dart';
import 'package:hitungin/features/security/pin_service.dart';

class FakeBiometric implements BiometricService {
  FakeBiometric({this.available = false, this.result = true});

  bool available;
  bool result;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return result;
  }
}

/// Jam palsu yang bisa dimajukan.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 2, 8);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

/// Semua dependensi aplikasi versi tes (DB memori, PIN cepat, tanpa Keystore).
class TestEnv {
  TestEnv({GateState gate = const GateState(), bool biometric = false})
      : initialGate = gate,
        biometric = FakeBiometric(available: biometric) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  final MemorySecureStore store = MemorySecureStore();
  final FakeClock clock = FakeClock();
  final FakeBiometric biometric;
  final GateState initialGate;

  late final PinService pin = PinService(store, clock: clock.call, iterations: 10, useIsolate: false);

  List<Override> get overrides => [
        appDatabaseProvider.overrideWithValue(db),
        secureStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(clock.call),
        pinServiceProvider.overrideWithValue(pin),
        biometricServiceProvider.overrideWithValue(biometric),
        initialGateProvider.overrideWithValue(initialGate),
      ];
}
