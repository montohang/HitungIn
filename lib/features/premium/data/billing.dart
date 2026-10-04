import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// ID produk sekali beli di Play Console (Produk dalam aplikasi → Kelola).
const String proProductId = 'hitungin_pro';

/// Pembungkus Google Play Billing supaya bisa dipalsukan di tes.
abstract interface class BillingGateway {
  Stream<List<PurchaseDetails>> get purchases;
  Future<bool> isAvailable();
  Future<ProductDetails?> product(String id);
  Future<bool> buy(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
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
}

final billingGatewayProvider = Provider<BillingGateway>((ref) => PlayBillingGateway());
