import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../settings/data/settings_dao.dart';
import '../../widgets/data/widget_style.dart';
import 'backup_codec.dart';

/// Ringkasan isi cadangan, ditampilkan sebelum pengguna memulihkan.
typedef BackupSummary = ({
  DateTime createdAt,
  int wallets,
  int transactions,
  int categories,
  int bills,
  int budgets,
  int recurring,
  int debts,
  int goals,
  int splits,
});

/// Mengubah seluruh isi database menjadi peta JSON dan sebaliknya.
/// PIN & kunci database tidak ikut (ada di Keystore, bukan di database).
class BackupService {
  BackupService(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const String appId = 'HitungIn';
  static const int format = 1;

  final AppDatabase db;
  final DateTime Function() _now;

  /// Pengaturan yang tidak ikut dipulihkan (status perangkat ini).
  static const Set<String> _localOnlySettings = {SettingKeys.onboardingDone, SettingKeys.lastBackupAt};

  Future<Map<String, Object?>> snapshot() async {
    List<Map<String, Object?>> rows(List<DataClass> list) => [for (final d in list) d.toJson()];
    return {
      'app': appId,
      'format': format,
      'schemaVersion': db.schemaVersion,
      'createdAt': _now().toIso8601String(),
      'tables': {
        'wallets': rows(await db.select(db.wallets).get()),
        'categories': rows(await db.select(db.categories).get()),
        'bills': rows(await db.select(db.bills).get()),
        'recurring': rows(await db.select(db.recurringTxs).get()),
        'splits': rows(await db.select(db.splits).get()),
        'splitMembers': rows(await db.select(db.splitMembers).get()),
        'splitItems': rows(await db.select(db.splitItems).get()),
        'debts': rows(await db.select(db.debts).get()),
        'debtPayments': rows(await db.select(db.debtPayments).get()),
        'goals': rows(await db.select(db.goals).get()),
        'goalDeposits': rows(await db.select(db.goalDeposits).get()),
        'transactions': rows(await db.select(db.transactions).get()),
        'budgets': rows(await db.select(db.budgets).get()),
        'budgetAdjustments': rows(await db.select(db.budgetAdjustments).get()),
        'netItems': rows(await db.select(db.netItems).get()),
        'netSnapshots': rows(await db.select(db.netSnapshots).get()),
        'settings': rows([
          for (final s in await db.select(db.settings).get())
            if (!_localOnlySettings.contains(s.key))
              // Foto widget tidak ikut cadangan (ukuran besar, tetap di HP ini).
              s.key == SettingKeys.widgetStyles ? s.copyWith(value: stripWidgetPhotos(s.value)) : s,
        ]),
      },
    };
  }

  /// Memeriksa isi cadangan tanpa mengubah apa pun.
  BackupSummary inspect(Map<String, Object?> data) {
    final Map<String, Object?> tables = _validate(data);
    int count(String t) => (tables[t] as List<Object?>? ?? const []).length;
    return (
      createdAt: DateTime.tryParse('${data['createdAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      wallets: count('wallets'),
      transactions: count('transactions'),
      categories: count('categories'),
      bills: count('bills'),
      budgets: count('budgets'),
      recurring: count('recurring'),
      debts: count('debts'),
      goals: count('goals'),
      splits: count('splits'),
    );
  }

  /// Buka lagi berkas terenkripsi dengan [password] dan pastikan isinya sama
  /// dengan [original] (jumlah baris per tabel). Melempar [FormatException]
  /// bila tidak cocok — dipanggil sebelum berkas disimpan.
  Future<void> verifyEncrypted(Uint8List bytes, String password, Map<String, Object?> original) async {
    final Map<String, Object?> back = await BackupCodec.decrypt(bytes, password);
    final Map<String, Object?> a = _validate(original);
    final Map<String, Object?> b = _validate(back);
    for (final String t in a.keys) {
      if ((a[t] as List<Object?>?)?.length != (b[t] as List<Object?>?)?.length) {
        throw FormatException('Isi cadangan tidak cocok ($t).');
      }
    }
  }

  /// MENGGANTI seluruh data dengan isi cadangan, dalam satu transaksi:
  /// kalau ada baris yang gagal, tidak ada yang berubah.
  Future<void> restore(Map<String, Object?> data) async {
    final Map<String, Object?> tables = _validate(data);
    List<Map<String, Object?>> rows(String name) => [
          for (final r in tables[name] as List<Object?>? ?? const []) Map<String, Object?>.from(r! as Map),
        ];

    await db.transaction(() async {
      // Hapus dari anak ke induk (foreign key aktif).
      await db.delete(db.transactions).go();
      await db.delete(db.goalDeposits).go();
      await db.delete(db.goals).go();
      await db.delete(db.splitItems).go();
      await db.delete(db.splitMembers).go();
      await db.delete(db.debtPayments).go();
      await db.delete(db.debts).go();
      await db.delete(db.splits).go();
      await db.delete(db.recurringTxs).go();
      await db.delete(db.budgetAdjustments).go();
      await db.delete(db.netItems).go();
      await db.delete(db.netSnapshots).go();
      await db.delete(db.budgets).go();
      await db.delete(db.bills).go();
      await db.delete(db.categories).go();
      await db.delete(db.wallets).go();
      await (db.delete(db.settings)..where((s) => s.key.isNotIn(_localOnlySettings))).go();

      await db.batch((b) {
        // Cadangan sebelum v4 tidak punya warna/sub-kategori → nilai bawaan.
        b.insertAll(db.wallets, [for (final r in rows('wallets')) Wallet.fromJson({'color': 0, ...r})]);
        b.insertAll(db.categories, [for (final r in rows('categories')) Category.fromJson({'color': 0, 'subs': '', ...r})]);
        // Cadangan sebelum v5 tidak punya kolom cicilan → tagihan biasa.
        b.insertAll(db.bills, [for (final r in rows('bills')) Bill.fromJson({'installmentPaid': 0, ...r})]);
        // Cadangan v1 tidak punya 'recurring' → kosong.
        b.insertAll(db.recurringTxs, [for (final r in rows('recurring')) RecurringTx.fromJson(r)]);
        // Cadangan sebelum v7 tidak punya patungan → kosong. Patungan dulu,
        // karena utang-piutang & transaksinya merujuk ke sana.
        b.insertAll(db.splits, [for (final r in rows('splits')) Split.fromJson(r)]);
        // Cadangan sebelum v5 tidak punya utang-piutang → kosong.
        b.insertAll(db.debts, [for (final r in rows('debts')) Debt.fromJson(r)]);
        b.insertAll(db.debtPayments, [for (final r in rows('debtPayments')) DebtPayment.fromJson(r)]);
        b.insertAll(db.splitMembers, [for (final r in rows('splitMembers')) SplitMember.fromJson(r)]);
        b.insertAll(db.splitItems, [for (final r in rows('splitItems')) SplitItem.fromJson(r)]);
        // Cadangan sebelum v6 tidak punya target tabungan → kosong.
        b.insertAll(db.goals, [for (final r in rows('goals')) Goal.fromJson(r)]);
        b.insertAll(db.goalDeposits, [for (final r in rows('goalDeposits')) GoalDeposit.fromJson(r)]);
        b.insertAll(db.transactions, [for (final r in rows('transactions')) Txn.fromJson({'sub': '', ...r})]);
        // Cadangan sebelum v3 tidak punya fromMonth → berlaku sejak awal.
        b.insertAll(db.budgets, [
          for (final r in rows('budgets'))
            Budget.fromJson({'fromMonth': DateTime(2000).millisecondsSinceEpoch, ...r}),
        ]);
        // Cadangan sebelum v9 tidak punya penyesuaian budget → kosong.
        b.insertAll(db.budgetAdjustments, [for (final r in rows('budgetAdjustments')) BudgetAdjustment.fromJson(r)]);
        // Cadangan sebelum v10 tidak punya Kekayaan bersih → kosong.
        b.insertAll(db.netItems, [for (final r in rows('netItems')) NetItem.fromJson(r)]);
        b.insertAll(db.netSnapshots, [for (final r in rows('netSnapshots')) NetSnapshot.fromJson(r)]);
        b.insertAll(
          db.settings,
          [for (final r in rows('settings')) Setting.fromJson(r)].where((s) => !_localOnlySettings.contains(s.key)),
          mode: InsertMode.insertOrReplace,
        );
      });
      // Data sekarang sama dengan isi cadangan ini → itulah cadangan terakhir.
      final DateTime? createdAt = DateTime.tryParse('${data['createdAt']}');
      if (createdAt != null) {
        await db.into(db.settings).insertOnConflictUpdate(
              SettingsCompanion.insert(key: SettingKeys.lastBackupAt, value: createdAt.toIso8601String()),
            );
      }
    });
  }

  Map<String, Object?> _validate(Map<String, Object?> data) {
    if (data['app'] != appId || data['format'] is! int) {
      throw const FormatException('Ini bukan cadangan HitungIn.');
    }
    if ((data['format']! as int) > format || (data['schemaVersion'] as int? ?? 0) > db.schemaVersion) {
      throw const FormatException('Cadangan dibuat oleh versi HitungIn yang lebih baru.');
    }
    final Object? tables = data['tables'];
    if (tables is! Map) throw const FormatException('Isi cadangan tidak lengkap.');
    return Map<String, Object?>.from(tables);
  }
}
