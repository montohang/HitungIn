import 'dart:convert';

import 'budget_insights.dart' show budgetStep;
import 'budgets_dao.dart';

/// Kelompok pengeluaran dalam template budget (P3f).
enum BudgetGroup {
  kebutuhan('Kebutuhan'),
  keinginan('Keinginan'),
  tabungan('Tabungan'),
  cicilan('Cicilan'),
  sedekah('Sedekah & zakat');

  const BudgetGroup(this.label);
  final String label;

  static BudgetGroup? parse(String? name) => BudgetGroup.values.where((g) => g.name == name).firstOrNull;
}

/// Template pembagian pemasukan.
enum BudgetTemplate {
  limaTigaDua('50/30/20', 'Separuh untuk kebutuhan, 30% untuk keinginan, 20% disisihkan untuk tabungan.',
      {BudgetGroup.kebutuhan: 50, BudgetGroup.keinginan: 30, BudgetGroup.tabungan: 20}),
  empatTigaDuaSatu('40/30/20/10', 'Kebutuhan 40%, tabungan & investasi 30%, cicilan 20%, sedekah & zakat 10%.',
      {BudgetGroup.kebutuhan: 40, BudgetGroup.tabungan: 30, BudgetGroup.cicilan: 20, BudgetGroup.sedekah: 10}),
  sendiri('Sendiri', 'Atur sendiri persentase tiap kelompok. Totalnya harus 100%.',
      {BudgetGroup.kebutuhan: 55, BudgetGroup.keinginan: 25, BudgetGroup.tabungan: 20});

  const BudgetTemplate(this.label, this.description, this.defaults);
  final String label;
  final String description;

  /// Persentase bawaan per kelompok (urutan = urutan tampil).
  final Map<BudgetGroup, int> defaults;

  static BudgetTemplate parse(String? name) =>
      BudgetTemplate.values.where((t) => t.name == name).firstOrNull ?? BudgetTemplate.limaTigaDua;
}

/// Langkah −/+ persentase di template Sendiri.
const int templatePercentStep = 5;

/// Kelompok asal kategori menurut ikonnya (bisa dipindah pengguna).
BudgetGroup homeGroupOf(String icon) => switch (icon) {
      'installment' => BudgetGroup.cicilan,
      'donation' || 'gift' => BudgetGroup.sedekah,
      'shopping' || 'fun' || 'coffee' || 'travel' || 'beauty' || 'game' || 'fitness' || 'other' => BudgetGroup.keinginan,
      _ => BudgetGroup.kebutuhan,
    };

/// Kelompok kategori di template dengan kelompok [groups]: pindahan pengguna
/// dulu, lalu kelompok asal; yang tidak ada di template → Kebutuhan (cicilan)
/// atau Keinginan (sedekah). Tabungan bukan kelompok belanja.
BudgetGroup groupIn(String icon, Set<BudgetGroup> groups, {BudgetGroup? moved}) {
  final Set<BudgetGroup> spend = groups.difference({BudgetGroup.tabungan});
  if (moved != null && spend.contains(moved)) return moved;
  final BudgetGroup home = homeGroupOf(icon);
  if (spend.contains(home)) return home;
  if (home == BudgetGroup.sedekah && spend.contains(BudgetGroup.keinginan)) return BudgetGroup.keinginan;
  return BudgetGroup.kebutuhan;
}

/// Kelompok berikutnya saat kategori diketuk (memutar kelompok belanja).
BudgetGroup nextSpendGroup(BudgetGroup current, Iterable<BudgetGroup> groups) {
  final List<BudgetGroup> spend = [for (final g in groups) if (g != BudgetGroup.tabungan) g];
  if (spend.isEmpty) return current;
  final int i = spend.indexOf(current);
  return spend[(i + 1) % spend.length];
}

typedef TemplateCategory = ({int id, String name, String icon, int average});
typedef TemplateItem = ({TemplateCategory category, int amount});
typedef GroupPlan = ({BudgetGroup group, int percent, int amount, List<TemplateItem> items});

