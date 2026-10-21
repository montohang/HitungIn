import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/bills/data/bill_reminders.dart' show ReminderPlan;
import 'package:hitungin/features/bills/reminder_scheduler.dart';
import 'package:hitungin/features/rapor/data/rapor.dart';
import 'package:hitungin/features/rapor/data/rapor_reminders.dart';

RaporTx tx(TxKind kind, int amount, DateTime at, {int? cat, int? billId, DateTime? billDue, bool auto = false, String note = ''}) =>
    (kind: kind, amount: amount, categoryId: cat, at: at, billId: billId, billDue: billDue, auto: auto, note: note);

/// Pemasukan & pengeluaran sederhana, tercatat tiap hari di September.
List<RaporTx> september({int income = 10000000, int expense = 8000000, int days = 30}) => [
      tx(TxKind.pemasukan, income, DateTime(2026, 9, 1, 9)),
      for (int d = 1; d <= days; d++) tx(TxKind.pengeluaran, expense ~/ days, DateTime(2026, 9, d, 12), cat: 1),
    ];

RaporInput input(List<RaporTx> txs,
        {int balance = 0,
        List<RaporBill> bills = const [],
        Map<DateTime, List<RaporBudget>> budgets = const {},
        List<({int amount, DateTime due})> utang = const [],
        DateTime? now}) =>
    RaporInput(
      txs: txs,
      categoryNames: const {1: 'Makan & Minum', 2: 'Belanja'},
      bills: bills,
      budgets: budgets,
      balanceNow: balance,
      now: now ?? DateTime(2026, 10, 2, 9),
      utangDue: utang,
    );

AspectScore score(Rapor r, RaporAspect a) => r.scores.firstWhere((s) => s.aspect == a);

