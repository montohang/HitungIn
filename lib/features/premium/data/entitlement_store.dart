import 'dart:convert';

import '../../../core/security/secure_store.dart';

/// Bukti pembelian Pro yang disimpan di perangkat (Keystore), supaya
/// status Pro tetap berlaku tanpa internet. Disinkronkan ulang dari
/// Google Play lewat "Pulihkan pembelian".
class EntitlementStore {
  EntitlementStore(this._store);

  static const String _key = 'hitungin.pro.v1';
  final SecureStore _store;

  Future<bool> isPro() async => await read() != null;

  Future<({String productId, String purchaseId, DateTime grantedAt})?> read() async {
    final String? raw = await _store.read(_key);
    if (raw == null) return null;
    try {
      final Map<String, Object?> j = Map<String, Object?>.from(jsonDecode(raw) as Map);
      return (
        productId: j['productId']! as String,
        purchaseId: j['purchaseId'] as String? ?? '',
        grantedAt: DateTime.parse(j['grantedAt']! as String),
      );
    } on Object {
      return null;
    }
  }

  Future<void> grant({required String productId, required String purchaseId, required DateTime at}) => _store.write(
        _key,
        jsonEncode({'productId': productId, 'purchaseId': purchaseId, 'grantedAt': at.toIso8601String()}),
      );

  Future<void> revoke() => _store.delete(_key);
}
