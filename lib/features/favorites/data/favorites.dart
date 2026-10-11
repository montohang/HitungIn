import 'dart:convert';

import '../../../core/db/app_database.dart';

/// Satu transaksi favorit ("Sekali ketuk" di Beranda, P1-3).
class Favorite {
  const Favorite({
    required this.kind,
    required this.note,
    required this.categoryId,
    required this.sub,
    required this.walletId,
    required this.amount,
    this.pinned = false,
    this.count = 0,
    this.lastTxId,
    this.lastAt,
  });

  final TxKind kind;
  final String note;
  final int? categoryId;
  final String sub;
  final int walletId;
  final int amount;

  /// Dipasang manual lewat "Jadikan favorit".
  final bool pinned;

  /// Berapa kali dicatat dalam 60 hari terakhir.
  final int count;

  /// Transaksi terbaru dengan isi yang sama (untuk "Ubah dulu").
  final int? lastTxId;
  final DateTime? lastAt;

  /// Kunci pembeda: jenis + catatan (tanpa beda huruf besar/spasi) + kategori + dompet + nominal.
  String get key => favoriteKey(kind: kind, note: note, categoryId: categoryId, walletId: walletId, amount: amount);

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'note': note,
        'categoryId': categoryId,
        'sub': sub,
        'walletId': walletId,
        'amount': amount,
        'txId': lastTxId,
      };

  static Favorite? fromJson(Object? j) {
    if (j is! Map) return null;
    final TxKind? kind = TxKind.values.where((k) => k.name == j['kind']).firstOrNull;
    final Object? wallet = j['walletId'];
    final Object? amount = j['amount'];
    if (kind == null || kind == TxKind.transfer || wallet is! int || amount is! int || amount <= 0) return null;
    return Favorite(
      kind: kind,
      note: '${j['note'] ?? ''}',
      categoryId: j['categoryId'] is int ? j['categoryId']! as int : null,
      sub: '${j['sub'] ?? ''}',
      walletId: wallet,
      amount: amount,
      pinned: true,
      lastTxId: j['txId'] is int ? j['txId']! as int : null,
    );
  }
}

String _normNote(String note) => note.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String favoriteKey({required TxKind kind, required String note, required int? categoryId, required int walletId, required int amount}) =>
    '${kind.name}|${_normNote(note)}|${categoryId ?? ''}|$walletId|$amount';

String favoriteKeyOf(Txn t) =>
    favoriteKey(kind: t.kind, note: t.note, categoryId: t.categoryId, walletId: t.walletId, amount: t.amount);

/// Favorit dari transaksi yang sudah dicatat.
Favorite favoriteFromTx(Txn t, {bool pinned = false}) => Favorite(
      kind: t.kind,
      note: t.note.trim(),
      categoryId: t.categoryId,
      sub: t.sub,
      walletId: t.walletId,
      amount: t.amount,
      pinned: pinned,
      lastTxId: t.id,
      lastAt: t.occurredAt,
    );

List<Favorite> decodeFavorites(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final Object? list = jsonDecode(raw);
    if (list is! List) return const [];
    return [for (final j in list) Favorite.fromJson(j)].whereType<Favorite>().toList();
  } on FormatException {
    return const [];
  }
}

String encodeFavorites(List<Favorite> list) => jsonEncode([for (final f in list) f.toJson()]);

Set<String> decodeKeys(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final Object? list = jsonDecode(raw);
    return list is List ? {for (final k in list) '$k'} : const {};
  } on FormatException {
    return const {};
  }
}

String encodeKeys(Set<String> keys) => jsonEncode((keys.toList()..sort()));

/// Favorit yang ditampilkan: yang manual dulu (urutan dipasang), lalu yang
/// dipelajari — dicatat ≥ [minCount] kali dalam [txs] (60 hari terakhir),
/// urut paling sering lalu paling baru. Yang disembunyikan tidak muncul.
/// Pindah saldo tidak pernah jadi favorit.
List<Favorite> learnFavorites(
  List<Txn> txs, {
  List<Favorite> pinned = const [],
  Set<String> hidden = const {},
  int minCount = 3,
  int limit = 6,
}) {
  final Map<String, ({Txn latest, int count})> groups = {};
  for (final Txn t in txs) {
    if (t.kind == TxKind.transfer || t.amount <= 0) continue;
    final String k = favoriteKeyOf(t);
    final g = groups[k];
    if (g == null) {
      groups[k] = (latest: t, count: 1);
    } else {
      groups[k] = (latest: t.occurredAt.isAfter(g.latest.occurredAt) ? t : g.latest, count: g.count + 1);
    }
  }
  final List<Favorite> out = [];
  final Set<String> seen = {};
  for (final Favorite p in pinned) {
    if (seen.add(p.key)) {
      final g = groups[p.key];
      out.add(g == null ? p : favoriteFromTx(g.latest, pinned: true));
    }
  }
  final auto = [
    for (final e in groups.entries)
      if (e.value.count >= minCount && !hidden.contains(e.key) && !seen.contains(e.key)) e.value,
  ]..sort((a, b) {
      final int byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : b.latest.occurredAt.compareTo(a.latest.occurredAt);
    });
  for (final g in auto) {
    final Favorite f = favoriteFromTx(g.latest);
    out.add(Favorite(
      kind: f.kind,
      note: f.note,
      categoryId: f.categoryId,
      sub: f.sub,
      walletId: f.walletId,
      amount: f.amount,
      count: g.count,
      lastTxId: f.lastTxId,
      lastAt: f.lastAt,
    ));
  }
  return out.take(limit).toList();
}
