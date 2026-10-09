import '../../../core/db/app_database.dart';

/// Alasan jenis transaksi yang sedang diubah tidak boleh diganti ke [target],
/// atau null bila boleh. Pengeluaran ↔ Pemasukan boleh (memperbaiki salah
/// catat); Pindah saldo dan transaksi dari tagihan/berulang dikunci.
String? kindLockReason(Txn editing, TxKind target) {
  if (target == editing.kind) return null;
  if (editing.billId != null) {
    return 'Transaksi dari tagihan tidak bisa diubah jenisnya. Hapus lalu catat ulang bila perlu.';
  }
  if (editing.recurringId != null) {
    return 'Transaksi berulang tidak bisa diubah jenisnya. Hapus lalu catat ulang bila perlu.';
  }
  if (editing.kind == TxKind.transfer) {
    return 'Pindah saldo tidak bisa diubah jenisnya. Hapus lalu catat ulang bila perlu.';
  }
  if (target == TxKind.transfer) {
    return 'Transaksi ini tidak bisa diubah jadi Pindah saldo. Hapus lalu catat ulang bila perlu.';
  }
  return null;
}
