import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/home/allowance_provider.dart';
import 'package:hitungin/features/home/data/allowance.dart';

import '../helpers/fakes.dart';

/// Tunggu sampai semua stream termuat (dan [until] terpenuhi) lalu baca jatah.
Future<Allowance> _read(ProviderContainer c, {bool Function(Allowance a)? until}) async {
  final sub = c.listen(allowanceProvider, (_, __) {});
  bool ready() {
    final Allowance? a = sub.read();
    return a != null && (until == null || until(a));
  }

  for (var i = 0; i < 100 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  final a = sub.read()!;
  sub.close();
  return a;
}

void main() {
  test('parse pengaturan', () {
    expect((parsePayday(null), parsePayday('25'), parsePayday('40'), parsePayday('x')), (1, 25, 1, 1));
    expect(parseIdSet('3, 7,,x'), {3, 7});
    expect(formatIdSet({7, 3}), '3,7');
  });

  test('dompet dikecualikan & pindah saldo tidak memengaruhi; tanggal gajian tersimpan', () async {
    final env = TestEnv()..clock.now = DateTime(2026, 10, 19, 9);
    final c = ProviderContainer(overrides: env.overrides);
    addTearDown(() async {
      c.dispose();
      await env.db.close();
    });
    final db = env.db;
    final cat = (await db.categoriesDao.active()).firstWhere((x) => x.kind == TxKind.pengeluaran).id;
    final tunai = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 1328000);
    final tabungan = await db.walletsDao.add(name: 'Tabungan', type: WalletType.bank, initialBalance: 5000000);
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 28000, walletId: tunai, categoryId: cat, occurredAt: DateTime(2026, 10, 19, 8));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 40000, walletId: tabungan, categoryId: cat, occurredAt: DateTime(2026, 10, 19, 8));
    await db.transactionsDao.add(kind: TxKind.transfer, amount: 100000, walletId: tabungan, toWalletId: tunai, occurredAt: DateTime(2026, 10, 19, 8));

    await setWalletInAllowance(db.settingsDao, const {}, tabungan, false);
    var a = await _read(c);
    // Tunai: 1.328.000 − 28.000 + 100.000 = 1.400.000; jatah = (1.400.000 + 28.000) ÷ 13.
    expect(a.balance, 1400000);
    expect(a.spentToday, 28000, reason: 'pengeluaran dari dompet tabungan tidak dihitung');
    expect(a.jatah, 109800);

    await setPayday(db.settingsDao, 25);
    a = await _read(c, until: (a) => a.nextPayday.day == 25);
    expect(a.nextPayday, DateTime(2026, 10, 25));
    expect(a.daysToPayday, 6);
  });
}
