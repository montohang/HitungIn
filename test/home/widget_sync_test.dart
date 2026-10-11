import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/platform/launch_routes.dart';
import 'package:hitungin/features/favorites/data/favorites.dart';
import 'package:hitungin/features/home/data/allowance.dart';
import 'package:hitungin/features/home/widget_sync.dart';

void main() {
  final now = DateTime(2026, 10, 19, 9);
  final a = computeAllowance(
      now: now, payday: 1, balance: 1300000 - 28000, spentToday: 28000, bills: const [], recurring: const []);
  const fav = Favorite(kind: TxKind.pengeluaran, note: 'kopi', categoryId: null, sub: '', walletId: 1, amount: 25000, lastTxId: 12);

  test('ringkasan widget: jatah, sisa, favorit dengan route ke Catat terisi', () {
    final s = buildWidgetSnapshot(now: now, allowance: a, favorites: const [fav], categories: const [], hidden: false);
    expect(s['date'], '2026-10-19');
    expect(s['jatah'], 'Rp100.000');
    expect(s['line'], 'Sisa Rp72.000 · gajian 13 hari lagi');
    expect(s['progress'], 28);
    expect(s['favs'], [
      {'label': 'Kopi', 'amount': '25rb', 'route': '/catat?copy=12'},
    ]);
  });

  test('mode sembunyikan saldo: tidak ada nominal sama sekali', () {
    final s = buildWidgetSnapshot(now: now, allowance: a, favorites: const [fav], categories: const [], hidden: true);
    expect(s['jatah'], 'Rp ••••');
    expect(s['progress'], 0);
    expect((s['favs']! as List).single, containsPair('amount', '••'));
    expect(s.toString(), isNot(contains('100.000')));
  });

  test('route dari luar aplikasi dibatasi', () {
    expect(isAllowedLaunchRoute('/catat'), isTrue);
    expect(isAllowedLaunchRoute('/catat?kind=pemasukan'), isTrue);
    expect(isAllowedLaunchRoute('/catat?copy=12'), isTrue);
    expect(isAllowedLaunchRoute('/riwayat'), isTrue);
    expect(isAllowedLaunchRoute('/pengaturan/keamanan'), isFalse);
    expect(isAllowedLaunchRoute('https://contoh.com/catat'), isFalse);
    expect(isAllowedLaunchRoute('//evil/catat'), isFalse);
  });
}
