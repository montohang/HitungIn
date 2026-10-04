/// ID unit iklan AdMob. Default = ID UJI resmi Google (aman dipakai saat
/// pengembangan). Untuk rilis, isi lewat:
///
/// ```
/// flutter build appbundle \
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/zzz
/// ```
///
/// ID aplikasi AdMob ada di android/app/src/main/AndroidManifest.xml.
abstract final class AdIds {
  static const String _testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const String banner = String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: _testBanner);
  static const String rewarded = String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: _testRewarded);

  static bool get usingTestIds => banner == _testBanner || rewarded == _testRewarded;
}
