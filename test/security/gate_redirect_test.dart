import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/security/app_gate.dart';

void main() {
  String? go(GateState s, String loc) => gateRedirect(s, Uri.parse(loc));

  const fresh = GateState();
  const pinOnly = GateState(hasPin: true, unlocked: true);
  const pinLocked = GateState(hasPin: true);
  const ready = GateState(onboardingDone: true, hasPin: true, unlocked: true);
  const readyLocked = GateState(onboardingDone: true, hasPin: true);

  test('splash selalu boleh', () {
    for (final s in [fresh, pinLocked, ready, readyLocked]) {
      expect(go(s, Routes.splash), isNull);
    }
  });

  test('pengguna baru diarahkan ke onboarding', () {
    expect(go(fresh, Routes.home), Routes.welcome);
    expect(go(fresh, Routes.lock), Routes.welcome);
    expect(go(fresh, Routes.welcome), isNull);
    expect(go(fresh, Routes.setupPin), isNull);
  });

  test('PIN sudah dibuat tapi onboarding belum selesai → lanjut ke dompet', () {
    expect(go(pinOnly, Routes.home), Routes.setupWallet);
    expect(go(pinOnly, Routes.welcome), Routes.setupWallet);
    expect(go(pinOnly, Routes.setupWallet), isNull);
  });

  test('aplikasi ditutup di tengah onboarding → kunci dulu', () {
    expect(go(pinLocked, Routes.home), '/lock?from=%2Fhome');
    expect(go(pinLocked.copyWith(unlocked: true), Routes.home), Routes.setupWallet);
  });

  test('terkunci → layar kunci, simpan tujuan', () {
    expect(go(readyLocked, Routes.home), '/lock?from=%2Fhome');
    expect(go(readyLocked, Routes.lock), isNull);
  });

  test('setelah terbuka kembali ke tujuan semula', () {
    expect(go(ready, '/lock?from=%2Fhome'), Routes.home);
    expect(go(ready, '/lock?from=%2Fdev%2Fgallery'), Routes.gallery);
    expect(go(ready, Routes.lock), Routes.home);
  });

  test('tujuan "from" yang aneh diabaikan', () {
    expect(go(ready, '/lock?from=https%3A%2F%2Fevil.example'), Routes.home);
    expect(go(ready, '/lock?from=%2Flock'), Routes.home);
    expect(go(ready, '/lock?from=%2Fsetup%2Fpin'), Routes.home);
  });

  test('onboarding tidak bisa dibuka lagi setelah selesai', () {
    expect(go(ready, Routes.welcome), Routes.home);
    expect(go(ready, Routes.setupPin), Routes.home);
    expect(go(ready, Routes.home), isNull);
  });

  test('tanpa PIN tidak pernah terkunci', () {
    const noPin = GateState(onboardingDone: true);
    expect(noPin.locked, isFalse);
    expect(go(noPin, Routes.home), isNull);
  });
}
