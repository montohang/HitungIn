import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/security/secure_store.dart';
import 'data/billing.dart';
import 'data/entitlement_store.dart';

@immutable
class ProState {
  const ProState({this.isPro = false, this.pending = false, this.busy = false, this.price, this.error, this.available = true});

  final bool isPro;

  /// Pembayaran sedang diproses di luar aplikasi (minimarket, pulsa, transfer).
  final bool pending;

  /// Sedang membuka Google Play / memulihkan.
  final bool busy;

  /// Harga dari Google Play (sudah terformat), null bila belum dimuat.
  final String? price;
  final String? error;

  /// Google Play Billing tersedia di perangkat ini.
  final bool available;

  ProState copyWith({bool? isPro, bool? pending, bool? busy, String? price, String? error, bool clearError = false, bool? available}) =>
      ProState(
        isPro: isPro ?? this.isPro,
        pending: pending ?? this.pending,
        busy: busy ?? this.busy,
        price: price ?? this.price,
        error: clearError ? null : (error ?? this.error),
        available: available ?? this.available,
      );
}

/// Status Pro yang sudah tersimpan, dibaca sebelum `runApp`.
final initialProProvider = Provider<bool>((ref) => false);

final entitlementStoreProvider = Provider<EntitlementStore>((ref) => EntitlementStore(ref.watch(secureStoreProvider)));

/// Pembelian HitungIn Pro (sekali bayar) lewat Google Play.
/// Tanpa server: pembelian dianggap sah bila Google Play melaporkannya
/// sebagai purchased/restored untuk [proProductId].
class ProController extends Notifier<ProState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  @override
  ProState build() {
    _sub = ref.read(billingGatewayProvider).purchases.listen(handle, onError: (Object _) {});
    ref.onDispose(() => _sub?.cancel());
    return ProState(isPro: ref.read(initialProProvider));
  }

  BillingGateway get _billing => ref.read(billingGatewayProvider);

  /// Ambil harga dari Google Play (untuk layar Pro).
  Future<void> loadProduct() async {
    if (!await _billing.isAvailable()) {
      state = state.copyWith(available: false);
      return;
    }
    _product = await _billing.product(proProductId);
    state = state.copyWith(available: true, price: _product?.price);
  }

  Future<void> buy() async {
    if (state.isPro || state.busy) return;
    if (_product == null) await loadProduct();
    final ProductDetails? p = _product;
    if (p == null) {
      state = state.copyWith(error: 'Produk belum tersedia di Google Play. Coba lagi nanti.');
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _billing.buy(p);
    } on Object {
      state = state.copyWith(busy: false, error: 'Tidak bisa membuka Google Play.');
    }
  }

  /// "Pulihkan pembelian" (mis. setelah instal ulang atau ganti HP).
  /// [silent] = pemeriksaan otomatis saat aplikasi dibuka (tanpa pesan).
  Future<void> restore({bool silent = false}) async {
    if (!silent) state = state.copyWith(busy: true, clearError: true);
    try {
      if (!await _billing.isAvailable()) {
        if (!silent) state = state.copyWith(error: 'Google Play tidak tersedia di perangkat ini.');
        return;
      }
      await _billing.restore();
      final bool? found = await syncWithPlay();
      if (!silent && found == false && !state.pending) {
        state = state.copyWith(error: 'Belum ada pembelian HitungIn Pro di akun Google Play ini.');
      }
    } on Object {
      if (!silent) state = state.copyWith(error: 'Gagal menghubungi Google Play.');
    } finally {
      if (!silent) state = state.copyWith(busy: false);
    }
  }

  /// Samakan status Pro dengan daftar pembelian di Google Play: aktifkan bila
  /// dimiliki, cabut bila sudah tidak ada (refund/dibatalkan). Bila Play tidak
  /// bisa dipastikan (offline/error), status Pro yang tersimpan dibiarkan.
  /// Mengembalikan true/false = Pro dimiliki/tidak, null = tidak diketahui.
  Future<bool?> syncWithPlay() async {
    final OwnedPurchases? owned = await _billing.owned();
    if (owned == null) return null;
    final EntitlementStore store = ref.read(entitlementStoreProvider);
    if (owned.purchased.contains(proProductId)) {
      if (!await store.isPro()) {
        await store.grant(productId: proProductId, purchaseId: '', at: ref.read(clockProvider)());
      }
      state = state.copyWith(isPro: true, pending: false);
      return true;
    }
    final bool pending = owned.pending.contains(proProductId);
    final entitlement = await store.read();
    // Mode Pro (uji) di build debug tidak punya pembelian di Play.
    final bool debugGrant = kDebugMode && entitlement?.purchaseId == 'debug';
    if (entitlement != null && !debugGrant) {
      await store.revoke();
      state = state.copyWith(
        isPro: false,
        pending: pending,
        error: 'Pembelian HitungIn Pro tidak lagi tercatat di Google Play (mis. dana dikembalikan).',
      );
    } else if (pending != state.pending) {
      state = state.copyWith(pending: pending);
    }
    return false;
  }

  /// "Mode Pro (uji)" di build debug: aktifkan/matikan Pro tanpa Google Play,
  /// untuk menguji fitur Pro. Tidak bisa dipanggil di build rilis.
  Future<void> debugSetPro(bool on) async {
    if (!kDebugMode) return;
    final store = ref.read(entitlementStoreProvider);
    if (on) {
      await store.grant(productId: proProductId, purchaseId: 'debug', at: ref.read(clockProvider)());
    } else {
      await store.revoke();
    }
    state = state.copyWith(isPro: on, pending: false, clearError: true);
  }

  @visibleForTesting
  Future<void> handle(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails p in purchases) {
      if (p.productID != proProductId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(pending: true, busy: false, clearError: true);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          await ref.read(entitlementStoreProvider).grant(
                productId: p.productID,
                purchaseId: p.purchaseID ?? '',
                at: ref.read(clockProvider)(),
              );
          state = state.copyWith(isPro: true, pending: false, busy: false, clearError: true);
        case PurchaseStatus.error:
          state = state.copyWith(pending: false, busy: false, error: 'Pembayaran gagal. Tidak ada biaya yang ditagih.');
        case PurchaseStatus.canceled:
          state = state.copyWith(pending: false, busy: false);
      }
      // Wajib diakui dalam 3 hari; kalau tidak, Google Play mengembalikan dana.
      if (p.pendingCompletePurchase) await _billing.complete(p);
    }
  }
}

final proControllerProvider = NotifierProvider<ProController, ProState>(ProController.new);

/// Pintasan yang paling sering dipakai layar.
final isProProvider = Provider<bool>((ref) => ref.watch(proControllerProvider.select((s) => s.isPro)));
