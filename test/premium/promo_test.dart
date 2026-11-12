import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/premium/data/promo.dart';
import 'package:hitungin/features/premium/data/billing.dart';
import 'package:hitungin/features/premium/pro_controller.dart';

import '../helpers/fakes.dart';

void main() {
  final Promo promo = Promo(DateTime(2027, 2, 28));

  test('tanpa tanggal promo: tidak ada promo', () {
    expect(Promo.fromDefine('').phase(DateTime(2027)), PromoPhase.none);
    expect(Promo.fromDefine('bukan-tanggal').lastDay, isNull);
    expect(Promo.fromDefine('2027-02-28').lastDay, DateTime(2027, 2, 28));
  });

  test('fase: gratis, tinggal 7 hari, harga perkenalan 30 hari, lalu normal', () {
    expect(promo.phase(DateTime(2027, 2, 20, 23, 59)), PromoPhase.active);
    expect(promo.phase(DateTime(2027, 2, 22)), PromoPhase.endingSoon);
    expect(promo.daysLeft(DateTime(2027, 2, 22, 9)), 7);
    expect(promo.phase(DateTime(2027, 2, 28, 23, 59)), PromoPhase.endingSoon, reason: 'hari terakhir masih gratis');
    expect(promo.daysLeft(DateTime(2027, 2, 28, 9)), 1);
    expect(promo.phase(DateTime(2027, 3, 1)), PromoPhase.intro);
    expect(promo.introLastDay, DateTime(2027, 3, 30));
    expect(promo.phase(DateTime(2027, 3, 30, 23)), PromoPhase.intro);
    expect(promo.phase(DateTime(2027, 3, 31)), PromoPhase.none);
    expect(promo.unlocksPro(DateTime(2027, 2, 28, 12)), isTrue);
    expect(promo.unlocksPro(DateTime(2027, 3, 1)), isFalse);
    expect(promo.justEnded(DateTime(2027, 3, 7, 23)), isTrue);
    expect(promo.justEnded(DateTime(2027, 3, 8)), isFalse);
    expect(promo.justEnded(DateTime(2027, 2, 28)), isFalse);
    expect(promoDate(DateTime(2027, 2, 28)), '28 Feb 2027');
  });

  test('fitur Pro terbuka selama promo, iklan tetap mengikuti pembelian', () {
    ProviderContainer make({required DateTime now, required bool owns}) => ProviderContainer(overrides: [
          initialProProvider.overrideWithValue(owns),
          billingGatewayProvider.overrideWithValue(FakeBilling()),
          promoProvider.overrideWithValue(promo),
          clockProvider.overrideWithValue(() => now),
        ]);
    final during = make(now: DateTime(2027, 1, 10), owns: false);
    expect((during.read(isProProvider), during.read(ownsProProvider)), (true, false));
    final after = make(now: DateTime(2027, 3, 2), owns: false);
    expect((after.read(isProProvider), after.read(promoPhaseProvider)), (false, PromoPhase.intro));
    final bought = make(now: DateTime(2027, 3, 2), owns: true);
    expect((bought.read(isProProvider), bought.read(ownsProProvider)), (true, true));
    for (final c in [during, after, bought]) {
      c.dispose();
    }
  });
}
