import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/dates.dart';
import 'goals.dart';

part 'goals_dao.g.dart';

/// Target beserta setoran/ambilnya (lama → baru).
typedef GoalWithDeposits = ({Goal goal, List<GoalDeposit> deposits});

extension GoalWithDepositsX on GoalWithDeposits {
  int get saved => deposits.fold(0, (sum, d) => sum + d.amount);
  int get left => (goal.target - saved).clamp(0, goal.target);
  int get percent => goalPercent(saved, goal.target);
  bool get reached => saved >= goal.target;

  /// Aktif = belum diarsipkan dan belum tercapai (yang dibatasi versi gratis).
  bool get active => !goal.archived && goal.achievedAt == null;
  List<DepositFact> get facts => [for (final d in deposits) (amount: d.amount, walletId: d.walletId, at: d.at)];
  GoalEstimate estimate(DateTime now) =>
      goalEstimate(target: goal.target, saved: saved, dueDate: goal.dueDate, deposits: facts, now: now);
}

@DriftAccessor(tables: [Goals, GoalDeposits])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.attachedDatabase);

  /// Semua target (urutan dibuat), dengan setorannya.
  Stream<List<GoalWithDeposits>> watchAll() {
    final q = select(goals).join([leftOuterJoin(goalDeposits, goalDeposits.goalId.equalsExp(goals.id))])
      ..orderBy([
        OrderingTerm(expression: goals.createdAt),
        OrderingTerm(expression: goals.id),
        OrderingTerm(expression: goalDeposits.at),
        OrderingTerm(expression: goalDeposits.id),
      ]);
    return q.watch().map((rows) {
      final Map<int, (Goal, List<GoalDeposit>)> acc = {};
      for (final TypedResult r in rows) {
        final Goal g = r.readTable(goals);
        final (Goal, List<GoalDeposit>) entry = acc.putIfAbsent(g.id, () => (g, []));
        final GoalDeposit? d = r.readTableOrNull(goalDeposits);
        if (d != null) entry.$2.add(d);
      }
      return [for (final (Goal g, List<GoalDeposit> ds) in acc.values) (goal: g, deposits: ds)];
    });
  }

  Future<GoalWithDeposits?> byId(int id) async {
    final Goal? g = await (select(goals)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (g == null) return null;
    final List<GoalDeposit> ds = await (select(goalDeposits)
          ..where((d) => d.goalId.equals(id))
          ..orderBy([(d) => OrderingTerm(expression: d.at), (d) => OrderingTerm(expression: d.id)]))
        .get();
    return (goal: g, deposits: ds);
  }

  Future<int> add({required String name, required int target, String emoji = '🎯', DateTime? dueDate, String note = ''}) {
    _validate(name, target);
    return into(goals).insert(GoalsCompanion.insert(
      name: name.trim(),
      target: target,
      emoji: Value(emoji),
      dueDate: Value(dueDate == null ? null : Dates.day(dueDate)),
      note: Value(note.trim()),
    ));
  }

  /// Ubah target. Bila target dinaikkan melewati terkumpul, status tercapai dilepas.
  Future<void> edit(Goal g) => transaction(() async {
        _validate(g.name, g.target);
        final int saved = await _saved(g.id);
        await update(goals).replace(g.copyWith(
          name: g.name.trim(),
          note: g.note.trim(),
          dueDate: Value(g.dueDate == null ? null : Dates.day(g.dueDate!)),
          achievedAt: Value(saved >= g.target ? (g.achievedAt ?? DateTime.now()) : null),
        ));
      });

  Future<void> setArchived(int id, bool archived) =>
      (update(goals)..where((g) => g.id.equals(id))).write(GoalsCompanion(archived: Value(archived)));

  Future<void> setReminder(int id, {required bool on, int? weekday, int? hour}) =>
      (update(goals)..where((g) => g.id.equals(id))).write(GoalsCompanion(
        remind: Value(on),
        remindWeekday: weekday == null ? const Value.absent() : Value(weekday),
        remindHour: hour == null ? const Value.absent() : Value(hour),
      ));

  /// Hapus target beserta riwayat setorannya.
  Future<void> remove(int id) => (delete(goals)..where((g) => g.id.equals(id))).go();

  /// Setor (+[amount]) ke target. Saat terkumpul mencapai target, tanggal
  /// tercapai dicatat. Mengembalikan terkumpul sesudahnya.
  Future<int> deposit(int goalId, {required int amount, required DateTime at, int? walletId}) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
    return _move(goalId, amount, at, walletId);
  }

  /// Ambil [amount] dari target (kembali jadi uang bebas). Tidak boleh
  /// melebihi terkumpul.
  Future<int> withdraw(int goalId, {required int amount, required DateTime at, int? walletId}) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
    return _move(goalId, -amount, at, walletId);
  }

  Future<void> removeDeposit(int id) => transaction(() async {
        final GoalDeposit? d = await (select(goalDeposits)..where((x) => x.id.equals(id))).getSingleOrNull();
        if (d == null) return;
        await (delete(goalDeposits)..where((x) => x.id.equals(id))).go();
        await _syncAchieved(d.goalId, DateTime.now());
      });

  Future<int> _move(int goalId, int delta, DateTime at, int? walletId) => transaction(() async {
        final Goal? g = await (select(goals)..where((x) => x.id.equals(goalId))).getSingleOrNull();
        if (g == null) throw StateError('Target tidak ditemukan');
        final int saved = await _saved(goalId);
        if (saved + delta < 0) throw ArgumentError.value(-delta, 'amount', 'Melebihi yang terkumpul');
        await into(goalDeposits)
            .insert(GoalDepositsCompanion.insert(goalId: goalId, amount: delta, walletId: Value(walletId), at: at));
        await _syncAchieved(goalId, at);
        return saved + delta;
      });

  /// Tercapai dicatat sekali saat menyentuh target; dilepas bila turun lagi.
  Future<void> _syncAchieved(int goalId, DateTime at) async {
    final Goal? g = await (select(goals)..where((x) => x.id.equals(goalId))).getSingleOrNull();
    if (g == null) return;
    final bool reached = await _saved(goalId) >= g.target;
    if (reached && g.achievedAt == null) {
      await (update(goals)..where((x) => x.id.equals(goalId))).write(GoalsCompanion(achievedAt: Value(at)));
    } else if (!reached && g.achievedAt != null) {
      await (update(goals)..where((x) => x.id.equals(goalId))).write(const GoalsCompanion(achievedAt: Value(null)));
    }
  }

  Future<int> _saved(int goalId) async {
    final Expression<int> sum = goalDeposits.amount.sum();
    final int? v = await (selectOnly(goalDeposits)
          ..addColumns([sum])
          ..where(goalDeposits.goalId.equals(goalId)))
        .map((r) => r.read(sum))
        .getSingle();
    return v ?? 0;
  }

  static void _validate(String name, int target) {
    if (name.trim().isEmpty) throw ArgumentError('Nama wajib diisi');
    if (target <= 0) throw ArgumentError.value(target, 'target', 'Nominal harus lebih dari 0');
  }
}
