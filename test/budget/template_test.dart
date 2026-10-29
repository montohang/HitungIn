import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/backup/data/backup_service.dart';
import 'package:hitungin/features/budget/data/budget_template.dart';
import 'package:hitungin/features/budget/widgets/leftover_card.dart' show applyLeftovers;
import 'package:hitungin/features/dev/sample_data.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

AppDatabase _db() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

const List<TemplateCategory> _cats = [
  (id: 1, name: 'Makan & Minum', icon: 'food', average: 1300000),
  (id: 2, name: 'Transportasi', icon: 'transport', average: 620000),
  (id: 3, name: 'Tagihan', icon: 'bills', average: 600000),
  (id: 4, name: 'Belanja', icon: 'shopping', average: 880000),
  (id: 5, name: 'Hiburan', icon: 'fun', average: 300000),
  (id: 6, name: 'Cicilan HP', icon: 'installment', average: 650000),
  (id: 7, name: 'Sosial', icon: 'gift', average: 150000),
  (id: 8, name: 'Pendidikan', icon: 'education', average: 0),
];

void main() {
  test('50/30/20: Kebutuhan 4 jt, Keinginan 2,4 jt jadi budget; Tabungan 1,6 jt saran setoran; jumlah kategori = jatah kelompok', () {
    final TemplatePlan p = planTemplate(income: 8000000, percents: BudgetTemplate.limaTigaDua.defaults, categories: _cats);
    expect([for (final g in p.groups) (g.group, g.amount)], [
      (BudgetGroup.kebutuhan, 4000000),
      (BudgetGroup.keinginan, 2400000),
      (BudgetGroup.tabungan, 1600000),
    ]);
    expect((p.total, p.savings), (6400000, 1600000));
    for (final g in p.groups.where((g) => g.group != BudgetGroup.tabungan)) {
      expect(g.items.fold(0, (s, i) => s + i.amount), g.amount, reason: g.group.label);
      expect(g.items.every((i) => i.amount % 50000 == 0), isTrue);
    }
    // Tanpa kelompok Cicilan/Sedekah: cicilan → Kebutuhan, sosial → Keinginan.
    final kebutuhan = p.groups.first.items.map((i) => i.category.name).toList();
    expect(kebutuhan, containsAll(['Makan & Minum', 'Cicilan HP', 'Pendidikan']));
    expect(p.groups[1].items.map((i) => i.category.name), containsAll(['Belanja', 'Hiburan', 'Sosial']));
    // Kategori tanpa data mendapat 0 bila kelompoknya punya data.
    expect(p.groups.first.items.firstWhere((i) => i.category.name == 'Pendidikan').amount, 0);
    // Sebanding kebiasaan: Makan (1,3 jt) > Transportasi (620 rb).
    final int makan = p.perCategory[1]!, transport = p.perCategory[2]!;
    expect(makan > transport, isTrue);
    expect(p.top(2).keys, [1, 4], reason: 'versi gratis: 2 kategori terbesar');
  });

  test('40/30/20/10: cicilan & sedekah punya kelompok sendiri; pindah kelompok; kelompok tanpa data dibagi rata', () {
    TemplatePlan p = planTemplate(income: 8000000, percents: BudgetTemplate.empatTigaDuaSatu.defaults, categories: _cats);
    GroupPlan g(BudgetGroup x) => p.groups.firstWhere((e) => e.group == x);
    expect((g(BudgetGroup.cicilan).amount, g(BudgetGroup.cicilan).items.single.category.name), (1600000, 'Cicilan HP'));
    expect((g(BudgetGroup.sedekah).amount, g(BudgetGroup.sedekah).items.single.category.name), (800000, 'Sosial'));
    expect((p.total, p.savings), (5600000, 2400000));
    // Belanja dipindah ke Kebutuhan.
    p = planTemplate(
      income: 8000000,
      percents: BudgetTemplate.empatTigaDuaSatu.defaults,
      categories: _cats,
      moved: {4: BudgetGroup.kebutuhan},
    );
    expect(g(BudgetGroup.kebutuhan).items.map((i) => i.category.name), contains('Belanja'));
    expect(nextSpendGroup(BudgetGroup.kebutuhan, BudgetTemplate.empatTigaDuaSatu.defaults.keys), BudgetGroup.cicilan);
    // Kelompok tanpa data sama sekali → dibagi rata.
    final noData = [for (final c in _cats) (id: c.id, name: c.name, icon: c.icon, average: 0)];
    final p2 = planTemplate(income: 6000000, percents: BudgetTemplate.limaTigaDua.defaults, categories: noData);
    final amounts = p2.groups.first.items.map((i) => i.amount).toSet();
    expect(amounts.length <= 2, isTrue, reason: 'rata, selisih pembulatan di satu kategori');
    expect(p2.groups.first.items.fold(0, (s, i) => s + i.amount), 3000000);
  });

  test('template Sendiri & pilihan tersimpan bolak-balik', () {
    const choice = TemplateChoice(
      template: BudgetTemplate.sendiri,
      custom: {BudgetGroup.kebutuhan: 60, BudgetGroup.keinginan: 20, BudgetGroup.tabungan: 20},
      moved: {4: BudgetGroup.kebutuhan},
    );
    final back = TemplateChoice.decode(choice.encode());
    expect(back.template, choice.template);
    expect(back.percents, choice.percents);
    expect(back.moved, choice.moved);
    expect(TemplateChoice.decode('rusak{').template, BudgetTemplate.limaTigaDua);
    expect(TemplateChoice.decode(null).percents, BudgetTemplate.limaTigaDua.defaults);
  });

  test('saran setoran dibagi ke target menurut sisa per bulan tersisa; tanpa target → kosong', () {
    final now = DateTime(2026, 10, 23);
    final split = splitSavings(1600000, [
      (id: 1, name: 'Liburan Bali', left: 5900000, due: DateTime(2027, 4, 20)),
      (id: 2, name: 'Dana darurat', left: 3000000, due: null),
      (id: 3, name: 'Sudah tercapai', left: 0, due: null),
    ], now);
    expect(split.map((s) => s.goal.name), ['Liburan Bali', 'Dana darurat']);
    expect(split.fold(0, (s, x) => s + x.amount), 1600000);
    expect(split.first.amount > split.last.amount, isTrue, reason: 'Bali bertenggat lebih dekat');
    expect(splitSavings(1600000, const [], now), isEmpty);
  });

  test('pindah batas: tawaran dari kategori dengan sisa terbesar; batas & total; urungkan', () async {
    final db = _db();
    final w = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 5000000);
    final cats = await db.categoriesDao.active();
    int id(String n) => cats.firstWhere((c) => c.name == n).id;
    final oct = DateTime(2026, 10);
    await db.budgetsDao.saveAll(month: oct, total: 3000000, perCategory: {id('Makan & Minum'): 1400000, id('Hiburan'): 300000, id('Transportasi'): 700000});
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 1480000, walletId: w, categoryId: id('Makan & Minum'), occurredAt: DateTime(2026, 10, 20));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 100000, walletId: w, categoryId: id('Hiburan'), occurredAt: DateTime(2026, 10, 20));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 560000, walletId: w, categoryId: id('Transportasi'), occurredAt: DateTime(2026, 10, 20));
    var progress = await db.budgetsDao.progress(oct);
    final per = [for (final b in progress) if (b.category != null) b];
    final over = per.firstWhere((b) => b.category!.name == 'Makan & Minum');
    final offer = moveOffer(over, per)!;
    expect(offer.amount, 100000, reason: 'lewat 80 rb → dibulatkan ke 100 rb');
    expect(offer.donors.map((d) => d.category!.name), ['Hiburan', 'Transportasi']);

    await db.budgetsDao.moveLimit(oct, from: id('Hiburan'), to: id('Makan & Minum'), amount: 100000);
    progress = await db.budgetsDao.progress(oct);
    int limit(String? n) => progress.firstWhere((b) => b.category?.name == n).budget.limitAmount;
    expect((limit('Makan & Minum'), limit('Hiburan'), limit(null)), (1500000, 200000, 3000000));
    expect((await db.budgetsDao.progress(DateTime(2026, 11))).firstWhere((b) => b.category?.name == 'Hiburan').budget.limitAmount, 300000,
        reason: 'berlaku bulan itu saja');
    expect((await db.budgetsDao.limitsFor(oct))[id('Makan & Minum')], 1500000, reason: 'Rapor memakai batas sesudah penyesuaian');

    await db.budgetsDao.undoLastMove(oct);
    progress = await db.budgetsDao.progress(oct);
    expect((limit('Makan & Minum'), limit('Hiburan')), (1400000, 300000));
    await db.close();
  });

  test('sisa akhir bulan: bawa menambah batas kategori bulan depan (total tetap), setor jadi setoran target, hangus diabaikan, ditandai selesai', () async {
    final db = _db();
    final w = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 5000000);
    final cats = await db.categoriesDao.active();
    int id(String n) => cats.firstWhere((c) => c.name == n).id;
    final oct = DateTime(2026, 10), nov = DateTime(2026, 11);
    await db.budgetsDao.saveAll(month: oct, total: 3000000, perCategory: {id('Makan & Minum'): 1400000, id('Belanja'): 1000000, id('Hiburan'): 300000});
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 1250000, walletId: w, categoryId: id('Makan & Minum'), occurredAt: DateTime(2026, 10, 20));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 880000, walletId: w, categoryId: id('Belanja'), occurredAt: DateTime(2026, 10, 21));
    await db.transactionsDao.add(kind: TxKind.pengeluaran, amount: 300000, walletId: w, categoryId: id('Hiburan'), occurredAt: DateTime(2026, 10, 22));
    final items = leftovers(await db.budgetsDao.progress(oct));
    expect({for (final l in items) l.name: l.left}, {'Makan & Minum': 150000, 'Belanja': 120000}, reason: 'Hiburan habis → tidak ada sisa');

    final goalId = await db.goalsDao.add(name: 'Liburan Bali', target: 6000000);
    final r = await applyLeftovers(
      db,
      from: oct,
      to: nov,
      items: items,
      choices: {id('Makan & Minum'): LeftoverChoice.bawa, id('Belanja'): LeftoverChoice.setor},
      goal: (id: goalId, name: 'Liburan Bali', left: 6000000, due: null),
      walletId: w,
      now: DateTime(2026, 11, 1, 9),
    );
    expect((r.carried, r.deposited), (150000, 120000));
    final novP = await db.budgetsDao.progress(nov);
    expect(novP.firstWhere((b) => b.category?.name == 'Makan & Minum').budget.limitAmount, 1550000);
    expect(novP.firstWhere((b) => b.category == null).budget.limitAmount, 3000000, reason: 'total tetap jadi batas utama');
    expect(await db.budgetsDao.watchCarried(nov).first, 150000);
    expect(novP.firstWhere((b) => b.category?.name == 'Belanja').budget.limitAmount, 1000000);
    final g = (await db.goalsDao.watchAll().first).single;
    expect(g.deposits.single.amount, 120000);
    expect(await db.settingsDao.read(SettingKeys.budgetLeftoverDone), '2026-10');
    await db.close();
  });

  test('rata-rata pemasukan 3 bulan dari bulan yang ada pemasukannya; penyesuaian budget ikut backup', () async {
    final db = _db();
    final w = await db.walletsDao.add(name: 'BCA', type: WalletType.bank);
    final gaji = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Gaji').id;
    await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 8000000, walletId: w, categoryId: gaji, occurredAt: DateTime(2026, 8, 25));
    await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 9000000, walletId: w, categoryId: gaji, occurredAt: DateTime(2026, 9, 25));
    await db.transactionsDao.add(kind: TxKind.pemasukan, amount: 9500000, walletId: w, categoryId: gaji, occurredAt: DateTime(2026, 10, 25));
    expect(await db.transactionsDao.incomeAverage(DateTime(2026, 10)), 8500000, reason: 'Agu & Sep, bulan berjalan tidak dihitung');
    expect(await db.transactionsDao.incomeAverage(DateTime(2026, 1)), 0);

    final makan = (await db.categoriesDao.active()).firstWhere((c) => c.name == 'Makan & Minum').id;
    await db.budgetsDao.setLimit(categoryId: makan, limitAmount: 1000000);
    await db.budgetsDao.carryOver(DateTime(2026, 11), {makan: 150000});
    final snap = await BackupService(db).snapshot();
    final target = _db();
    await BackupService(target).restore(snap);
    expect((await target.budgetsDao.adjustments(DateTime(2026, 11)))[makan], 150000);
    await db.close();
    await target.close();
  });

  test('data uji debug: bulan lalu ada sisa, bulan ini Makan lewat batas, pemasukan rata-rata terisi', () async {
    final db = _db();
    await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai, initialBalance: 200000);
    final now = DateTime(2026, 10, 29, 14);
    expect(await seedSampleData(db, now), greaterThan(100));
    expect(leftovers(await db.budgetsDao.progress(DateTime(2026, 9))), isNotEmpty);
    final oct = await db.budgetsDao.progress(DateTime(2026, 10));
    final makan = oct.firstWhere((b) => b.category?.name == 'Makan & Minum');
    expect(makan.spent > makan.budget.limitAmount, isTrue);
    expect(await db.transactionsDao.incomeAverage(DateTime(2026, 10)), 8500000);
    await db.close();
  });
}
