import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/security/pin_hasher.dart';
import 'package:hitungin/features/security/pin_service.dart';

import '../helpers/fakes.dart';

void main() {
  group('PinHasher', () {
    test('hash terverifikasi, PIN lain ditolak, garam berbeda tiap kali', () async {
      final a = await PinHasher.hash('258013', iterations: 1000);
      final b = await PinHasher.hash('258013', iterations: 1000);
      expect(a, startsWith(r'pbkdf2-sha256$1000$'));
      expect(a, isNot(b));
      expect(a, isNot(contains('258013')));
      expect(await PinHasher.verify('258013', a), isTrue);
      expect(await PinHasher.verify('258014', a), isFalse);
    });

    test('format rusak ditolak tanpa error', () async {
      expect(await PinHasher.verify('258013', 'bukan-hash'), isFalse);
      expect(await PinHasher.verify('258013', r'md5$1$AA==$AA=='), isFalse);
    });
  });

  group('PinService', () {
    late MemorySecureStore store;
    late FakeClock clock;
    late PinService pin;

    setUp(() {
      store = MemorySecureStore();
      clock = FakeClock();
      pin = PinService(store, clock: clock.call, iterations: 10, useIsolate: false);
    });

    test('validasi format & PIN terlalu mudah', () {
      expect(PinService.isValidFormat('123456'), isTrue);
      expect(PinService.isValidFormat('12345'), isFalse);
      expect(PinService.isValidFormat('12345a'), isFalse);
      for (final p in ['111111', '123456', '654321', '345678', '000000']) {
        expect(PinService.isTooSimple(p), isTrue, reason: p);
      }
      expect(PinService.isTooSimple('258013'), isFalse);
      expect(() => pin.setPin('12'), throwsArgumentError);
    });

    test('PIN benar membuka, PIN salah mengurangi sisa percobaan', () async {
      expect(await pin.hasPin(), isFalse);
      await pin.setPin('258013');
      expect(await pin.hasPin(), isTrue);
      expect(await pin.verify('000000'), isA<PinWrong>().having((r) => r.attemptsLeft, 'sisa', 4));
      expect(await pin.verify('000000'), isA<PinWrong>().having((r) => r.attemptsLeft, 'sisa', 3));
      expect(await pin.verify('258013'), isA<PinOk>());
      // Berhasil → hitungan kembali penuh.
      expect(await pin.verify('000000'), isA<PinWrong>().having((r) => r.attemptsLeft, 'sisa', 4));
    });

    test('5 kali salah → tunggu 30 dtk, lalu berlipat; PIN benar pun ditolak saat dikunci', () async {
      await pin.setPin('258013');
      for (int i = 0; i < 4; i++) {
        await pin.verify('000000');
      }
      final r = await pin.verify('000000');
      expect(r, isA<PinLockedOut>().having((r) => r.until, 'until', clock.now.add(const Duration(seconds: 30))));
      expect(await pin.verify('258013'), isA<PinLockedOut>());

      clock.advance(const Duration(seconds: 31));
      expect(await pin.lockedUntil(), isNull);
      for (int i = 0; i < 4; i++) {
        expect(await pin.verify('000000'), isA<PinWrong>());
      }
      final r2 = await pin.verify('000000');
      expect(r2, isA<PinLockedOut>().having((r) => r.until, 'until', clock.now.add(const Duration(minutes: 1))));

      clock.advance(const Duration(minutes: 2));
      expect(await pin.verify('258013'), isA<PinOk>());
    });

    test('penguncian tetap ada setelah aplikasi dibuka ulang', () async {
      await pin.setPin('258013');
      for (int i = 0; i < 5; i++) {
        await pin.verify('000000');
      }
      final reopened = PinService(store, clock: clock.call, iterations: 10, useIsolate: false);
      expect(await reopened.lockedUntil(), isNotNull);
    });

    test('lama tunggu maksimal 15 menit', () async {
      await pin.setPin('258013');
      PinResult? last;
      for (int round = 0; round < 8; round++) {
        for (int i = 0; i < 5; i++) {
          last = await pin.verify('000000');
        }
        clock.advance(const Duration(hours: 1));
      }
      final until = (last! as PinLockedOut).until;
      expect(until.difference(clock.now.subtract(const Duration(hours: 1))), const Duration(minutes: 15));
    });

    test('pilihan biometrik tersimpan', () async {
      expect(await pin.biometricEnabled(), isFalse);
      await pin.setBiometricEnabled(true);
      expect(await pin.biometricEnabled(), isTrue);
    });
  });
}
