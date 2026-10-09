import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/ads/ad_policy.dart';
import 'package:hitungin/features/premium/data/billing.dart';
import 'package:hitungin/features/premium/data/entitlement_store.dart';
import 'package:hitungin/features/premium/data/pro_limits.dart';
import 'package:hitungin/features/premium/pro_controller.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../helpers/fakes.dart';

PurchaseDetails _purchase(PurchaseStatus status, {String product = proProductId, bool pendingComplete = true}) =>
    PurchaseDetails(
      purchaseID: 'GPA.1234',
      productID: product,
      verificationData:
          PurchaseVerificationData(localVerificationData: '{}', serverVerificationData: 'token', source: 'google_play'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;

void main() {
  group('batas versi gratis', () {
    test('budget kategori: 2 gratis, Pro tanpa batas', () {
      expect(FreeLimits.canAddCategoryBudget(existing: 1, isPro: false), isTrue);
      expect(FreeLimits.canAddCategoryBudget(existing: 2, isPro: false), isFalse);
      expect(FreeLimits.canAddCategoryBudget(existing: 50, isPro: true), isTrue);
    });

    test('tagihan aktif: 3 gratis', () {
      expect(FreeLimits.canAddBill(active: 2, isPro: false), isTrue);
      expect(FreeLimits.canAddBill(active: 3, isPro: false), isFalse);
      expect(FreeLimits.canAddBill(active: 3, isPro: true), isTrue);
    });

    test('laporan: bulan ini & bulan lalu, termasuk lintas tahun', () {
      final now = DateTime(2026, 1, 15);
      expect(FreeLimits.canViewReport(DateTime(2026, 1), now, isPro: false), isTrue);
      expect(FreeLimits.canViewReport(DateTime(2025, 12), now, isPro: false), isTrue);
      expect(FreeLimits.canViewReport(DateTime(2025, 11), now, isPro: false), isFalse);
      expect(FreeLimits.canViewReport(DateTime(2020, 1), now, isPro: true), isTrue);
    });

    test('CSV: Pro atau setelah iklan berhadiah', () {
      expect(FreeLimits.canExportCsv(isPro: false, rewardEarned: false), isFalse);
      expect(FreeLimits.canExportCsv(isPro: false, rewardEarned: true), isTrue);
      expect(FreeLimits.canExportCsv(isPro: true, rewardEarned: false), isTrue);
    });

    test('alasan Pro dari URL', () {
      expect(ProReason.parse('csv'), ProReason.csv);
      expect(ProReason.parse('ngawur'), ProReason.umum);
      expect(ProReason.parse(null), ProReason.umum);
    });
  });

  group('aturan iklan', () {
    test('banner hanya di Beranda, Laporan & Budget — dan tidak untuk Pro', () {
      for (final tab in [0, 1, 2]) {
        expect(AdPolicy.showBanner(tab: tab, isPro: false, adsReady: true), isTrue);
      }
      expect(AdPolicy.showBanner(tab: 3, isPro: false, adsReady: true), isFalse, reason: 'Lainnya');
      expect(AdPolicy.showBanner(tab: 0, isPro: true, adsReady: true), isFalse);
      expect(AdPolicy.showBanner(tab: 0, isPro: false, adsReady: false), isFalse, reason: 'belum ada persetujuan');
    });

    test('iklan berhadiah hanya ditawarkan ke pengguna gratis yang siap iklan', () {
      expect(AdPolicy.offerRewarded(isPro: false, adsReady: true), isTrue);
      expect(AdPolicy.offerRewarded(isPro: true, adsReady: true), isFalse);
      expect(AdPolicy.offerRewarded(isPro: false, adsReady: false), isFalse);
    });
  });

  group('EntitlementStore', () {
    test('grant → tersimpan, revoke → hilang, data rusak dianggap bukan Pro', () async {
      final mem = MemorySecureStore();
      final store = EntitlementStore(mem);
      expect(await store.isPro(), isFalse);
      await store.grant(productId: proProductId, purchaseId: 'GPA.1', at: DateTime(2026, 10, 4));
      expect(await store.isPro(), isTrue);
      expect((await store.read())!.purchaseId, 'GPA.1');
      expect(await EntitlementStore(mem).isPro(), isTrue, reason: 'bertahan setelah aplikasi dibuka ulang');
      await store.revoke();
      expect(await store.isPro(), isFalse);
      mem.values['hitungin.pro.v1'] = '{rusak';
      expect(await store.isPro(), isFalse);
    });
  });

  group('ProController', () {
    late FakeBilling billing;
    late MemorySecureStore mem;
    late ProviderContainer container;

    ProviderContainer make({bool initialPro = false}) => ProviderContainer(overrides: [
          billingGatewayProvider.overrideWithValue(billing),
          secureStoreProvider.overrideWithValue(mem),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 4, 12)),
          initialProProvider.overrideWithValue(initialPro),
        ]);

    setUp(() {
      billing = FakeBilling();
      mem = MemorySecureStore();
      container = make();
    });
    tearDown(() => container.dispose());

    ProController ctl() => container.read(proControllerProvider.notifier);
    ProState state() => container.read(proControllerProvider);

    test('Mode Pro (uji) di debug: aktif & mati, tersimpan', () async {
      await ctl().debugSetPro(true);
      expect(state().isPro, isTrue);
      expect(await container.read(entitlementStoreProvider).isPro(), isTrue);
      await ctl().debugSetPro(false);
      expect(state().isPro, isFalse);
      expect(await container.read(entitlementStoreProvider).isPro(), isFalse);
    });

    test('memuat harga dari Google Play', () async {
      await ctl().loadProduct();
      expect(state().price, 'Rp59.000');
      expect(state().available, isTrue);
    });

    test('beli → purchased → Pro aktif, tersimpan, dan diakui (acknowledge)', () async {
      await ctl().buy();
      expect(billing.buys, 1);
      expect(state().busy, isTrue);

      await ctl().handle([_purchase(PurchaseStatus.purchased)]);
      expect(state().isPro, isTrue);
      expect(state().busy, isFalse);
      expect(container.read(isProProvider), isTrue);
      expect(await EntitlementStore(mem).isPro(), isTrue);
      expect(billing.completed, hasLength(1));

      await ctl().buy();
      expect(billing.buys, 1, reason: 'sudah Pro, tidak membuka Google Play lagi');
    });

    test('pembayaran tertunda (minimarket/pulsa) → menunggu, lalu aktif saat lunas', () async {
      await ctl().handle([_purchase(PurchaseStatus.pending, pendingComplete: false)]);
      expect(state().pending, isTrue);
      expect(state().isPro, isFalse);
      expect(billing.completed, isEmpty);

      await ctl().handle([_purchase(PurchaseStatus.purchased)]);
      expect(state().pending, isFalse);
      expect(state().isPro, isTrue);
    });

    test('pulihkan pembelian setelah instal ulang', () async {
      await ctl().restore();
      expect(billing.restores, 1);
      await ctl().handle([_purchase(PurchaseStatus.restored)]);
      expect(state().isPro, isTrue);
    });

    test('gagal / dibatalkan → tetap gratis, pesan jelas', () async {
      await ctl().handle([_purchase(PurchaseStatus.error)]);
      expect(state().isPro, isFalse);
      expect(state().error, contains('gagal'));
      await ctl().handle([_purchase(PurchaseStatus.canceled)]);
      expect(state().isPro, isFalse);
      expect(state().busy, isFalse);
    });

    test('refund: Play tidak lagi mencatat pembelian → Pro dicabut + pesan', () async {
      await ctl().handle([_purchase(PurchaseStatus.purchased)]);
      expect(state().isPro, isTrue);
      billing.ownedResult = (purchased: <String>{}, pending: <String>{});
      await ctl().restore(silent: true);
      expect(state().isPro, isFalse);
      expect(await EntitlementStore(mem).isPro(), isFalse);
      expect(state().error, contains('tidak lagi tercatat'));
    });

    test('Play offline/error → status Pro tersimpan tidak diubah', () async {
      await ctl().handle([_purchase(PurchaseStatus.purchased)]);
      billing.ownedResult = null;
      await ctl().restore(silent: true);
      expect(state().isPro, isTrue);
      expect(await EntitlementStore(mem).isPro(), isTrue);
    });

    test('instal ulang: Play mencatat pembelian → Pro aktif otomatis saat dibuka', () async {
      billing.ownedResult = (purchased: {proProductId}, pending: <String>{});
      await ctl().restore(silent: true);
      expect(state().isPro, isTrue);
      expect(await EntitlementStore(mem).isPro(), isTrue);
    });

    test('pembayaran masih tertunda di Play → menunggu, belum Pro', () async {
      billing.ownedResult = (purchased: <String>{}, pending: {proProductId});
      await ctl().restore(silent: true);
      expect(state().isPro, isFalse);
      expect(state().pending, isTrue);
    });

    test('Pulihkan tanpa pembelian → pesan jelas', () async {
      await ctl().restore();
      expect(state().isPro, isFalse);
      expect(state().busy, isFalse);
      expect(state().error, contains('Belum ada pembelian'));
    });

    test('Mode Pro (uji) debug tidak dicabut oleh pemeriksaan Play', () async {
      await ctl().debugSetPro(true);
      await ctl().restore(silent: true);
      expect(state().isPro, isTrue);
    });

    test('produk lain diabaikan', () async {
      await ctl().handle([_purchase(PurchaseStatus.purchased, product: 'produk_lain')]);
      expect(state().isPro, isFalse);
      expect(billing.completed, isEmpty);
    });

    test('Google Play tidak tersedia / produk belum ada', () async {
      billing.available = false;
      await ctl().loadProduct();
      expect(state().available, isFalse);
      billing
        ..available = true
        ..productDetails = null;
      await ctl().buy();
      expect(billing.buys, 0);
      expect(state().error, contains('belum tersedia'));
    });

    test('status Pro tersimpan dibaca saat aplikasi dibuka', () {
      final c = make(initialPro: true);
      expect(c.read(isProProvider), isTrue);
      c.dispose();
    });

    test('pembelian lewat stream Google Play juga diproses', () async {
      ctl(); // mulai mendengarkan
      billing.emit([_purchase(PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(state().isPro, isTrue);
    });
  });
}
