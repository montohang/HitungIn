import '../../../core/utils/dates.dart';
import 'budgets_dao.dart';

/// Ringkasan budget satu bulan: dari budget total bila ada, selain itu
/// jumlah semua budget kategori.
typedef BudgetOverview = ({int limit, int spent, bool fromTotal});

BudgetOverview? budgetOverview(List<BudgetProgress> list) {
  if (list.isEmpty) return null;
  for (final BudgetProgress b in list) {
    if (b.category == null) return (limit: b.budget.limitAmount, spent: b.spent, fromTotal: true);
  }
  return (
    limit: list.fold(0, (s, b) => s + b.budget.limitAmount),
    spent: list.fold(0, (s, b) => s + b.spent),
    fromTotal: false,
  );
}

/// Bagian bulan yang sudah berjalan (hari ke-19 dari 31 → 0,61).
double monthElapsed(DateTime now) => now.day / Dates.daysInMonth(now.year, now.month);

/// Hari tersisa setelah hari ini (19 Okt → 12).
int daysLeftInMonth(DateTime now) => Dates.daysInMonth(now.year, now.month) - now.day;

/// Kategori yang paling "lebih cepat dari jadwal": pemakaian ≥ 80% dan
/// melebihi waktu berjalan. Null bila semua aman.
BudgetProgress? hottestCategory(List<BudgetProgress> list, DateTime now) {
  final double elapsed = monthElapsed(now);
  BudgetProgress? worst;
  double worstRatio = 0;
  for (final BudgetProgress b in list) {
    if (b.category == null || b.budget.limitAmount <= 0) continue;
    final double r = b.spent / b.budget.limitAmount;
    if (r >= 0.8 && r > elapsed && r > worstRatio) {
      worst = b;
      worstRatio = r;
    }
  }
  return worst;
}

/// Batas belanja per hari supaya aman sampai akhir bulan (desain: "sisa
/// Rp250rb untuk 12 hari → sekitar Rp20rb per hari"). 0 bila sudah habis.
int safeDailySpend(BudgetProgress b, DateTime now) {
  final int left = b.budget.limitAmount - b.spent;
  if (left <= 0) return 0;
  final int days = daysLeftInMonth(now);
  return left ~/ (days < 1 ? 1 : days);
}

/// Nama pendek untuk chip: "Makan & Minum" → "Makan".
String shortCategoryName(String name) => name.split(RegExp(r'[\s&]+')).first;
