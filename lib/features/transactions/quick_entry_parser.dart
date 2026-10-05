import '../../core/db/app_database.dart';

/// Hasil Catat Cepat. Kolom yang tidak terbaca dibiarkan kosong supaya
/// layar Catat bisa menanyakannya ke pengguna.
class QuickEntry {
  const QuickEntry({
    required this.kind,
    required this.occurredAt,
    this.amount,
    this.note = '',
    this.walletId,
    this.toWalletId,
    this.categoryId,
    this.sub = '',
  });

  final TxKind kind;
  final int? amount;
  final String note;
  final int? walletId;

  /// Hanya untuk transfer.
  final int? toWalletId;
  final int? categoryId;

  /// Sub-kategori yang disebut ("kopi" → Makan & Minum › Kopi), kosong bila tidak ada.
  final String sub;
  final DateTime occurredAt;

  /// Cukup untuk langsung disimpan tanpa bertanya lagi.
  bool get isComplete =>
      amount != null &&
      walletId != null &&
      (kind == TxKind.transfer ? toWalletId != null && toWalletId != walletId : categoryId != null);

  @override
  String toString() =>
      'QuickEntry($kind, amount: $amount, note: "$note", wallet: $walletId, to: $toWalletId, category: $categoryId, at: $occurredAt)';
}

/// Membaca kalimat bebas gaya Indonesia menjadi transaksi:
///
/// - `kopi 25rb gopay` → pengeluaran Rp25.000, Makan & Minum, dompet GoPay
/// - `gaji 9,2jt bca` → pemasukan Rp9.200.000, Gaji, BCA
/// - `tf bca ke gopay 100rb` → transfer BCA → GoPay
/// - `bensin 50.000 kemarin` → tanggal kemarin
///
/// Murni Dart (tanpa database), jadi mudah dites. Dompet & kategori
/// diberikan dari luar.
class QuickEntryParser {
  QuickEntryParser({required List<Wallet> wallets, required List<Category> categories})
      : _wallets = wallets.where((w) => !w.archived).toList(),
        _categories = categories.where((c) => !c.archived && c.kind != TxKind.transfer).toList();

  final List<Wallet> _wallets;
  final List<Category> _categories;

  static const Set<String> _transferWords = {'tf', 'trf', 'transfer', 'pindah'};
  static const Set<String> _topUpWords = {'topup', 'top-up'};
  static const Set<String> _connectors = {'pakai', 'pake', 'pakek', 'via', 'dari', 'ke', 'dgn', 'dengan', 'lewat'};
  static const Set<String> _cashAliases = {'cash', 'tunai', 'dompet', 'kes'};
  static const Set<String> _yesterday = {'kemarin', 'kemaren', 'kmrn', 'kmrin', 'kmarin'};
  static const Map<String, int> _multipliers = {
    'k': 1000,
    'rb': 1000,
    'ribu': 1000,
    'jt': 1000000,
    'juta': 1000000,
    'm': 1000000000,
    'miliar': 1000000000,
    'milyar': 1000000000,
  };
  static final RegExp _amountRe = RegExp(
    r'^([+\-−])?(?:rp\.?)?(\d+(?:[.,]\d+)*)(k|rb|ribu|jt|juta|m|miliar|milyar)?$',
  );

