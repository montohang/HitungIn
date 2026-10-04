import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/security/secure_store.dart';
import 'package:hitungin/features/bills/data/bill_due.dart';
import 'package:hitungin/features/categories/data/categories_dao.dart';
import 'package:hitungin/features/security/auto_lock_setting.dart';
import 'package:hitungin/features/security/pin_service.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

import '../helpers/fakes.dart';

Bill _bill(DateTime due, {int remind = 3}) => Bill(
      id: 1,
      name: 'Listrik',
      amount: 450000,
      nextDue: due,
      repeat: BillRepeat.bulanan,
      anchorDay: due.day,
      remindDaysBefore: remind,
      active: true,
      createdAt: DateTime(2026),
    );

void main() {
  late AppDatabase db;
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('jatuh tempo tagihan', () {
    final now = DateTime(2026, 10, 4, 21, 30);

    test('status & label', () {
      String label(DateTime d) => billDueLabel(billDue(_bill(d), now));
      expect(label(DateTime(2026, 10, 2)), 'Terlambat 2 hari');
      expect(label(DateTime(2026, 10, 4)), 'Hari ini');
      expect(label(DateTime(2026, 10, 5)), 'Besok');
      expect(label(DateTime(2026, 10, 7)), '3 hari lagi');
      expect(billDue(_bill(DateTime(2026, 10, 7)), now).state, BillDueState.segera);
      expect(billDue(_bill(DateTime(2026, 10, 8)), now).state, BillDueState.nanti);
    });

    test('perlu perhatian mengikuti remindDaysBefore', () {
      expect(billNeedsAttention(_bill(DateTime(2026, 10, 8), remind: 3), now), isFalse);
      expect(billNeedsAttention(_bill(DateTime(2026, 10, 8), remind: 7), now), isTrue);
      expect(billNeedsAttention(_bill(DateTime(2026, 9, 30), remind: 0), now), isTrue);
    });

    test('lintas tahun', () {
      expect(billDue(_bill(DateTime(2027, 1, 1)), DateTime(2026, 12, 31, 23)).days, 1);
    });
  });

  group('kunci otomatis', () {
    test('nilai tersimpan dibaca, nilai asing → 30 detik', () async {
      expect(await loadAutoLockDelay(db.settingsDao), AutoLockDelay.detik30);
      await db.settingsDao.write(SettingKeys.autoLock, 'menit5');
      expect(await loadAutoLockDelay(db.settingsDao), AutoLockDelay.menit5);
      expect(AutoLockDelay.parse('ngawur'), AutoLockDelay.detik30);
      expect(AutoLockDelay.segera.duration, Duration.zero);
    });
  });

  group('ganti PIN', () {
    late PinService pin;
    setUp(() async {
      pin = PinService(MemorySecureStore(), clock: FakeClock().call, iterations: 10, useIsolate: false);
      await pin.setPin('258013');
    });

    test('PIN lama benar → PIN baru berlaku', () async {
      expect(await pin.changePin('258013', '970412'), isA<PinOk>());
      expect(await pin.verify('258013'), isA<PinWrong>());
      expect(await pin.verify('970412'), isA<PinOk>());
    });

    test('PIN lama salah → tidak berubah dan dihitung sebagai percobaan', () async {
      expect(await pin.changePin('000000', '970412'), isA<PinWrong>().having((r) => r.attemptsLeft, 'sisa', 4));
      expect(await pin.verify('258013'), isA<PinOk>());
    });

    test('format PIN baru salah ditolak', () {
      expect(() => pin.changePin('258013', '12'), throwsArgumentError);
    });
  });

  test('kata kunci kategori dirapikan', () {
    expect(normalizeCategoryKeywords(' Kopi, nasi ,kopi,,\nGoFood '), 'kopi,nasi,gofood');
    expect(normalizeCategoryKeywords('  '), '');
  });

  group('kelola kategori & dompet', () {
    test('watchAll memuat yang diarsipkan di akhir; reorder; usage', () async {
      final dao = db.categoriesDao;
      final cats = await dao.active(kind: TxKind.pemasukan);
      await dao.setArchived(cats.first.id, true);
      final all = await dao.watchAll(TxKind.pemasukan).first;
      expect(all.length, cats.length);
      expect(all.last.id, cats.first.id);
      expect(await dao.active(kind: TxKind.pemasukan), hasLength(cats.length - 1));

      final ids = [for (final c in await dao.active(kind: TxKind.pemasukan)) c.id].reversed.toList();
      await dao.reorder(ids);
      expect([for (final c in await dao.active(kind: TxKind.pemasukan)) c.id], ids);

      final w = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai);
      await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 10, walletId: w, categoryId: ids.first, occurredAt: DateTime(2026));
      expect(await dao.usage(ids.first), 1);
      expect(await dao.usage(ids.last), 0);
    });

    test('dompet: arsip disembunyikan dari total, reorder', () async {
      final a = await db.walletsDao.add(name: 'A', type: WalletType.tunai, initialBalance: 100);
      final b = await db.walletsDao.add(name: 'B', type: WalletType.bank, initialBalance: 50);
      await db.walletsDao.setArchived(a, true);
      expect(await db.walletsDao.watchTotalBalance().first, 50);
      expect(await db.walletsDao.watchBalances(includeArchived: true).first, hasLength(2));
      await db.walletsDao.setArchived(a, false);
      await db.walletsDao.reorder([b, a]);
      expect([for (final w in await db.walletsDao.active()) w.name], ['B', 'A']);
    });
  });
}