/// Hasil template: per kelompok, total budget (tanpa Tabungan), saran tabungan.
class TemplatePlan {
  const TemplatePlan({required this.groups, required this.total, required this.savings});

  final List<GroupPlan> groups;
  final int total;
  final int savings;

  /// Batas per kategori (hanya yang > 0).
  Map<int, int> get perCategory => {
        for (final g in groups)
          for (final i in g.items)
            if (i.amount > 0) i.category.id: i.amount,
      };

  /// [n] kategori dengan batas terbesar (versi gratis).
  Map<int, int> top(int n) {
    final List<MapEntry<int, int>> sorted = perCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(n));
  }
}

int _round(int v, int step) => ((v + step ~/ 2) ~/ step) * step;

/// Bagi [income] ke kelompok sesuai [percents], lalu ke kategori sebanding
/// rata-rata 3 bulan. Kategori tanpa data mendapat 0, kecuali seluruh
/// kelompoknya tanpa data (dibagi rata). Jatah kelompok dibulatkan ke
/// [step]; jumlah batas kategori sama dengan jatah kelompoknya.
TemplatePlan planTemplate({
  required int income,
  required Map<BudgetGroup, int> percents,
  required List<TemplateCategory> categories,
  Map<int, BudgetGroup> moved = const {},
  int step = budgetStep,
}) {
  final Set<BudgetGroup> groups = percents.keys.toSet();
  final List<GroupPlan> out = [];
  int total = 0;
  int savings = 0;
  for (final MapEntry<BudgetGroup, int> e in percents.entries) {
    final int amount = _round(income * e.value ~/ 100, step);
    if (e.key == BudgetGroup.tabungan) {
      savings = amount;
      out.add((group: e.key, percent: e.value, amount: amount, items: const []));
      continue;
    }
    total += amount;
    final List<TemplateCategory> members = [
      for (final c in categories)
        if (groupIn(c.icon, groups, moved: moved[c.id]) == e.key) c,
    ];
    final int avgSum = members.fold(0, (s, c) => s + c.average);
    final List<int> weights = [for (final c in members) avgSum == 0 ? 1 : c.average];
    final int wSum = weights.fold(0, (s, w) => s + w);
    final List<int> amounts = [for (final w in weights) wSum == 0 ? 0 : (amount * w ~/ wSum) ~/ step * step];
    // Sisa pembulatan ke kategori dengan bobot terbesar.
    final int rest = amount - amounts.fold(0, (s, a) => s + a);
    if (rest != 0 && amounts.isNotEmpty) {
      int best = 0;
      for (int i = 1; i < weights.length; i++) {
        if (weights[i] > weights[best]) best = i;
      }
      amounts[best] += rest;
    }
    out.add((
      group: e.key,
      percent: e.value,
      amount: amount,
      items: [for (int i = 0; i < members.length; i++) (category: members[i], amount: amounts[i])],
    ));
  }
  return TemplatePlan(groups: out, total: total, savings: savings);
}

typedef SavingGoal = ({int id, String name, int left, DateTime? due});

/// Bagi saran setoran bulanan ke target aktif: sebanding sisa kekurangan per
/// bulan tersisa (tanpa tanggal = 12 bulan). Dibulatkan ke Rp1.000; selisih
/// pembulatan ke target pertama.
List<({SavingGoal goal, int amount})> splitSavings(int amount, List<SavingGoal> goals, DateTime now) {
  final List<SavingGoal> open = [for (final g in goals) if (g.left > 0) g];
  if (amount <= 0 || open.isEmpty) return const [];
  double perMonth(SavingGoal g) {
    if (g.due == null) return g.left / 12;
    final int months = (g.due!.year - now.year) * 12 + g.due!.month - now.month;
    return g.left / (months < 1 ? 1 : months);
  }

  final List<double> w = [for (final g in open) perMonth(g)];
  final double sum = w.fold(0, (s, v) => s + v);
  final List<int> parts = [for (final v in w) (amount * v / sum / 1000).floor() * 1000];
  parts[0] += amount - parts.fold(0, (s, v) => s + v);
  return [for (int i = 0; i < open.length; i++) if (parts[i] > 0) (goal: open[i], amount: parts[i])];
}

