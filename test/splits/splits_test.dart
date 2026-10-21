import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/debts/data/debts_dao.dart';
import 'package:hitungin/features/splits/data/splits.dart';
import 'package:hitungin/features/splits/data/splits_dao.dart';
import 'package:hitungin/features/splits/splits_provider.dart';

void main() {
  group('pembagian (logika murni)', () {
    test('rata: sisa pembulatan ditanggung pembayar, jumlah tepat', () {
      expect(splitEven(450000, 4, payer: 0), [112500, 112500, 112500, 112500]);
      expect(splitEven(100000, 3, payer: 1), [33333, 33334, 33333]);
      expect(splitEven(100000, 3, payer: 1).reduce((a, b) => a + b), 100000);
    });

    test('alokasi sisa terbesar: bulat & jumlahnya tepat', () {
      final List<int> r = allocate(100, [1, 1, 1]);
      expect(r.reduce((a, b) => a + b), 100);
      expect(r, [34, 33, 33]);
      expect(allocate(1000, [0, 3, 1]), [0, 750, 250]);
      expect(allocate(500, [0, 0]), [0, 0]);
    });

    test('per menu: item dibagi di antara yang ikut, PB1 & service proporsional', () {
      final List<MenuLine> lines = [
        (name: 'Nasi goreng spesial', price: 48000, who: {0}),
        (name: 'Ayam bakar madu', price: 62000, who: {1}),
        (name: 'Kwetiau goreng', price: 45000, who: {2}),
        (name: 'Gurame asam manis', price: 120000, who: {1, 3}),
        (name: 'Es teh manis ×4', price: 48000, who: {0, 1, 2, 3}),
        (name: 'Kentang goreng', price: 35000, who: {0, 2}),
      ];
      final MenuBill bill = menuBill(lines, taxPermille: 100, servicePermille: 50);
      expect((bill.subtotal, bill.tax, bill.service, bill.total), (358000, 35800, 17900, 411700));
      final List<int> shares = splitMenu(lines, 4, bill);
      expect(shares, [89125, 154100, 85675, 82800]);
      expect(shares.reduce((a, b) => a + b), 411700);
    });

    test('per menu: ongkir & diskon ikut proporsional; tetap tepat', () {
      final List<MenuLine> lines = [
        (name: 'Pizza', price: 99000, who: {0, 1, 2}),
        (name: 'Pasta', price: 51000, who: {2}),
      ];
      final MenuBill bill = menuBill(lines, extraFee: 15000, discount: 20000);
      expect(bill.total, 145000);
      final List<int> shares = splitMenu(lines, 3, bill);
      expect(shares.reduce((a, b) => a + b), 145000);
      expect(shares[0], shares[1]);
      expect(shares[2] > shares[0], isTrue);
    });

    test('masalah isian: teman, nama dobel, total, item tanpa peserta, sisa/kelebihan', () {
      expect(splitProblem(total: 100, names: ['Aku'], shares: [100]), 'Tambahkan minimal satu teman.');
      expect(splitProblem(total: 100, names: ['Aku', 'budi', 'Budi'], shares: [50, 25, 25]), 'Nama "Budi" dobel.');
      expect(splitProblem(total: 0, names: ['Aku', 'Budi'], shares: [0, 0]), 'Isi total tagihannya.');
      expect(
        splitProblem(total: 100, names: ['Aku', 'Budi'], shares: [100, 0], lines: [(name: 'Es teh', price: 100, who: <int>{})]),
        '"Es teh" belum dipilih siapa yang ikut.',
      );
      expect(splitProblem(total: 100000, names: ['Aku', 'Budi'], shares: [50000, 40000]), 'Sisa Rp10.000 belum terbagi.');
      expect(splitProblem(total: 100000, names: ['Aku', 'Budi'], shares: [50000, 60000]), 'Kelebihan Rp10.000 dari total.');
      expect(splitProblem(total: 100000, names: ['Aku', 'Budi'], shares: [50000, 50000]), isNull);
    });

    test('teks WhatsApp: bagian teman, item, tanda lunas, pembayar & transfer', () {
      final String text = splitShareText(
        title: 'Makan Solaria',
        date: DateTime(2026, 10, 21, 19),
        total: 411700,
        modeNote: 'dibagi per menu (sudah termasuk pajak & service)',
        people: [
          (name: 'Aku', share: 89125, isMe: true, payer: true, paid: false, items: const ['Nasi goreng']),
          (name: 'Budi', share: 154100, isMe: false, payer: false, paid: true, items: const ['Ayam bakar', 'Gurame']),
          (name: 'Sinta', share: 85675, isMe: false, payer: false, paid: false, items: const []),
        ],
        transfer: 'BCA 1234567890 a.n. Rina',
      );
      expect(
        text,
        'Patungan Makan Solaria (Rabu, 21 Oktober)\n'
        'Total Rp411.700 · dibagi per menu (sudah termasuk pajak & service)\n'
        '• Budi Rp154.100 (Ayam bakar, Gurame) ✓\n'
        '• Sinta Rp85.675\n'
        'Dibayar dulu oleh aku.\n'
        'Transfer ke BCA 1234567890 a.n. Rina 🙏',
      );
    });
  });

  group('SplitsDao', () {
    late AppDatabase db;
    late int bca;
    late int makan;
    final DateTime at = DateTime(2026, 10, 21, 19);

    setUp(() async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      bca = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
      makan = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
    });
    tearDown(() => db.close());

    Future<int> balance() async => (await db.walletsDao.watchBalances().first).single.balance;
    Future<int> expense() async => (await db.transactionsDao.watchSummary(DateTime(2026, 10), DateTime(2026, 11)).first).expense;
    Future<Map<int, DebtWithPayments>> debts() async => {for (final d in await db.debtsDao.watchAll().first) d.debt.id: d};

    Future<int> saveEven({required int payer, int? id}) => db.splitsDao.save(
          id: id,
          title: 'Makan Solaria',
          mode: SplitMode.rata,
          total: 450000,
          walletId: bca,
          categoryId: makan,
          occurredAt: at,
          members: [
            (name: 'Aku', isMe: true, payer: payer == 0, share: 112500),
            (name: 'Budi', isMe: false, payer: payer == 1, share: 112500),
            (name: 'Sinta', isMe: false, payer: payer == 2, share: 112500),
            (name: 'Rina', isMe: false, payer: payer == 3, share: 112500),
          ],
        );

    test('aku yang bayar: Laporan hanya bagianku, piutang per teman, saldo berkurang total', () async {
      final int id = await saveEven(payer: 0);
      expect(await expense(), 112500);
      expect(await balance(), 550000);
      final List<DebtWithPayments> ds = await db.debtsDao.watchAll().first;
      expect({for (final d in ds) d.debt.name: (d.debt.direction, d.debt.amount, d.debt.splitId)}, {
        'Budi': (DebtDirection.piutang, 112500, id),
        'Sinta': (DebtDirection.piutang, 112500, id),
        'Rina': (DebtDirection.piutang, 112500, id),
      });
      final SplitFull s = (await db.splitsDao.byId(id))!;
      expect(splitProgress(s, await debts()), (settled: 0, count: 3, owedToMe: 337500, iOwe: 0));
      final Txn mine = (await db.transactionsDao.watchRecent().first).firstWhere((t) => t.tx.splitId == id).tx;
      expect((mine.kind, mine.amount, mine.categoryId, mine.note), (TxKind.pengeluaran, 112500, makan, 'Makan Solaria'));
    });

    test('teman yang bayar: pengeluaran bagianku + utangku ke dia, saldo tidak berubah', () async {
      final int id = await saveEven(payer: 1);
      expect(await expense(), 112500);
      expect(await balance(), 1000000);
      final DebtWithPayments d = (await db.debtsDao.watchAll().first).single;
      expect((d.debt.name, d.debt.direction, d.debt.amount), ('Budi', DebtDirection.utang, 112500));
      final SplitFull s = (await db.splitsDao.byId(id))!;
      expect((s.iPaid, s.payer.name, s.payer.debtId), (false, 'Budi', d.debt.id));
      expect(splitProgress(s, await debts()), (settled: 0, count: 1, owedToMe: 0, iOwe: 112500));
    });

    test('teman membayar lewat Utang-piutang → status ikut; ubah ditolak setelah ada pembayaran', () async {
      final int id = await saveEven(payer: 0);
      SplitFull s = (await db.splitsDao.byId(id))!;
      final SplitMember budi = s.members.firstWhere((m) => m.name == 'Budi');
      await db.debtsDao.pay(budi.debtId!, amount: 112500, paidAt: at, walletId: bca);
      expect(await balance(), 662500);
      s = (await db.splitsDao.byId(id))!;
      expect(splitProgress(s, await debts()).settled, 1);
      expect(memberStatuses(s, await debts())[budi.id], (share: 112500, paid: 112500, left: 0, settled: true));
      expect(await db.splitsDao.hasPayments(id), isTrue);
      expect(() => saveEven(payer: 0, id: id), throwsStateError);
    });

    test('ubah sebelum ada pembayaran: catatan lama diganti, id tetap', () async {
      final int id = await saveEven(payer: 0);
      expect(await saveEven(payer: 2, id: id), id);
      expect(await balance(), 1000000);
      expect(await expense(), 112500);
      final List<DebtWithPayments> ds = await db.debtsDao.watchAll().first;
      expect([for (final d in ds) (d.debt.name, d.debt.direction)], [('Sinta', DebtDirection.utang)]);
      expect((await db.splitsDao.byId(id))!.members.length, 4);
    });

    test('hapus patungan: pengeluaran, piutang & pembayarannya ikut terhapus, saldo kembali', () async {
      final int id = await saveEven(payer: 0);
      final SplitFull s = (await db.splitsDao.byId(id))!;
      await db.debtsDao.pay(s.members[1].debtId!, amount: 50000, paidAt: at, walletId: bca);
      await db.splitsDao.remove(id);
      expect(await balance(), 1000000);
      expect(await expense(), 0);
      expect(await db.debtsDao.watchAll().first, isEmpty);
      expect(await db.transactionsDao.watchRecent().first, isEmpty);
      expect(await db.select(db.splitMembers).get(), isEmpty);
    });

    test('per menu: item & peserta tersimpan; total harus sama dengan jumlah bagian', () async {
      final int id = await db.splitsDao.save(
        title: 'Pizza',
        mode: SplitMode.menu,
        total: 145000,
        walletId: bca,
        occurredAt: at,
        members: [
          (name: 'Aku', isMe: true, payer: true, share: 45000),
          (name: 'Budi', isMe: false, payer: false, share: 100000),
        ],
        items: [(name: 'Pizza', price: 99000, who: {0, 1}), (name: 'Pasta ×2', price: 51000, who: {1})],
        extraFee: 15000,
        discount: 20000,
      );
      final SplitFull s = (await db.splitsDao.byId(id))!;
      expect([for (final i in s.items) (i.name, i.who)], [('Pizza', '0,1'), ('Pasta ×2', '1')]);
      expect(s.itemsOf(1), ['Pizza', 'Pasta ×2']);
      expect((s.split.extraFee, s.split.discount), (15000, 20000));
      expect(
        () => db.splitsDao.save(
          title: 'Salah',
          mode: SplitMode.custom,
          total: 100000,
          walletId: bca,
          occurredAt: at,
          members: [
            (name: 'Aku', isMe: true, payer: true, share: 50000),
            (name: 'Budi', isMe: false, payer: false, share: 40000),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