void main() {
  final DateTime sep = DateTime(2026, 9);

  group('Menabung', () {
    test('batas Juara ≥20%, Aman 10–19%, Nanggung 0–9%, Waduh minus', () {
      RaporGrade? g(int expense) => score(computeRapor(input(september(expense: expense)), sep), RaporAspect.menabung).grade;
      expect(g(8000000), RaporGrade.juara);
      expect(g(8100000), RaporGrade.aman);
      expect(g(9000000), RaporGrade.aman);
      expect(g(9100000), RaporGrade.nanggung);
      expect(g(10000000), RaporGrade.nanggung);
      expect(g(10100000), RaporGrade.waduh);
    });

    test('tanpa pemasukan → belum dinilai (Menabung & Beban cicilan)', () {
      final Rapor r = computeRapor(input([tx(TxKind.pengeluaran, 50000, DateTime(2026, 9, 3))]), sep);
      expect(score(r, RaporAspect.menabung).grade, isNull);
      expect(score(r, RaporAspect.cicilan).grade, isNull);
      expect(score(r, RaporAspect.menabung).reason, 'Belum dinilai: pemasukan belum dicatat');
    });

    test('transfer & utang-piutang tidak dihitung sebagai masuk/keluar', () {
      final Rapor r = computeRapor(
          input([
            ...september(),
            tx(TxKind.transfer, 3000000, DateTime(2026, 9, 5)),
            tx(TxKind.utangKeluar, 500000, DateTime(2026, 9, 6)),
          ]),
          sep);
      expect((r.income, r.expense), (10000000, 7999980), reason: '8 jt ÷ 30 hari dibulatkan ke bawah per hari');
    });
  });

  group('Tagihan & cicilan', () {
    RaporBill bill(int id, String name, {bool installment = false, DateTime? next, bool active = true}) =>
        (id: id, name: name, amount: 400000, installment: installment, nextDue: next ?? DateTime(2026, 10, 25), active: active);

    test('semua tepat Juara; 1 telat ≤7 hari Aman; telat lebih banyak Nanggung', () {
      List<RaporTx> pays(List<int> lateDays) => [
            for (final (int i, int late) in lateDays.indexed)
              tx(TxKind.pengeluaran, 400000, DateTime(2026, 9, 10 + late, 10), billId: i + 1, billDue: DateTime(2026, 9, 10)),
          ];
      final List<RaporBill> bills = [bill(1, 'Internet'), bill(2, 'Listrik'), bill(3, 'Kos')];
      RaporGrade? g(List<int> late) =>
          score(computeRapor(input([...september(), ...pays(late)], bills: bills), sep), RaporAspect.tagihan).grade;
      expect(g([0, 0, 0]), RaporGrade.juara);
      expect(g([0, 3, 0]), RaporGrade.aman);
      expect(g([0, 9, 0]), RaporGrade.nanggung);
      expect(g([2, 3, 0]), RaporGrade.nanggung);
      final Rapor r = computeRapor(input([...september(), ...pays([0, 3, 0])], bills: bills), sep);
      expect(score(r, RaporAspect.tagihan).reason, '2 dari 3 tepat · Listrik telat 3 hari');
    });

    test('belum dibayar > 30 hari → Waduh; pembayaran lama tanpa jatuh tempo dianggap tepat', () {
      final RaporBill unpaid = bill(1, 'Kredivo', next: DateTime(2026, 9, 5));
      final Rapor r = computeRapor(input(september(), bills: [unpaid], now: DateTime(2026, 10, 8)), sep);
      expect(score(r, RaporAspect.tagihan).grade, RaporGrade.waduh);
      final Rapor old = computeRapor(
          input([...september(), tx(TxKind.pengeluaran, 400000, DateTime(2026, 9, 28), billId: 2)], bills: [bill(2, 'Kos')]), sep);
      expect(score(old, RaporAspect.tagihan).grade, RaporGrade.juara);
      expect(score(computeRapor(input(september()), sep), RaporAspect.tagihan).grade, isNull);
    });

    test('beban cicilan: cicilan + utang jatuh tempo ÷ pemasukan; tanpa cicilan Juara "bebas cicilan"', () {
      final List<RaporTx> base = september(income: 10000000);
      List<RaporTx> inst(int amount) =>
          [tx(TxKind.pengeluaran, amount, DateTime(2026, 9, 15), billId: 1, billDue: DateTime(2026, 9, 15))];
      final List<RaporBill> bills = [bill(1, 'SPayLater', installment: true)];
      RaporGrade? g(int amount, {int utang = 0}) => score(
              computeRapor(
                  input([...base, ...inst(amount)], bills: bills, utang: [if (utang > 0) (amount: utang, due: DateTime(2026, 9, 20))]),
                  sep),
              RaporAspect.cicilan)
          .grade;
      expect(g(2000000), RaporGrade.juara);
      expect(g(2000000, utang: 1000000), RaporGrade.aman);
      expect(g(3500000), RaporGrade.nanggung);
      expect(g(4100000), RaporGrade.waduh);
      expect(score(computeRapor(input(base), sep), RaporAspect.cicilan).reason, 'Bebas cicilan bulan ini');
    });
  });

  group('Disiplin budget', () {
    Rapor run(Map<int, int> spend, List<RaporBudget> budgets) => computeRapor(
          input([
            tx(TxKind.pemasukan, 10000000, DateTime(2026, 9, 1)),
            for (final e in spend.entries) tx(TxKind.pengeluaran, e.value, DateTime(2026, 9, 10), cat: e.key),
          ], budgets: {sep: budgets}),
          sep,
        );

    test('semua aman Juara; 1 jebol ≤10% Aman; lebih Nanggung; total >120% Waduh; tanpa budget belum dinilai', () {
      final List<RaporBudget> b = [(categoryId: 1, limit: 1000000), (categoryId: 2, limit: 500000)];
      expect(score(run({1: 900000, 2: 400000}, b), RaporAspect.budget).grade, RaporGrade.juara);
      expect(score(run({1: 1080000, 2: 400000}, b), RaporAspect.budget).grade, RaporGrade.aman);
      expect(score(run({1: 1200000, 2: 400000}, b), RaporAspect.budget).grade, RaporGrade.nanggung);
      expect(score(run({1: 1050000, 2: 550000}, b), RaporAspect.budget).grade, RaporGrade.nanggung);
      expect(score(run({1: 900000}, [...b, (categoryId: null, limit: 700000)]), RaporAspect.budget).grade, RaporGrade.waduh);
      expect(score(run({1: 900000}, const []), RaporAspect.budget).grade, isNull);
      expect(score(run({1: 1080000, 2: 400000}, b), RaporAspect.budget).reason, '1 dari 2 aman · Makan & Minum jebol 8%');
    });
  });

  group('Ketahanan & rajin mencatat', () {
    test('saldo akhir bulan (dihitung mundur dari saldo sekarang) ÷ rata-rata pengeluaran', () {
      // Akhir Sep saldo = 9 jt − (Oktober: +1 jt) = 8 jt; rata-rata keluar 2 jt → 4 bulan.
      final List<RaporTx> txs = [
        ...september(income: 3000000, expense: 2000000),
        tx(TxKind.pemasukan, 1000000, DateTime(2026, 10, 1)),
      ];
      final AspectScore s = score(computeRapor(input(txs, balance: 9000000), sep), RaporAspect.ketahanan);
      expect(s.grade, RaporGrade.aman);
      expect(s.value, closeTo(4, 0.001));
      expect(score(computeRapor(input(txs, balance: 13000000), sep), RaporAspect.ketahanan).grade, RaporGrade.juara);
      expect(score(computeRapor(input(txs, balance: 2500000), sep), RaporAspect.ketahanan).grade, RaporGrade.waduh);
    });

    test('hari dihitung sejak catatan pertama; catatan otomatis tidak dihitung; < 50% = data kurang', () {
      final List<RaporTx> late = [
        tx(TxKind.pemasukan, 5000000, DateTime(2026, 9, 21)),
        for (int d = 21; d <= 30; d++) tx(TxKind.pengeluaran, 50000, DateTime(2026, 9, d)),
      ];
      final Rapor r = computeRapor(input(late), sep);
      expect((r.daysLogged, r.daysCounted, score(r, RaporAspect.mencatat).grade), (10, 10, RaporGrade.juara));
      final Rapor few = computeRapor(
          input([
            tx(TxKind.pemasukan, 5000000, DateTime(2026, 9, 1)),
            for (int d = 1; d <= 30; d += 4) tx(TxKind.pengeluaran, 50000, DateTime(2026, 9, d)),
            for (int d = 2; d <= 30; d += 4) tx(TxKind.pengeluaran, 50000, DateTime(2026, 9, d), auto: true),
          ]),
          sep);
      expect((few.daysLogged, score(few, RaporAspect.mencatat).grade, few.lowData), (8, RaporGrade.nanggung, true));
      expect(few.headline, 'Awal yang baik — lengkapi catatanmu');
    });
  });

  group('Nilai keseluruhan, tren & Kata HitungIn', () {
    test('rata-rata aspek yang dinilai; naik dari bulan lalu → "Level up!"', () {
      final List<RaporTx> txs = [
        // Agustus: tekor, sedikit mencatat.
        tx(TxKind.pemasukan, 5000000, DateTime(2026, 8, 1)),
        tx(TxKind.pengeluaran, 5500000, DateTime(2026, 8, 2), cat: 1),
        ...september(),
      ];
      final Rapor r = computeRapor(input(txs, balance: 50000000), sep);
      expect(r.previous, isNotNull);
      expect(r.overall, RaporGrade.juara);
      expect(r.trendOf(RaporAspect.menabung), 1);
      expect(r.headline, startsWith('Level up!'));
      expect(r.note, contains('Sisa uangmu naik dari'));
      expect(RaporGrade.fromAverage(3.5), RaporGrade.juara);
      expect(RaporGrade.fromAverage(3.49), RaporGrade.aman);
      expect(RaporGrade.fromAverage(1.5), RaporGrade.nanggung);
      expect(RaporGrade.fromAverage(1.49), RaporGrade.waduh);
    });

    test('bulan rapor: dari bulan pertama tercatat sampai bulan lalu, terbaru dulu', () {
      final RaporInput i = input([tx(TxKind.pengeluaran, 1000, DateTime(2026, 7, 20))], now: DateTime(2026, 10, 21));
      expect(raporMonths(i), [DateTime(2026, 9), DateTime(2026, 8), DateTime(2026, 7)]);
      expect(raporMonths(input(const [])), isEmpty);
    });

    test('saran: budget jebol → Atur budget; tagihan telat → pengingat; maks 3', () {
      final Rapor r = computeRapor(
          input([
            ...september(expense: 9000000),
            tx(TxKind.pengeluaran, 400000, DateTime(2026, 9, 20), billId: 1, billDue: DateTime(2026, 9, 15)),
          ], bills: [
            (id: 1, name: 'Internet', amount: 400000, installment: false, nextDue: DateTime(2026, 10, 15), active: true)
          ], budgets: {
            sep: [(categoryId: 1, limit: 8000000)]
          }),
          sep);
      expect([for (final t in r.tips) t.target], [RaporAction.aturBudget, RaporAction.tagihan, RaporAction.target]);
    });
  });

  group('Prakiraan bulan berjalan', () {
    test('melewati budget total → muncul; aman → tidak; awal bulan (< tgl 5) → tidak', () {
      final Forecast? f = computeForecast(now: DateTime(2026, 10, 19), spent: 3120000, totalLimit: 4200000, categories: const []);
      expect(f, isNotNull);
      expect((f!.projected, f.daysLeft, f.perDayToFit), (5090526, 12, 90000));
      expect(computeForecast(now: DateTime(2026, 10, 19), spent: 1000000, totalLimit: 4200000, categories: const []), isNull);
      expect(computeForecast(now: DateTime(2026, 10, 3), spent: 3000000, totalLimit: 1000000, categories: const []), isNull);
    });

    test('kategori ≥ 80% dengan sisa hari → muncul walau total aman', () {
      final Forecast? f = computeForecast(
          now: DateTime(2026, 10, 19), spent: 1000000, totalLimit: null, categories: [(name: 'Makan & Minum', spent: 1150000, limit: 1400000)]);
      expect(f?.hot, [(name: 'Makan & Minum', pct: 82)]);
    });
  });

  group('Notifikasi & data', () {
    test('tanggal 1 berikutnya pukul 08.00; mati → tidak ada', () {
      final List<ReminderPlan> p = planRaporReminder(now: DateTime(2026, 10, 21, 9), enabled: true);
      expect((p.single.at, p.single.title, p.single.payload), (DateTime(2026, 11, 1, 8), 'Rapor Oktober sudah terbit 📋', 'recap:month'));
      expect(planRaporReminder(now: DateTime(2026, 11, 1, 7), enabled: true).single.at, DateTime(2026, 11, 1, 8));
      expect(planRaporReminder(now: DateTime(2026, 10, 21), enabled: false), isEmpty);
      expect(routeForNotification('recap:month'), '/rapor');
    });

    test('bayar tagihan menyimpan jatuh temponya (untuk menilai ketepatan waktu)', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      final int w = await db.walletsDao.add(name: 'BCA', type: WalletType.bank, initialBalance: 1000000);
      await db.billsDao.add(name: 'Internet', amount: 350000, dueDate: DateTime(2026, 10, 13), repeat: BillRepeat.bulanan, walletId: w);
      final Bill b = (await db.billsDao.watchActive().first).single;
      final int id = await db.billsDao.pay(b, paidAt: DateTime(2026, 10, 16, 9));
      expect((await db.transactionsDao.byId(id))!.billDue, DateTime(2026, 10, 13));
      await db.close();
    });
  });
}
