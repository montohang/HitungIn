import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/app.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/security/app_gate.dart';
import 'package:hitungin/router.dart';

import 'fakes.dart';

export 'fakes.dart';

/// Aplikasi utuh untuk tes UI: onboarding selesai, tanpa PIN. [seed] membuat
/// 3 dompet (Tunai 50rb, GoPay 100rb, BCA 1jt) dan memetakan kategori bawaan.
class AppHarness {
  AppHarness(this.tester, {bool pro = false, bool pin = false})
      : env = TestEnv(gate: GateState(onboardingDone: true, hasPin: pin, unlocked: pin), pro: pro);

  final WidgetTester tester;
  final TestEnv env;
  late int tunai, gopay, bca;
  late Map<String, int> cat;

  AppDatabase get db => env.db;

  /// Query Drift di luar frame harus berjalan dengan waktu nyata,
  /// kalau tidak tes menggantung di zona fake-async.
  Future<T> run<T>(Future<T> Function(AppDatabase db) f) async => (await tester.runAsync(() => f(db))) as T;

  Future<void> seed() => run((db) async {
        tunai = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 50000);
        gopay = await db.walletsDao.add(name: 'GoPay', type: WalletType.ewallet, initialBalance: 100000);
        bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
        cat = {for (final c in await db.categoriesDao.active()) '${c.name}/${c.kind.name}': c.id};
      });

  Future<int> addTx(TxKind kind, int amount, int wallet, DateTime at, {int? category, String note = ''}) => run(
        (db) => db.transactionsDao.add(kind: kind, amount: amount, walletId: wallet, categoryId: category, note: note, occurredAt: at),
      );

  int food() => cat['Makan & Minum/pengeluaran']!;
  int transport() => cat['Transportasi/pengeluaran']!;

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const HitungInApp()));
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String location) async {
    ProviderScope.containerOf(tester.element(find.byType(HitungInApp))).read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  /// Seperti membuka dari layar sebelumnya (bisa kembali/pop).
  Future<void> push(WidgetTester tester, String location) async {
    ProviderScope.containerOf(tester.element(find.byType(HitungInApp))).read(routerProvider).push(location);
    await tester.pumpAndSettle();
  }

  /// Kembali satu layar (seperti tombol kembali Android).
  Future<void> back(WidgetTester tester) async {
    ProviderScope.containerOf(tester.element(find.byType(HitungInApp))).read(routerProvider).pop();
    await tester.pumpAndSettle();
  }

  Future<String?> setting(String key) => run((db) => db.settingsDao.read(key));

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  }

  /// Ketuk teks lalu tunggu animasi selesai.
  Future<void> tap(String text) async {
    final Finder f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Gulir daftar utama sampai [finder] terlihat.
  Future<void> scrollTo(Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<Map<String, int>> balances() =>
      run((db) async => {for (final b in await db.walletsDao.watchBalances().first) b.wallet.name: b.balance});
}