  QuickEntry parse(String input, {DateTime? now}) {
    final DateTime at = now ?? DateTime.now();
    final List<String> raw = input.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final List<String> low = [for (final t in raw) t.toLowerCase()];
    final List<bool> used = List<bool>.filled(raw.length, false);

    // 1. Tanggal.
    int daysAgo = 0;
    for (int i = 0; i < low.length; i++) {
      if (_yesterday.contains(low[i])) {
        daysAgo = 1;
        used[i] = true;
      } else if (i + 2 < low.length &&
          int.tryParse(low[i]) != null &&
          (low[i + 1] == 'hari' || low[i + 1] == 'hr') &&
          (low[i + 2] == 'lalu' || low[i + 2] == 'lalu.')) {
        daysAgo = int.parse(low[i]);
        used[i] = used[i + 1] = used[i + 2] = true;
      }
    }

    // 2. Nominal.
    int? amount;
    String? sign;
    final List<_AmountHit> hits = [];
    for (int i = 0; i < low.length; i++) {
      if (used[i]) continue;
      final _AmountHit? hit = _readAmount(low, i);
      if (hit != null) hits.add(hit);
    }
    if (hits.isNotEmpty) {
      final _AmountHit pick = hits.firstWhere((h) => h.strong, orElse: () => hits.last);
      amount = pick.value;
      sign = pick.sign;
      for (int i = pick.start; i < pick.start + pick.length; i++) {
        used[i] = true;
      }
      if (pick.start > 0 && low[pick.start - 1] == 'rp') used[pick.start - 1] = true;
    }

    // 3. Dompet (pasangan kata dulu, mis. "bank jago").
    final List<(int index, Wallet wallet)> walletHits = [];
    for (int i = 0; i < low.length; i++) {
      if (used[i]) continue;
      if (i + 1 < low.length && !used[i + 1]) {
        final Wallet? w = _matchWallet(_norm(low[i]) + _norm(low[i + 1]), exactOnly: true);
        if (w != null) {
          walletHits.add((i, w));
          used[i] = used[i + 1] = true;
          continue;
        }
      }
      final Wallet? w = _matchWallet(_norm(low[i]));
      if (w != null) {
        walletHits.add((i, w));
        used[i] = true;
      }
    }

    // 4. Transfer? Kata "ke"/"dari" sebelum dompet menentukan arah.
    final bool hasTransferWord = low.any(_transferWords.contains);
    final bool isTopUp = low.any(_topUpWords.contains);
    String markerBefore(int index) => index > 0 ? low[index - 1] : '';
    final bool isTransfer = ((hasTransferWord || isTopUp) && walletHits.isNotEmpty) ||
        (walletHits.length >= 2 && walletHits.any((h) => markerBefore(h.$1) == 'ke'));
    int? walletId;
    int? toWalletId;
    if (isTransfer) {
      for (int i = 0; i < low.length; i++) {
        if (_transferWords.contains(low[i]) || _topUpWords.contains(low[i])) used[i] = true;
      }
      final List<Wallet> unmarked = [];
      for (final (int index, Wallet w) in walletHits) {
        switch (markerBefore(index)) {
          case 'ke':
            toWalletId ??= w.id;
          case 'dari':
            walletId ??= w.id;
          default:
            unmarked.add(w);
        }
      }
      // "topup gopay 100rb" → GoPay adalah tujuan; selain itu dompet
      // pertama tanpa penanda adalah sumber.
      for (final Wallet w in unmarked) {
        if (isTopUp && toWalletId == null) {
          toWalletId = w.id;
        } else if (walletId == null) {
          walletId = w.id;
        } else {
          toWalletId ??= w.id;
        }
      }
    } else if (walletHits.isNotEmpty) {
      walletId = walletHits.first.$2.id;
    }

    // Kata sambung tepat sebelum dompet ("pakai gopay", "ke bca") dibuang dari catatan.
    for (final (int index, _) in walletHits) {
      if (index > 0 && _connectors.contains(low[index - 1])) used[index - 1] = true;
    }

    // 5. Kategori & jenis.
    TxKind kind = TxKind.pengeluaran;
    int? categoryId;
    String sub = '';
    if (isTransfer) {
      kind = TxKind.transfer;
    } else {
      final TxKind? forced = switch (sign) {
        '+' => TxKind.pemasukan,
        '-' || '−' => TxKind.pengeluaran,
        _ => null,
      };
      final (Category? cat, String matchedSub) = _matchCategory([
        for (int i = 0; i < low.length; i++)
          if (!used[i]) _norm(low[i]),
      ], forced);
      categoryId = cat?.id;
      sub = matchedSub;
      kind = forced ?? cat?.kind ?? TxKind.pengeluaran;
    }

    // 6. Catatan = sisa kata, huruf pertama kapital.
    final String note = [
      for (int i = 0; i < raw.length; i++)
        if (!used[i]) raw[i],
    ].join(' ');

    final DateTime day = DateTime(at.year, at.month, at.day - daysAgo, at.hour, at.minute);
    return QuickEntry(
      kind: kind,
      amount: amount,
      note: note.isEmpty ? note : note[0].toUpperCase() + note.substring(1),
      walletId: walletId,
      toWalletId: toWalletId,
      categoryId: categoryId,
      sub: sub,
      occurredAt: daysAgo == 0 ? at : day,
    );
  }

