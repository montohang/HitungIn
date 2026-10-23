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
///
/// [utangKeluar] / [utangMasuk] (v5) = uang keluar/masuk dompet karena
/// utang-piutang: mengubah saldo tetapi tidak dihitung sebagai pengeluaran
/// atau pemasukan di Laporan, Budget, maupun Jatah. Hanya dibuat oleh
/// `DebtsDao`, tidak bisa dipilih di Catat.
enum TxKind {
  pengeluaran('Pengeluaran'),
  pemasukan('Pemasukan'),
  transfer('Transfer'),
  utangKeluar('Utang-piutang'),
  utangMasuk('Utang-piutang');

  const TxKind(this.label);
  final String label;

  bool get isDebt => this == utangKeluar || this == utangMasuk;

  /// Jenis yang bisa dipilih di Catat & transaksi berulang.
  static const List<TxKind> manual = [pengeluaran, pemasukan, transfer];

  /// Menambah saldo dompet sumbernya ([walletId]).
  bool get isInflow => this == pemasukan || this == utangMasuk;
}

/// Arah catatan utang-piutang (v5).
enum DebtDirection {
  /// Orang lain berutang ke aku (aku meminjamkan).
  piutang('Ditagih ke orang'),

  /// Aku berutang ke orang lain (aku meminjam).
  utang('Utangku');

  const DebtDirection(this.label);
  final String label;
}

/// Cara bagi patungan (v7).
enum SplitMode {
  rata('Rata'),
  custom('Custom'),
  menu('Per menu');

  const SplitMode(this.label);
  final String label;
}

/// Asal penyesuaian batas budget satu bulan (v9).
enum BudgetAdjustReason {
  /// Sisa bulan lalu yang dibawa.
  carry,

  /// Batas dipindah dari/ke kategori lain.
  move,
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

  /// Indeks warna di `AppPalette` (v4).
  IntColumn get color => integer().withDefault(const Constant(0))();
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

  /// Indeks warna di `AppPalette` (v4).
  IntColumn get color => integer().withDefault(const Constant(0))();

  /// Sub-kategori, dipisah koma: `Kopi,Makan siang,Jajan` (v4). Juga dikenali Catat cepat.
  TextColumn get subs => text().withDefault(const Constant(''))();
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

  /// Sub-kategori terpilih (salah satu dari `Categories.subs`), kosong = tidak ada (v4).
  TextColumn get sub => text().withDefault(const Constant(''))();

