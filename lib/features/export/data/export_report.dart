import '../../../core/db/app_database.dart';
import '../../../core/utils/date_format.dart';
import '../../budget/data/budgets_dao.dart';
import '../../debts/data/debts_dao.dart';
import '../../goals/data/goals.dart';
import '../../goals/data/goals_dao.dart';
import '../../networth/data/net_worth.dart';
import '../../splits/data/splits_dao.dart';
import '../../transactions/data/transactions_dao.dart';

/// Format berkas export (P3g).
enum ExportFormat {
  pdf('PDF laporan', 'pdf', 'application/pdf'),
  xlsx('Excel (.xlsx)', 'xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  csv('CSV', 'csv', 'text/csv');

  const ExportFormat(this.label, this.extension, this.mimeType);
  final String label;
  final String extension;
  final String mimeType;
}

/// Pilihan periode export.
enum ExportPeriod {
  bulanIni('Bulan ini'),
  bulanLalu('Bulan lalu'),
  tigaBulan('3 bulan'),
  tahunIni('Tahun ini'),
  semua('Semua'),
  pilih('Pilih sendiri');

  const ExportPeriod(this.label);
  final String label;
}

/// Rentang [from, to) — `to` eksklusif (awal hari sesudah hari terakhir).
typedef DateRange = ({DateTime from, DateTime to});

/// Rentang periode. [custom] dipakai untuk [ExportPeriod.pilih]; [firstData]
/// = tanggal transaksi pertama untuk [ExportPeriod.semua].
DateRange exportRange(ExportPeriod p, DateTime now, {DateRange? custom, DateTime? firstData}) {
  final DateTime m = DateTime(now.year, now.month);
  final DateTime endOfMonth = DateTime(now.year, now.month + 1);
  return switch (p) {
    ExportPeriod.bulanIni => (from: m, to: endOfMonth),
    ExportPeriod.bulanLalu => (from: DateTime(now.year, now.month - 1), to: m),
    ExportPeriod.tigaBulan => (from: DateTime(now.year, now.month - 2), to: endOfMonth),
    ExportPeriod.tahunIni => (from: DateTime(now.year), to: endOfMonth),
    ExportPeriod.semua => (
        from: firstData == null ? m : DateTime(firstData.year, firstData.month, firstData.day),
        to: endOfMonth,
      ),
    ExportPeriod.pilih => custom ?? (from: m, to: endOfMonth),
  };
}

/// "1–29 Okt 2026", "Agu – Okt 2026", "Oktober 2026".
String rangeLabel(DateRange r, DateTime now) {
  final DateTime last = r.to.subtract(const Duration(days: 1));
  final bool wholeMonth = r.from.day == 1 && r.to == DateTime(r.from.year, r.from.month + 1);
  if (wholeMonth) return DateFmt.month(r.from);
  String d(DateTime x) => '${x.day} ${DateFmt.monthsShort[x.month - 1]} ${x.year}';
  if (r.from.year == last.year && r.from.month == last.month) {
    return '${r.from.day}–${last.day} ${DateFmt.monthsShort[last.month - 1]} ${last.year}';
  }
  if (r.from.day == 1 && r.to.day == 1) {
    return '${DateFmt.monthsShort[r.from.month - 1]}${r.from.year == last.year ? '' : ' ${r.from.year}'} – '
        '${DateFmt.monthsShort[last.month - 1]} ${last.year}';
  }
  return '${d(r.from)} – ${d(last)}';
}

/// Versi gratis: PDF bulan berjalan saja (P3g).
bool exportAllowedFree(ExportFormat f, DateRange r, DateTime now) =>
    f == ExportFormat.pdf && r.from == DateTime(now.year, now.month) && r.to == DateTime(now.year, now.month + 1);

/// Semua data untuk satu berkas export.
class ExportInput {
  ExportInput({
    required this.range,
    required this.createdAt,
    required this.walletLabel,
    required this.txs,
    required this.wallets,
    required this.balancesAtEnd,
    required this.budgets,
    required this.debts,
    required this.bills,
    required this.goals,
    required this.splits,
    required this.recurring,
    this.netWorth,
  });

  final DateRange range;
  final DateTime createdAt;

  /// "Semua dompet" / "BCA".
  final String walletLabel;

  /// Transaksi periode (sudah difilter dompet), urut terbaru dulu.
  final List<TxDetail> txs;
  final List<Wallet> wallets;
  final Map<int, int> balancesAtEnd;

  /// Budget per bulan dalam periode (batas sesudah penyesuaian).
  final Map<DateTime, List<BudgetProgress>> budgets;
  final List<DebtWithPayments> debts;
  final List<Bill> bills;
  final List<GoalWithDeposits> goals;
  final List<SplitFull> splits;
  final List<RecurringTx> recurring;

  /// Kekayaan bersih saat export (hanya untuk semua dompet).
  final NetWorth? netWorth;

