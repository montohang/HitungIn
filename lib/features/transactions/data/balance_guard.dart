import '../../../core/db/app_database.dart';

/// Pengaruh satu transaksi pada saldo dompet [walletId].
int txEffectOn(int walletId, {required TxKind kind, required int amount, required int fromWallet, int? toWallet}) {
  int effect = 0;
  if (fromWallet == walletId) effect += kind == TxKind.pemasukan ? amount : -amount;
  if (kind == TxKind.transfer && toWallet == walletId) effect += amount;
  return effect;
}

/// Saldo dompet [walletId] setelah transaksi disimpan ([current] = saldo
/// sekarang, sudah termasuk [editing] bila sedang mengubah transaksi).
/// [warn] hanya bila transaksi ini membuat saldo yang tadinya ≥ 0 menjadi
/// minus — dompet yang memang sudah minus tidak ditanya berulang-ulang.
({int before, int after, bool warn}) negativeBalanceCheck({
  required int current,
  required int walletId,
  required TxKind kind,
  required int amount,
  int? toWalletId,
  Txn? editing,
}) {
  final int old = editing == null
      ? 0
      : txEffectOn(walletId,
          kind: editing.kind, amount: editing.amount, fromWallet: editing.walletId, toWallet: editing.toWalletId);
  final int before = current - old;
  final int effect = txEffectOn(walletId, kind: kind, amount: amount, fromWallet: walletId, toWallet: toWalletId);
  final int after = before + effect;
  return (before: before, after: after, warn: effect < 0 && after < 0 && before >= 0);
}