  /// Membaca nominal di token [i]; satuan boleh di token berikutnya ("25 rb").
  _AmountHit? _readAmount(List<String> low, int i) {
    final RegExpMatch? m = _amountRe.firstMatch(low[i]);
    if (m == null) return null;
    String? suffix = m.group(3);
    int length = 1;
    if (suffix == null && i + 1 < low.length && _multipliers.containsKey(low[i + 1])) {
      suffix = low[i + 1];
      length = 2;
    }
    final double? number = parseNumber(m.group(2)!, hasSuffix: suffix != null);
    if (number == null) return null;
    final int value = (number * (suffix == null ? 1 : _multipliers[suffix]!)).round();
    if (value <= 0 || value > 999999999999) return null;
    final bool strong = suffix != null || low[i].contains('rp') || m.group(2)!.contains(RegExp('[.,]')) || value >= 1000;
    return _AmountHit(start: i, length: length, value: value, strong: strong, sign: m.group(1));
  }

  /// Angka gaya Indonesia: titik = ribuan, koma = desimal. Titik/koma
  /// yang diikuti tepat 3 digit dianggap pemisah ribuan ("25.000",
  /// "25,000"), selain itu desimal ("1.5jt", "2,5jt").
  static double? parseNumber(String s, {bool hasSuffix = false}) {
    final bool hasDot = s.contains('.');
    final bool hasComma = s.contains(',');
    if (hasDot && hasComma) {
      return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
    }
    if (!hasDot && !hasComma) return double.tryParse(s);
    final String sep = hasDot ? '.' : ',';
    final List<String> parts = s.split(sep);
    final bool thousands = parts.length > 1 && parts.skip(1).every((p) => p.length == 3) && !(hasComma && hasSuffix);
    if (thousands) return double.tryParse(parts.join());
    if (parts.length != 2) return null;
    return double.tryParse('${parts[0]}.${parts[1]}');
  }

  Wallet? _matchWallet(String token, {bool exactOnly = false}) {
    if (token.length < 2) return null;
    final List<Wallet> exact = [for (final w in _wallets) if (_norm(w.name) == token) w];
    if (exact.length == 1) return exact.single;
    if (exactOnly) return null;
    if (_cashAliases.contains(token)) {
      final List<Wallet> cash = [for (final w in _wallets) if (w.type == WalletType.tunai) w];
      if (cash.isNotEmpty) return cash.first;
    }
    if (token.length < 3) return null;
    final List<Wallet> partial = [
      for (final w in _wallets)
        if (w.name.toLowerCase().split(RegExp(r'\s+')).map(_norm).contains(token)) w,
    ];
    // "bank" cocok ke banyak dompet → ambigu, abaikan.
    return partial.length == 1 ? partial.single : null;
  }

  /// Kategori dengan skor tertinggi + sub-kategori yang disebut. Sub-kategori
  /// (semua katanya ada di kalimat) bernilai paling tinggi.
  (Category?, String) _matchCategory(List<String> tokens, TxKind? kind) {
    Category? best;
    String bestSub = '';
    int bestScore = 0;
    final Set<String> tokenSet = {...tokens}..remove('');
    for (final Category c in _categories) {
      if (kind != null && c.kind != kind) continue;
      final Set<String> words = {
        ...c.keywords.split(',').map((k) => _norm(k.trim())),
        ...c.name.toLowerCase().split(RegExp(r'[\s&/]+')).map(_norm).where((w) => w.length >= 4),
      }..remove('');
      int score = 0;
      for (final String t in tokens) {
        if (t.isEmpty) continue;
        if (words.contains(t)) {
          score += 2;
        } else if (words.any((w) => w.length >= 4 && t.startsWith(w))) {
          score += 1;
        }
      }
      String sub = '';
      for (final String name in c.subs.split(',')) {
        final List<String> words = [for (final w in name.toLowerCase().split(RegExp(r'\s+'))) if (_norm(w).isNotEmpty) _norm(w)];
        if (words.isNotEmpty && words.every(tokenSet.contains)) {
          score += 3;
          sub = name.trim();
          break;
        }
      }
      if (score > bestScore) {
        best = c;
        bestScore = score;
        bestSub = sub;
      }
    }
    return (best, bestSub);
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _AmountHit {
  const _AmountHit({required this.start, required this.length, required this.value, required this.strong, this.sign});

  final int start;
  final int length;
  final int value;

  /// Jelas sebuah nominal (ada satuan, "rp", pemisah, atau ≥ 1.000).
  final bool strong;
  final String? sign;
}