  /// Tagihan asal, bila transaksi dibuat dari "Bayar tagihan".
  IntColumn get billId => integer().nullable().references(Bills, #id, onDelete: KeyAction.setNull)();

  /// Jatuh tempo tagihan yang dibayar transaksi ini (v8), untuk menilai
  /// ketepatan waktu di Rapor. Kosong untuk pembayaran sebelum v8.
  DateTimeColumn get billDue => dateTime().nullable()();

  /// Jadwal asal, bila transaksi dicatat otomatis oleh transaksi berulang (v2).
  IntColumn get recurringId => integer().nullable().references(RecurringTxs, #id, onDelete: KeyAction.setNull)();

  /// Catatan utang-piutang asal (v5). Ikut terhapus bersama catatannya.
  IntColumn get debtId => integer().nullable().references(Debts, #id, onDelete: KeyAction.cascade)();

  /// Pembayaran utang asal (v5); kosong = transaksi pinjaman awal.
  IntColumn get debtPaymentId => integer().nullable().references(DebtPayments, #id, onDelete: KeyAction.cascade)();

  /// Patungan asal (v7): pengeluaran sebesar bagianku. Ikut terhapus bersama patungannya.
  IntColumn get splitId => integer().nullable().references(Splits, #id, onDelete: KeyAction.cascade)();
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

/// Penyesuaian batas budget untuk SATU bulan saja (v9, P3f): sisa bulan lalu
/// yang dibawa ([BudgetAdjustReason.carry]) atau batas yang dipindah antar-
/// kategori saat lewat batas ([BudgetAdjustReason.move]). [categoryId] kosong =
/// budget total. Batas efektif bulan M = target + jumlah penyesuaian bulan M.
@DataClassName('BudgetAdjustment')
class BudgetAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Tanggal 1 bulan yang disesuaikan.
  DateTimeColumn get month => dateTime()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// Bisa negatif (kategori asal pindah batas). Tidak boleh 0.
  IntColumn get amount => integer().check(amount.equals(0).not())();
  TextColumn get reason => textEnum<BudgetAdjustReason>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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

  /// Cicilan (v5): jumlah cicilan (tenor, 2–60); kosong = tagihan biasa.
  IntColumn get installmentTotal => integer().nullable().check(installmentTotal.isBetweenValues(2, 60))();

  /// Cicilan yang sudah dibayar. Saat sama dengan tenor, tagihan selesai.
  IntColumn get installmentPaid => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Catatan utang-piutang (v5). Sisa = [amount] − jumlah [DebtPayments].
/// Bila [walletId] diisi, pinjaman awal tercatat sebagai transaksi
/// utangKeluar/utangMasuk sehingga saldo dompet ikut berubah.
@DataClassName('Debt')
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get direction => textEnum<DebtDirection>()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  IntColumn get walletId => integer().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get occurredAt => dateTime()();

  /// Jatuh tempo (tanggal saja), opsional.
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Patungan asal (v7); ikut terhapus bersama patungannya.
  IntColumn get splitId => integer().nullable().references(Splits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Pembayaran (sebagian) satu catatan utang-piutang (v5).
@DataClassName('DebtPayment')
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  IntColumn get walletId => integer().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Patungan (v7, P3c). Bagianku jadi pengeluaran ([Transactions.splitId]);
/// bagian teman jadi catatan utang-piutang ([Debts.splitId]).
@DataClassName('Split')
class Splits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  TextColumn get mode => textEnum<SplitMode>()();
  IntColumn get total => integer().check(total.isBiggerThanValue(0))();

  /// Dompet yang dipakai: membayar (aku yang bayar) atau tempat utangku dicatat.
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();

  /// Per menu: pajak & service dalam persen ×10 (100 = 10%), ongkir, diskon.
  IntColumn get taxPermille => integer().withDefault(const Constant(0))();
  IntColumn get servicePermille => integer().withDefault(const Constant(0))();
  IntColumn get extraFee => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Peserta patungan beserta bagiannya (v7). Tepat satu [isMe]; [payer] =
/// yang membayar ke kasir.
@DataClassName('SplitMember')
class SplitMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get splitId => integer().references(Splits, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  BoolColumn get payer => boolean().withDefault(const Constant(false))();
  IntColumn get share => integer().check(share.isBiggerOrEqualValue(0))();
  IntColumn get position => integer()();

  /// Catatan utang-piutang untuk bagian ini (kosong untuk aku / bila tidak perlu).
  IntColumn get debtId => integer().nullable().references(Debts, #id, onDelete: KeyAction.setNull)();
}

/// Item menu patungan (v7). [who] = posisi peserta yang ikut, dipisah koma.
@DataClassName('SplitItem')
class SplitItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get splitId => integer().references(Splits, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get price => integer().check(price.isBiggerThanValue(0))();
  TextColumn get who => text()();
  IntColumn get position => integer()();
}

/// Target tabungan (v6, P3b). Terkumpul = jumlah [GoalDeposits]. Uangnya
/// tetap di dompet asal setoran; hanya "disisihkan" dari Jatah hari ini.
@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Satu emoji (ikon target).
  TextColumn get emoji => text().withDefault(const Constant('🎯'))();
  IntColumn get target => integer().check(target.isBiggerThanValue(0))();

  /// Tanggal target (tanggal saja), opsional.
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Saat terkumpul pertama kali mencapai target.
  DateTimeColumn get achievedAt => dateTime().nullable()();

  /// Diarsipkan: tidak tampil di daftar aktif dan tidak lagi disisihkan dari Jatah.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// Pengingat setoran mingguan (bawaan mati): hari (1 = Senin) & jam.
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  IntColumn get remindWeekday => integer().withDefault(const Constant(1)).check(remindWeekday.isBetweenValues(1, 7))();
  IntColumn get remindHour => integer().withDefault(const Constant(19)).check(remindHour.isBetweenValues(0, 23))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Setoran (positif) atau ambil (negatif) satu target (v6). [walletId] =
/// dompet tempat uangnya disisihkan; menentukan apakah Jatah ikut dipotong.
@DataClassName('GoalDeposit')
class GoalDeposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer().check(amount.equals(0).not())();
  IntColumn get walletId => integer().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get at => dateTime()();
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