/// Pilihan template yang tersimpan (pengaturan `budget.template`).
class TemplateChoice {
  const TemplateChoice({this.template = BudgetTemplate.limaTigaDua, this.custom = const {}, this.moved = const {}});

  final BudgetTemplate template;

  /// Persentase template Sendiri.
  final Map<BudgetGroup, int> custom;

  /// Kategori yang dipindah kelompoknya.
  final Map<int, BudgetGroup> moved;

  Map<BudgetGroup, int> get percents =>
      template == BudgetTemplate.sendiri ? {...BudgetTemplate.sendiri.defaults, ...custom} : template.defaults;

  String encode() => jsonEncode({
        't': template.name,
        'c': {for (final e in custom.entries) e.key.name: e.value},
        'm': {for (final e in moved.entries) '${e.key}': e.value.name},
      });

  static TemplateChoice decode(String? raw) {
    if (raw == null || raw.isEmpty) return const TemplateChoice();
    try {
      final Map<String, Object?> j = Map<String, Object?>.from(jsonDecode(raw) as Map);
      final Map<String, Object?> c = Map<String, Object?>.from(j['c'] as Map? ?? const {});
      final Map<String, Object?> m = Map<String, Object?>.from(j['m'] as Map? ?? const {});
      return TemplateChoice(
        template: BudgetTemplate.parse(j['t'] as String?),
        custom: {
          for (final e in c.entries)
            if (BudgetGroup.parse(e.key) != null && e.value is int) BudgetGroup.parse(e.key)!: e.value! as int,
        },
        moved: {
          for (final e in m.entries)
            if (int.tryParse(e.key) != null && BudgetGroup.parse(e.value as String?) != null)
              int.parse(e.key): BudgetGroup.parse(e.value as String?)!,
        },
      );
    } on Object {
      return const TemplateChoice();
    }
  }
}

/// Sisa budget kategori di akhir bulan (yang belum terpakai).
typedef Leftover = ({int categoryId, String name, String icon, int left});

List<Leftover> leftovers(List<BudgetProgress> progress) => [
      for (final b in progress)
        if (b.category != null && b.budget.limitAmount > b.spent)
          (categoryId: b.category!.id, name: b.category!.name, icon: b.category!.icon, left: b.budget.limitAmount - b.spent),
    ];

/// Kartu sisa tampil tanggal 1–5 (sesudahnya sisa dianggap hangus).
const int leftoverLastDay = 5;

/// Pilihan untuk sisa satu kategori.
enum LeftoverChoice {
  bawa('Bawa'),
  setor('Setor ke target'),
  hangus('Hangus');

  const LeftoverChoice(this.label);
  final String label;
}

/// Tawaran pindah batas untuk kategori yang lewat: jumlah = kelebihan
/// dibulatkan ke atas ke [step]; sumber = kategori lain dengan sisa terbesar
/// yang cukup. Null bila tidak ada sumber.
typedef MoveOffer = ({int amount, List<BudgetProgress> donors});

MoveOffer? moveOffer(BudgetProgress over, List<BudgetProgress> all, {int step = budgetStep}) {
  final int excess = over.spent - over.budget.limitAmount;
  if (over.category == null || excess <= 0) return null;
  final int amount = ((excess + step - 1) ~/ step) * step;
  final List<BudgetProgress> donors = [
    for (final b in all)
      if (b.category != null && b.category!.id != over.category!.id && b.budget.limitAmount - b.spent >= amount) b,
  ]..sort((a, b) => (b.budget.limitAmount - b.spent).compareTo(a.budget.limitAmount - a.spent));
  if (donors.isEmpty) return null;
  return (amount: amount, donors: donors);
}
