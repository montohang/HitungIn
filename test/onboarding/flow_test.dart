import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/app.dart';
import 'package:hitungin/features/security/app_gate.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

import '../helpers/fakes.dart';

Future<void> _pump(WidgetTester tester, TestEnv env) async {
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

    expect(find.text('Catat uang,\ntanpa ribet.'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('100% offline.\nDatamu milikmu.'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Rina');
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(await env.db.settingsDao.read(SettingKeys.userName), 'Rina');

    // PIN terlalu mudah ditolak.
    expect(find.text('Buat PIN'), findsOneWidget);
    await _enterPin(tester, '123456');
    expect(find.textContaining('terlalu mudah'), findsOneWidget);
    // Konfirmasi berbeda → ulang dari awal.
    await _enterPin(tester, '258013');
    expect(find.text('Ulangi PIN'), findsOneWidget);
    await _enterPin(tester, '258014');
    expect(find.text('Buat PIN'), findsOneWidget);
    expect(find.textContaining('tidak sama'), findsOneWidget);
    await _enterPin(tester, '258013');
    await _enterPin(tester, '258013');
    expect(await env.pin.hasPin(), isTrue);

    expect(find.textContaining('sidik jari?'), findsOneWidget);
    await tester.tap(find.text('Aktifkan sidik jari'));
    await tester.pumpAndSettle();
    expect(env.biometric.prompts, 1);
    expect(await env.pin.biometricEnabled(), isTrue);

    expect(find.text('Uangmu ada di mana saja?'), findsOneWidget);
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

  testWidgets('tanpa sensor biometrik, langkah sidik jari dilewati', (tester) async {
    final env = TestEnv();
    await _pump(tester, env);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    await _enterPin(tester, '258013');
    await _enterPin(tester, '258013');
    expect(find.text('Uangmu ada di mana saja?'), findsOneWidget);
    await _close(tester, env);
  });

  group('layar kunci', () {
    const locked = GateState(onboardingDone: true, hasPin: true);

    testWidgets('PIN salah lalu benar → beranda', (tester) async {
      final env = TestEnv(gate: locked);
      await env.pin.setPin('258013');
      await _pump(tester, env);

      expect(find.text('Masukkan PIN'), findsOneWidget);
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
      expect(find.text('Masukkan PIN'), findsOneWidget);

      env.clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
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
      expect(find.text('Masukkan PIN'), findsOneWidget);
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
    expect(find.text('Masukkan PIN'), findsOneWidget);

    // Tombol "Kunci sekarang" juga bekerja.
    await _enterPin(tester, '258013');
    await tester.tap(find.bySemanticsLabel('Kunci sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan PIN'), findsOneWidget);
    await _close(tester, env);
  });
}
