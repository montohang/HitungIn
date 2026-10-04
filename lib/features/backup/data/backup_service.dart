import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../settings/data/settings_dao.dart';

/// Ringkasan isi cadangan, ditampilkan sebelum pengguna memulihkan.
typedef BackupSummary = ({DateTime createdAt, int wallets, int transactions, int categories, int bills, int budgets});

/// Mengubah seluruh isi database menjadi peta JSON dan sebaliknya.
/// PIN & kunci database tidak ikut (ada di Keystore, bukan di database).
class BackupService {
  BackupService(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const String appId = 'HitungIn';
  static const int format = 1;

  final AppDatabase db;
  final DateTime Function() _now;

  /// Pengaturan yang tidak ikut dipulihkan (status perangkat ini).
  static const Set<String> _localOnlySettings = {SettingKeys.onboardingDone};

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
        'transactions': rows(await db.select(db.transactions).get()),
        'budgets': rows(await db.select(db.budgets).get()),
        'settings': rows([
          for (final s in await db.select(db.settings).get())
            if (!_localOnlySettings.contains(s.key)) s,
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
    );
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
      await db.delete(db.budgets).go();
      await db.delete(db.bills).go();
      await db.delete(db.categories).go();
      await db.delete(db.wallets).go();
      await (db.delete(db.settings)..where((s) => s.key.isNotIn(_localOnlySettings))).go();

      await db.batch((b) {
        b.insertAll(db.wallets, [for (final r in rows('wallets')) Wallet.fromJson(r)]);
        b.insertAll(db.categories, [for (final r in rows('categories')) Category.fromJson(r)]);
        b.insertAll(db.bills, [for (final r in rows('bills')) Bill.fromJson(r)]);
        b.insertAll(db.transactions, [for (final r in rows('transactions')) Txn.fromJson(r)]);
        b.insertAll(db.budgets, [for (final r in rows('budgets')) Budget.fromJson(r)]);
        b.insertAll(
          db.settings,
          [for (final r in rows('settings')) Setting.fromJson(r)].where((s) => !_localOnlySettings.contains(s.key)),
          mode: InsertMode.insertOrReplace,
        );
      });
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
