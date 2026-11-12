import 'package:flutter/foundation.dart';

/// ID unit iklan AdMob (aplikasi HitungIn di konsol AdMob).
/// Build rilis memakai ID asli; build debug & profile memakai ID UJI resmi
/// Google supaya iklan sungguhan tidak terketuk saat pengembangan.
/// Bisa ditimpa lewat `--dart-define=ADMOB_BANNER_ID=…` / `ADMOB_REWARDED_ID=…`.
///
/// ID aplikasi AdMob ada di android/app/src/main/AndroidManifest.xml.
abstract final class AdIds {
  static const String _testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  /// Unit "HitungIn Banner".
  static const String _banner = 'ca-app-pub-2760179272510023/8615664560';

  /// Unit "HitungIn Rewarded CSV" (hadiah 1 "Ekspor CSV").
  static const String _rewarded = 'ca-app-pub-2760179272510023/9058663487';

  static const String banner =
      String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: kReleaseMode ? _banner : _testBanner);
  static const String rewarded =
      String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: kReleaseMode ? _rewarded : _testRewarded);

  static bool get usingTestIds => banner == _testBanner || rewarded == _testRewarded;
}
