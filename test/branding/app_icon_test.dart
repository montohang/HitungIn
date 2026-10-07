import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/branding/app_icon_service.dart';
import 'package:hitungin/core/branding/app_icon_variants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('varian ikon', () {
    test('kunci & nama mipmap', () {
      expect(AppIconVariant.standar.mipmap, 'ic_launcher');
      expect(AppIconVariant.emas.mipmap, 'ic_launcher_emas');
      expect(AppIconVariant.parse('gelap'), AppIconVariant.gelap);
      expect(AppIconVariant.parse('ngawur'), AppIconVariant.standar);
      expect(AppIconVariant.standar.pro, isFalse);
      expect(AppIconVariant.values.where((v) => v.pro), hasLength(3));
    });
  });

  group('AndroidAppIconService', () {
    const channel = MethodChannel('com.capt.hitungin/app_icon');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'get' ? 'emas' : null;
      });
    });
    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    test('membaca & mengganti ikon lewat kanal', () async {
      const service = AndroidAppIconService();
      expect(await service.current(), AppIconVariant.emas);
      await service.set(AppIconVariant.terang);
      expect(calls.last.method, 'set');
      expect(calls.last.arguments, {'key': 'terang'});
    });

    test('tanpa sisi native (mis. tes/desktop) → Standar', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      expect(await const AndroidAppIconService().current(), AppIconVariant.standar);
    });
  });

  group('konsistensi Dart ↔ Android', () {
    final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final String kotlin = File('android/app/src/main/kotlin/com/capt/hitungin/MainActivity.kt').readAsStringSync();
    const String res = 'android/app/src/main/res';

    String component(AppIconVariant v) =>
        v == AppIconVariant.standar ? 'LauncherActivity' : 'Icon${v.key[0].toUpperCase()}${v.key.substring(1)}';

    test('setiap varian punya komponen peluncur & kunci di MainActivity', () {
      for (final v in AppIconVariant.values) {
        expect(manifest, contains('android:name=".${component(v)}"'), reason: v.key);
        expect(kotlin, contains('"${v.key}" to "com.capt.hitungin.${component(v)}"'), reason: v.key);
      }
      expect(RegExp('android.intent.category.LAUNCHER').allMatches(manifest).length, AppIconVariant.values.length,
          reason: 'MainActivity sendiri tidak boleh punya LAUNCHER (ikon dobel)');
      expect(RegExp(r'android:enabled="true"').allMatches(manifest).length, 1, reason: 'hanya Standar aktif bawaan');
    });

    test('berkas ikon lengkap di semua kepadatan', () {
      for (final v in AppIconVariant.values) {
        expect(File('$res/mipmap-anydpi-v26/${v.mipmap}.xml').existsSync(), isTrue, reason: v.key);
        for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
          expect(File('$res/mipmap-$d/${v.mipmap}.png').existsSync(), isTrue, reason: '${v.key} $d');
          expect(File('$res/mipmap-$d/${v.mipmap}_fg.png').existsSync(), isTrue, reason: '${v.key} $d fg');
        }
      }
      expect(File('$res/mipmap-xxxhdpi/ic_launcher_mono.png').existsSync(), isTrue);
      expect(File('branding/play_store_icon_512.png').existsSync(), isTrue);
    });
  });

  test('splash lama tidak menggambar ikon adaptif sebagai bitmap (crash Android 8+)', () {
    for (final String path in [
      'android/app/src/main/res/drawable/launch_background.xml',
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    ]) {
      final String xml = File(path).readAsStringSync();
      expect(xml, isNot(contains('@mipmap/')), reason: path);
    }
    // Mode gelap Android 12+ memakai splash sistem, bukan launch_background.
    final String night31 = File('android/app/src/main/res/values-night-v31/styles.xml').readAsStringSync();
    expect(night31, contains('windowSplashScreenAnimatedIcon'));
    expect(night31, isNot(contains('@drawable/launch_background')));
  });
}

