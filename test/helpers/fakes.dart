import 'dart:async';

import 'package:drift/drift.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/providers.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/ads/ads_service.dart';
import 'package:hitungin/features/premium/data/billing.dart';
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

/// Google Play palsu: pembelian dikirim manual lewat [emit].
class FakeBilling implements BillingGateway {
  final StreamController<List<PurchaseDetails>> _ctl = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  ProductDetails? productDetails = ProductDetails(
    id: proProductId,
    title: 'HitungIn Pro',
    description: 'Sekali bayar',
    price: 'Rp59.000',
    rawPrice: 59000,
    currencyCode: 'IDR',
  );
  int buys = 0;
  int restores = 0;
  final List<PurchaseDetails> completed = [];

  void emit(List<PurchaseDetails> p) => _ctl.add(p);

  @override
  Stream<List<PurchaseDetails>> get purchases => _ctl.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetails?> product(String id) async => productDetails;

  @override
  Future<bool> buy(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<void> restore() async => restores++;

  @override
  Future<void> complete(PurchaseDetails purchase) async => completed.add(purchase);
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
  final FakeBilling billing = FakeBilling();
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
        adsServiceProvider.overrideWithValue(const NoAdsService()),
        billingGatewayProvider.overrideWithValue(billing),
      ];
}
