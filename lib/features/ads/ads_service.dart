import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Iklan AdMob. Tidak ada data keuangan yang dikirim: permintaan iklan
/// polos tanpa kata kunci/penargetan konten.
abstract interface class AdsService {
  /// Minta persetujuan (UMP) bila diwajibkan, lalu inisialisasi SDK.
  /// True bila iklan boleh diminta.
  Future<bool> init();

  /// Ada pengaturan privasi iklan yang bisa dibuka pengguna (mis. di EEA).
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();

  /// Putar iklan berhadiah. True bila pengguna menonton sampai dapat hadiah.
  Future<bool> showRewarded();
}

class AdMobService implements AdsService {
  Future<bool>? _init;

  @override
  Future<bool> init() => _init ??= _doInit();

  Future<bool> _doInit() async {
    final Completer<void> updated = Completer<void>();
    void done([Object? _]) {
      if (!updated.isCompleted) updated.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired(done),
      done,
    );
    await updated.future;
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  }

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() {
    final Completer<void> done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) => done.complete());
    return done.future;
  }

  @override
  Future<bool> showRewarded() async {
    if (!await init()) return false;
    final Completer<RewardedAd?> loaded = Completer<RewardedAd?>();
    await RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (e) {
          debugPrint('Rewarded gagal dimuat: $e');
          loaded.complete(null);
        },
      ),
    );
    final RewardedAd? ad = await loaded.future;
    if (ad == null) return false;

    final Completer<bool> result = Completer<bool>();
    bool earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!result.isCompleted) result.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return result.future;
  }
}

/// Untuk tes & perangkat tanpa Google Play.
class NoAdsService implements AdsService {
  const NoAdsService();

  @override
  Future<bool> init() async => false;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<bool> showRewarded() async => false;
}

final adsServiceProvider = Provider<AdsService>((ref) => AdMobService());

/// True setelah persetujuan beres & SDK siap.
final adsReadyProvider = StateProvider<bool>((ref) => false);
