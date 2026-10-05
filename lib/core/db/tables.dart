// Drift memakai getter yang merujuk dirinya sendiri di dalam .check().
// ignore_for_file: recursive_getters


import 'package:drift/drift.dart';

/// Jenis dompet. Disimpan sebagai teks (nama enum) — jangan mengganti
/// nama nilai yang sudah ada tanpa migrasi.
enum WalletType {
  tunai('Tunai'),
  bank('Bank'),
  ewallet('E-wallet'),
  lainnya('Lainnya');

  const WalletType(this.label);
  final String label;
}

/// Jenis transaksi. Kategori hanya punya [pengeluaran] / [pemasukan].
enum TxKind {
  pengeluaran('Pengeluaran'),
  pemasukan('Pemasukan'),
  transfer('Transfer');

  const TxKind(this.label);
  final String label;
}

/// Pengulangan tagihan.
enum BillRepeat {
  sekali('Sekali'),
  mingguan('Mingguan'),
  bulanan('Bulanan'),
  tahunan('Tahunan');

  const BillRepeat(this.label);
  final String label;
}

/// Semua nominal disimpan sebagai bilangan bulat Rupiah (tanpa sen),
/// sama seperti `Rupiah` di `core/utils`.

@DataClassName('Wallet')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => textEnum<WalletType>()();

  /// Saldo saat dompet dibuat. Saldo berjalan = ini + mutasi transaksi.
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();

  /// Kunci ikon (lihat `AppIcons`), bukan IconData, supaya lapisan data
  /// tidak bergantung pada Flutter.
  TextColumn get icon => text().withDefault(const Constant('wallet'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Hanya [TxKind.pengeluaran] atau [TxKind.pemasukan].
  TextColumn get kind => textEnum<TxKind>()();
  TextColumn get icon => text().withDefault(const Constant('other'))();

  /// Kata kunci untuk Catat Cepat, dipisah koma: `kopi,makan,nasi`.
  TextColumn get keywords => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('Txn')
@TableIndex(name: 'tx_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'tx_wallet', columns: {#walletId})
@TableIndex(name: 'tx_category', columns: {#categoryId})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<TxKind>()();

  /// Selalu positif; arah uang ditentukan oleh [kind].
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();

  /// Dompet sumber (pengeluaran/transfer) atau tujuan (pemasukan).
  @ReferenceName('sourceTransactions')
  IntColumn get walletId => integer().references(Wallets, #id)();

  /// Dompet tujuan, hanya untuk transfer.
  @ReferenceName('incomingTransfers')
  IntColumn get toWalletId => integer().nullable().references(Wallets, #id)();

  /// Kosong untuk transfer.
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Tagihan asal, bila transaksi dibuat dari "Bayar tagihan".
  IntColumn get billId => integer().nullable().references(Bills, #id, onDelete: KeyAction.setNull)();

  /// Jadwal asal, bila transaksi dicatat otomatis oleh transaksi berulang (v2).
  IntColumn get recurringId => integer().nullable().references(RecurringTxs, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
        "CHECK ((kind = 'transfer') = (to_wallet_id IS NOT NULL))",
        "CHECK (kind != 'transfer' OR to_wallet_id != wallet_id)",
      ];
}

/// Batas belanja bulanan. [categoryId] kosong = batas total semua
/// pengeluaran. Satu baris per kategori, berlaku setiap bulan.
@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// 0 = "tanpa budget mulai [fromMonth]" (menghapus target lama untuk bulan itu dst.).
  IntColumn get limitAmount => integer().check(limitAmount.isBiggerOrEqualValue(0))();

  /// Bulan (tanggal 1) target ini mulai berlaku (v3). Target bulan M = baris
  /// dengan [fromMonth] terbesar yang ≤ M. Data lama = berlaku sejak awal.
  DateTimeColumn get fromMonth => dateTime().withDefault(Constant(DateTime(2000)))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, fromMonth},
      ];
}

@DataClassName('Bill')
class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get walletId => integer().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)();

  /// Jatuh tempo berikutnya (tanggal saja, jam 00.00).
  DateTimeColumn get nextDue => dateTime()();
  TextColumn get repeat => textEnum<BillRepeat>()();

  /// Tanggal asli jatuh tempo (1–31), supaya tagihan tanggal 31 tidak
  /// bergeser permanen ke 28 setelah melewati Februari.
  IntColumn get anchorDay => integer().check(anchorDay.isBetweenValues(1, 31))();
  IntColumn get remindDaysBefore => integer().withDefault(const Constant(1))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Transaksi berulang (Pro, v2): dicatat otomatis setiap jatuh tempo,
/// mis. gaji tiap tanggal 25 atau langganan bulanan yang didebet otomatis.
/// Berbeda dengan [Bills] yang hanya mengingatkan dan dibayar manual.
@DataClassName('RecurringTx')
class RecurringTxs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<TxKind>()();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  @ReferenceName('recurringSources')
  IntColumn get walletId => integer().references(Wallets, #id)();
  @ReferenceName('recurringTargets')
  IntColumn get toWalletId => integer().nullable().references(Wallets, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Hanya mingguan/bulanan/tahunan (bukan [BillRepeat.sekali]).
  TextColumn get repeat => textEnum<BillRepeat>()();
  IntColumn get anchorDay => integer().check(anchorDay.isBetweenValues(1, 31))();

  /// Tanggal pencatatan berikutnya (00.00).
  DateTimeColumn get nextRun => dateTime()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
        "CHECK ((kind = 'transfer') = (to_wallet_id IS NOT NULL))",
        "CHECK (repeat != 'sekali')",
      ];
}

/// Pengaturan sederhana kunci–nilai (tema, aksen, onboarding selesai, …).
@DataClassName('Setting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
