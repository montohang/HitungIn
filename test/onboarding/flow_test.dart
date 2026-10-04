import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/app.dart';
import 'package:hitungin/features/security/app_gate.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/onboarding/pin_setup_screen.dart';

import '../helpers/fakes.dart';

Future<void> _pump(WidgetTester tester, TestEnv env) async {
  // Ukuran HP (keypad PIN menempel di bawah layar).
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const HitungInApp()));
  await tester.pumpAndSettle();
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.bySemanticsLabel(d).last);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Drift memakai timer untuk stream; tutup DB sebelum tes selesai.
Future<void> _close(WidgetTester tester, TestEnv env) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(env.db.close);
}

void main() {
  testWidgets('onboarding lengkap: sapaan → PIN → sidik jari → dompet → beranda', (tester) async {
    final env = TestEnv(biometric: true);
    await _pump(tester, env);

    // 3 sapaan (teks dari Claude Design) + halaman nama.
    expect(find.text('Data keuanganmu tetap di HP-mu'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.textContaining('Pulihkan dari backup', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Catat cukup dengan satu kalimat'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Bukan cuma mencatat, tapi merencanakan'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Mau dipanggil apa?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Rina');
    await tester.tap(find.text('Mulai sekarang'));
    await tester.pumpAndSettle();
    expect(await env.db.settingsDao.read(SettingKeys.userName), 'Rina');

    // PIN terlalu mudah ditolak.
    expect(find.text('Buat PIN 6 digit'), findsOneWidget);
    expect(find.text('Langkah 1 dari 2'), findsOneWidget);
    await _enterPin(tester, '123456');
    expect(find.textContaining('terlalu mudah'), findsOneWidget);
    // Konfirmasi berbeda → ulang dari awal.
    await _enterPin(tester, '258013');
    expect(find.text('Ulangi PIN-mu'), findsOneWidget);
    await _enterPin(tester, '258014');
    expect(find.text('Buat PIN 6 digit'), findsOneWidget);
    expect(find.textContaining('tidak sama'), findsOneWidget);
    await _enterPin(tester, '258013');
    await _enterPin(tester, '258013');
    expect(await env.pin.hasPin(), isTrue);

    // Sidik jari ditawarkan lewat lembar bawah.
    expect(find.text('PIN tersimpan'), findsOneWidget);
    expect(find.textContaining('sidik jari?'), findsOneWidget);
    await tester.tap(find.text('Aktifkan'));
    await tester.pumpAndSettle();
    expect(env.biometric.prompts, 1);
    expect(await env.pin.biometricEnabled(), isTrue);

    expect(find.text('Uangmu ada di mana saja?'), findsOneWidget);
    expect(find.text('Langkah 2 dari 2'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Saldo sekarang'), '150000');
    await tester.tap(find.text('GoPay'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Saldo sekarang').last, '75000');
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Total saldo'), findsOneWidget);
    expect(find.text('Rp225.000'), findsOneWidget);
    expect(find.textContaining('Rina', findRichText: true), findsOneWidget);
    await tester.scrollUntilVisible(find.text('GoPay'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('GoPay'), findsOneWidget);
    expect(await env.db.settingsDao.read(SettingKeys.onboardingDone), 'true');

    await _close(tester, env);
  });

  testWidgets('Lewati → PIN; tanpa sensor biometrik, lembar sidik jari tidak muncul', (tester) async {
    final env = TestEnv();
    await _pump(tester, env);
    // "Lewati" langsung ke Buat PIN, nama tidak disimpan.
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Buat PIN 6 digit'), findsOneWidget);
    expect(await env.db.settingsDao.read(SettingKeys.userName), isNull);
    await _enterPin(tester, '258013');
    await _enterPin(tester, '258013');
    expect(find.text('PIN tersimpan'), findsNothing);
    expect(find.text('Uangmu ada di mana saja?'), findsOneWidget);
    await _close(tester, env);
  });

  test('setelah PIN: data hasil pulihkan (sudah ada dompet) → langsung selesai', () {
    expect(routeAfterPinSetup(hasWallets: true), isNull);
    expect(routeAfterPinSetup(hasWallets: false), Routes.setupWallet);
  });

  testWidgets('pulihkan dari sapaan → buat PIN → langsung Beranda (tanpa Dompet Awal)', (tester) async {
    final env = TestEnv();
    // Keadaan setelah runRestoreFlow: data cadangan sudah masuk, PIN belum ada.
    await tester.runAsync(() async {
      await env.db.walletsDao.add(name: 'BCA lama', type: WalletType.bank, initialBalance: 750000);
      await env.db.settingsDao.write(SettingKeys.userName, 'Rina');
    });
    await _pump(tester, env);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await _enterPin(tester, '258013');
    await _enterPin(tester, '258013');
    expect(find.text('Uangmu ada di mana saja?'), findsNothing);
    expect(find.textContaining('Total saldo'), findsOneWidget);
    expect(find.text('Rp750.000'), findsWidgets);
    expect(await env.db.settingsDao.read(SettingKeys.onboardingDone), 'true');
    await _close(tester, env);
  });

  group('layar kunci', () {
    const locked = GateState(onboardingDone: true, hasPin: true);

    testWidgets('PIN salah lalu benar → beranda', (tester) async {
      final env = TestEnv(gate: locked);
      await env.pin.setPin('258013');
      await _pump(tester, env);

      expect(find.text('Hai lagi'), findsOneWidget);
      expect(find.bySemanticsLabel('Buka dengan sidik jari'), findsNothing);
      await _enterPin(tester, '000000');
      expect(find.text('PIN salah. Sisa 4 percobaan.'), findsOneWidget);
      await _enterPin(tester, '258013');
      expect(find.textContaining('Total saldo'), findsOneWidget);
      await _close(tester, env);
    });

    testWidgets('5 kali salah → keypad dikunci dengan hitung mundur', (tester) async {
      final env = TestEnv(gate: locked);
      await env.pin.setPin('258013');
      await _pump(tester, env);
      for (int i = 0; i < 5; i++) {
        await _enterPin(tester, '000000');
      }
      expect(find.textContaining('Coba lagi dalam 0:30'), findsOneWidget);
      await _enterPin(tester, '258013'); // diabaikan saat terkunci
      expect(find.text('Hai lagi'), findsOneWidget);

      env.clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // pesan memudar keluar
      expect(find.textContaining('Coba lagi'), findsNothing);
      await _enterPin(tester, '258013');
      expect(find.textContaining('Total saldo'), findsOneWidget);
      await _close(tester, env);
    });

    testWidgets('sidik jari aktif → langsung ditawarkan saat dibuka', (tester) async {
      final env = TestEnv(gate: locked, biometric: true);
      await env.pin.setPin('258013');
      await env.pin.setBiometricEnabled(true);
      await _pump(tester, env);
      expect(env.biometric.prompts, 1);
      expect(find.textContaining('Total saldo'), findsOneWidget);
      await _close(tester, env);
    });

    testWidgets('sidik jari batal → tetap bisa pakai PIN', (tester) async {
      final env = TestEnv(gate: locked, biometric: true);
      env.biometric.result = false;
      await env.pin.setPin('258013');
      await env.pin.setBiometricEnabled(true);
      await _pump(tester, env);
      expect(find.text('Hai lagi'), findsOneWidget);
      expect(find.bySemanticsLabel('Buka dengan sidik jari'), findsOneWidget);
      await _enterPin(tester, '258013');
      expect(find.textContaining('Total saldo'), findsOneWidget);
      await _close(tester, env);
    });
  });

  testWidgets('kunci otomatis setelah 30 detik di latar belakang', (tester) async {
    final env = TestEnv(gate: const GateState(onboardingDone: true, hasPin: true, unlocked: true));
    await env.pin.setPin('258013');
    await _pump(tester, env);
    expect(find.textContaining('Total saldo'), findsOneWidget);

    // Sebentar saja → tidak terkunci.
    void background() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }

    void foreground() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    background();
    env.clock.advance(const Duration(seconds: 10));
    foreground();
    await tester.pumpAndSettle();
    expect(find.textContaining('Total saldo'), findsOneWidget);

    background();
    env.clock.advance(const Duration(seconds: 31));
    foreground();
    await tester.pumpAndSettle();
    expect(find.text('Hai lagi'), findsOneWidget);

    // Tombol "Kunci sekarang" juga bekerja.
    await _enterPin(tester, '258013');
    await tester.tap(find.bySemanticsLabel('Kunci sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Hai lagi'), findsOneWidget);
    await _close(tester, env);
  });
}
