import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// ID produk sekali beli di Play Console (Produk dalam aplikasi → Kelola).
const String proProductId = 'hitungin_pro';

/// Pembelian yang masih dimiliki akun Google Play saat ini (per ID produk).
/// Pembelian yang di-refund/dicabut tidak muncul lagi di sini.
typedef OwnedPurchases = ({Set<String> purchased, Set<String> pending});

/// Pembungkus Google Play Billing supaya bisa dipalsukan di tes.
abstract interface class BillingGateway {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<ProductDetails?> product(String id);
  Future<bool> buy(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);

  /// Daftar pembelian yang dimiliki menurut Google Play, atau null bila
  /// tidak bisa dipastikan (Play error / tidak tersedia).
  Future<OwnedPurchases?> owned();
}

class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchases => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetails?> product(String id) async {
    final ProductDetailsResponse r = await _iap.queryProductDetails({id});
    return r.productDetails.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<bool> buy(ProductDetails product) => _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) => _iap.completePurchase(purchase);

  @override
  Future<OwnedPurchases?> owned() async {
    final InAppPurchaseAndroidPlatformAddition android =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final QueryPurchaseDetailsResponse r = await android.queryPastPurchases();
    if (r.error != null) return null;
    return (
      purchased: {
        for (final PurchaseDetails p in r.pastPurchases)
          if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) p.productID,
      },
      pending: {
        for (final PurchaseDetails p in r.pastPurchases)
          if (p.status == PurchaseStatus.pending) p.productID,
      },
    );
  }
}

final billingGatewayProvider = Provider<BillingGateway>((ref) => PlayBillingGateway());