  String get periodLabel => rangeLabel(range, createdAt);
  Map<int, String> get walletNames => {for (final w in wallets) w.id: w.name};

  /// Bulan (tanggal 1) dalam periode.
  List<DateTime> get months => [
        for (DateTime m = DateTime(range.from.year, range.from.month);
            m.isBefore(range.to);
            m = DateTime(m.year, m.month + 1))
          m,
      ];
}

typedef ExportSummary = ({
  int income,
  int expense,
  int net,
  double? savingRate,
  int avgDaily,
  int count,
  String? topCategory,
});

int _signed(TxDetail d) => switch (d.tx.kind) {
      TxKind.pemasukan || TxKind.utangMasuk => d.tx.amount,
      TxKind.pengeluaran || TxKind.utangKeluar => -d.tx.amount,
      TxKind.transfer => 0,
    };

/// Nominal bertanda untuk sheet/tabel: keluar negatif, transfer positif.
int signedAmount(TxDetail d) => d.tx.kind == TxKind.transfer ? d.tx.amount : _signed(d);

/// Ringkasan periode: transfer & utang-piutang tidak dihitung.
ExportSummary summarize(ExportInput x) {
  int income = 0, expense = 0;
  final Map<String, int> byCat = {};
  for (final d in x.txs) {
    if (d.tx.kind == TxKind.pemasukan) income += d.tx.amount;
    if (d.tx.kind == TxKind.pengeluaran) {
      expense += d.tx.amount;
      final String c = d.category?.name ?? 'Tanpa kategori';
      byCat[c] = (byCat[c] ?? 0) + d.tx.amount;
    }
  }
  final DateTime today = DateTime(x.createdAt.year, x.createdAt.month, x.createdAt.day + 1);
  final DateTime end = x.range.to.isBefore(today) ? x.range.to : today;
  final int days = end.difference(x.range.from).inDays.clamp(1, 100000);
  final String? top = byCat.isEmpty ? null : (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  return (
    income: income,
    expense: expense,
    net: income - expense,
    savingRate: income > 0 ? (income - expense) / income : null,
    avgDaily: expense ~/ days,
    count: x.txs.length,
    topCategory: top,
  );
}

typedef MonthRow = ({DateTime month, int income, int expense});

List<MonthRow> monthly(ExportInput x) => [
      for (final m in x.months)
        (
          month: m,
          income: x.txs
              .where((d) => d.tx.kind == TxKind.pemasukan && _inMonth(d.tx.occurredAt, m))
              .fold(0, (s, d) => s + d.tx.amount),
          expense: x.txs
              .where((d) => d.tx.kind == TxKind.pengeluaran && _inMonth(d.tx.occurredAt, m))
              .fold(0, (s, d) => s + d.tx.amount),
        ),
    ];

bool _inMonth(DateTime at, DateTime m) => at.year == m.year && at.month == m.month;

/// Pengeluaran per [key] per bulan, urut total terbesar.
List<({String name, Map<DateTime, int> perMonth, int total})> expenseMatrix(
  ExportInput x,
  String? Function(TxDetail) key,
) {
  final Map<String, Map<DateTime, int>> m = {};
  for (final d in x.txs) {
    if (d.tx.kind != TxKind.pengeluaran) continue;
    final String? k = key(d);
    if (k == null) continue;
    final DateTime month = DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month);
    final Map<DateTime, int> row = m.putIfAbsent(k, () => {});
    row[month] = (row[month] ?? 0) + d.tx.amount;
  }
  final rows = [
    for (final e in m.entries) (name: e.key, perMonth: e.value, total: e.value.values.fold(0, (s, v) => s + v)),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return rows;
}

typedef WalletRow = ({Wallet wallet, int inflow, int outflow, int transferIn, int transferOut, int balance});

List<WalletRow> perWallet(ExportInput x) => [
      for (final w in x.wallets)
        (
          wallet: w,
          inflow: x.txs
              .where((d) => d.wallet.id == w.id && d.tx.kind.isInflow)
              .fold(0, (s, d) => s + d.tx.amount),
          outflow: x.txs
              .where((d) => d.wallet.id == w.id && (d.tx.kind == TxKind.pengeluaran || d.tx.kind == TxKind.utangKeluar))
              .fold(0, (s, d) => s + d.tx.amount),
          transferIn: x.txs
              .where((d) => d.tx.kind == TxKind.transfer && d.toWallet?.id == w.id)
              .fold(0, (s, d) => s + d.tx.amount),
          transferOut: x.txs
              .where((d) => d.tx.kind == TxKind.transfer && d.wallet.id == w.id)
              .fold(0, (s, d) => s + d.tx.amount),
          balance: x.balancesAtEnd[w.id] ?? w.initialBalance,
        ),
    ];

/// Pengeluaran per tanggal (hanya hari yang ada pengeluaran), urut tanggal.
List<({DateTime day, int expense, int count})> daily(ExportInput x) {
  final Map<DateTime, ({int expense, int count})> m = {};
  for (final d in x.txs) {
    if (d.tx.kind != TxKind.pengeluaran) continue;
    final DateTime day = DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month, d.tx.occurredAt.day);
    final prev = m[day] ?? (expense: 0, count: 0);
    m[day] = (expense: prev.expense + d.tx.amount, count: prev.count + 1);
  }
  return [for (final e in (m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) (day: e.key, expense: e.value.expense, count: e.value.count)];
}

/// Saldo tiap dompet sesudah semua transaksi sebelum [to].
Map<int, int> balancesAt(List<Wallet> wallets, List<TxDetail> all, DateTime to) {
  final Map<int, int> out = {for (final w in wallets) w.id: w.initialBalance};
  for (final d in all) {
    if (!d.tx.occurredAt.isBefore(to)) continue;
    final int from = d.wallet.id;
    switch (d.tx.kind) {
      case TxKind.pemasukan || TxKind.utangMasuk:
        out[from] = (out[from] ?? 0) + d.tx.amount;
      case TxKind.pengeluaran || TxKind.utangKeluar:
        out[from] = (out[from] ?? 0) - d.tx.amount;
      case TxKind.transfer:
        out[from] = (out[from] ?? 0) - d.tx.amount;
        if (d.toWallet != null) out[d.toWallet!.id] = (out[d.toWallet!.id] ?? 0) + d.tx.amount;
    }
  }
  return out;
}

/// "Rp1,71 jt dari Rp6 jt · tercapai sekitar Apr 2027".
String goalLine(GoalWithDeposits g, DateTime now) => goalEstimateText(
      goalEstimate(target: g.goal.target, saved: g.saved, dueDate: g.goal.dueDate, deposits: g.facts, now: now),
      now: now,
    );

/// Kumpulkan data export dari database.
Future<ExportInput> loadExportInput(
  AppDatabase db, {
  required DateRange range,
  required DateTime now,
  int? walletId,
  bool includeManualNet = true,
}) async {
  final List<TxDetail> all = await db.transactionsDao.allDetails();
  final List<Wallet> allWallets = await db.walletsDao.all();
  final List<Wallet> wallets = [
    for (final w in allWallets)
      if (walletId == null ? !w.archived : w.id == walletId) w,
  ];
  bool touches(TxDetail d) => walletId == null || d.wallet.id == walletId || d.toWallet?.id == walletId;
  final List<TxDetail> txs = [
    for (final d in all)
      if (!d.tx.occurredAt.isBefore(range.from) && d.tx.occurredAt.isBefore(range.to) && touches(d)) d,
  ];
  final Map<DateTime, List<BudgetProgress>> budgets = {};
  for (DateTime m = DateTime(range.from.year, range.from.month); m.isBefore(range.to); m = DateTime(m.year, m.month + 1)) {
    final List<BudgetProgress> p = await db.budgetsDao.progress(m);
    if (p.isNotEmpty) budgets[m] = p;
  }
  final List<SplitFull> splits = [
    for (final s in await db.splitsDao.watchAll().first)
      if (!s.split.occurredAt.isBefore(range.from) && s.split.occurredAt.isBefore(range.to)) s,
  ];
  final List<DebtWithPayments> debts = await db.debtsDao.watchAll().first;
  final List<Bill> bills = await db.billsDao.watchActive().first;
  final NetWorth? netWorth = walletId != null
      ? null
      : computeNetWorth(
          wallets: await db.walletsDao.watchBalances().first,
          debts: debts,
          bills: bills,
          items: await db.netWorthDao.items(),
          includeManual: includeManualNet,
        );
  return ExportInput(
    range: range,
    createdAt: now,
    walletLabel: walletId == null ? 'Semua dompet' : (wallets.firstOrNull?.name ?? 'Dompet'),
    txs: txs,
    wallets: wallets,
    balancesAtEnd: balancesAt(allWallets, all, range.to.isAfter(now) ? now.add(const Duration(seconds: 1)) : range.to),
    budgets: budgets,
    debts: debts,
    bills: bills,
    goals: [for (final g in await db.goalsDao.watchAll().first) if (!g.goal.archived) g],
    splits: splits,
    recurring: await db.recurringDao.watchAll().first,
    netWorth: netWorth,
  );
}

/// Nama berkas: hitungin-laporan-2026-10.pdf / hitungin-2026-08_2026-10.xlsx.
String exportFileName(ExportFormat f, DateRange r) {
  final DateTime last = r.to.subtract(const Duration(days: 1));
  final String a = DateFmt.monthKey(r.from), b = DateFmt.monthKey(last);
  final String span = a == b ? a : '${a}_$b';
  return f == ExportFormat.pdf ? 'hitungin-laporan-$span.pdf' : 'hitungin-$span.${f.extension}';
}
