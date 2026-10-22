/// Pembaca struk Indonesia (P3e): dari baris teks hasil OCR (dengan posisi)
/// menjadi total, toko, tanggal, item, pajak/service/diskon, dan cara bayar.
/// Murni — tanpa ML Kit — supaya mudah dites.
library;

/// Satu baris teks OCR beserta kotaknya (piksel gambar).
typedef OcrLine = ({String text, double left, double top, double right, double bottom});

class ReceiptItem {
  const ReceiptItem({required this.name, required this.qty, required this.price});

  final String name;
  final int qty;

  /// Harga total baris (qty × satuan).
  final int price;

  @override
  String toString() => '$qty× $name $price';
}

class ReceiptScan {
  const ReceiptScan({
    this.merchant,
    this.total,
    this.date,
    this.payment,
    this.items = const [],
    this.subtotal,
    this.tax = 0,
    this.service = 0,
    this.discount = 0,
    this.extraFee = 0,
    this.unsure = const {},
    this.rows = const [],
  });

  final String? merchant;
  final int? total;
  final DateTime? date;

  /// Kata cara bayar yang terbaca (mis. "GOPAY", "QRIS", "BCA").
  final String? payment;
  final List<ReceiptItem> items;
  final int? subtotal;
  final int tax;
  final int service;
  final int discount;
  final int extraFee;

  /// Field yang kurang yakin: 'total', 'date', 'merchant', 'items'.
  final Set<String> unsure;

  /// Baris yang sudah disusun ulang (untuk ditampilkan / debug).
  final List<String> rows;

  bool get isEmpty => total == null && items.isEmpty && merchant == null;
  int get itemsSum => items.fold(0, (a, i) => a + i.price);
  int get base => subtotal ?? itemsSum;

  /// Item + pajak + service + biaya − diskon sama dengan total.
  bool get itemsMatchTotal =>
      items.isNotEmpty && total != null && itemsSum + tax + service + extraFee - discount == total;

  /// Pajak & service dalam permil (100 = 10%) terhadap subtotal.
  int get taxPermille => base <= 0 || tax <= 0 ? 0 : (tax * 1000 / base).round();
  int get servicePermille => base <= 0 || service <= 0 ? 0 : (service * 1000 / base).round();
}

// ---------------------------------------------------------------- baris

/// Susun ulang baris OCR menjadi baris struk: potongan teks yang sejajar
/// vertikal digabung kiri → kanan (ML Kit sering memisah nama & harga).
List<String> receiptRows(List<OcrLine> lines) {
  final List<OcrLine> sorted = [...lines.where((l) => l.text.trim().isNotEmpty)]
    ..sort((a, b) => a.top.compareTo(b.top));
  final List<List<OcrLine>> rows = [];
  for (final OcrLine l in sorted) {
    final double mid = (l.top + l.bottom) / 2;
    final double h = (l.bottom - l.top).abs();
    List<OcrLine>? hit;
    for (final List<OcrLine> r in rows.reversed.take(3)) {
      final double rTop = r.map((x) => x.top).reduce((a, b) => a < b ? a : b);
      final double rBottom = r.map((x) => x.bottom).reduce((a, b) => a > b ? a : b);
      final double rMid = (rTop + rBottom) / 2;
      if ((mid - rMid).abs() <= h * 0.55 && !r.any((x) => _overlapX(x, l))) {
        hit = r;
        break;
      }
    }
    hit == null ? rows.add([l]) : hit.add(l);
  }
  return [
    for (final r in rows) (r..sort((a, b) => a.left.compareTo(b.left))).map((x) => x.text.trim()).join('  '),
  ];
}

bool _overlapX(OcrLine a, OcrLine b) => a.left < b.right - 4 && b.left < a.right - 4;

// ---------------------------------------------------------------- angka

final RegExp _amountToken = RegExp(r'(?<![\d.,])(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d{3,9})(?![\d.,]*\d)', caseSensitive: false);

/// "25.000" / "25,000" / "Rp 25.000" / "25.000,00" / "7000" → rupiah.
int? parseAmount(String s) {
  String t = s.trim().replaceAll(RegExp(r'^(rp\.?\s*)', caseSensitive: false), '').replaceAll(' ', '');
  t = t.replaceAll(RegExp(r'^[-−]'), '');
  final RegExpMatch? m = RegExp(r'^(\d{1,3}(?:[.,]\d{3})+)([.,]\d{2})?$').firstMatch(t);
  if (m != null) return int.parse(m.group(1)!.replaceAll(RegExp(r'[.,]'), ''));
  if (RegExp(r'^\d{1,9}$').hasMatch(t)) return int.parse(t);
  return null;
}

/// Nominal paling kanan di baris (harga), atau null.
int? _lastAmount(String row) {
  final List<RegExpMatch> ms = _amountToken.allMatches(row).toList();
  for (final RegExpMatch m in ms.reversed) {
    final int? v = parseAmount(m.group(0)!);
    if (v != null && v >= 100) return v;
  }
  return null;
}

// ---------------------------------------------------------------- kata kunci

bool _has(String up, List<String> words) => words.any((w) => RegExp('(^|[^A-Z])${RegExp.escape(w)}([^A-Z]|\$)').hasMatch(up));

const List<String> _subtotalWords = ['SUBTOTAL', 'SUB TOTAL', 'SUB-TOTAL'];
const List<String> _totalWords = ['GRAND TOTAL', 'TOTAL BAYAR', 'TOTAL BELANJA', 'TOTAL', 'JUMLAH', 'TAGIHAN', 'AMOUNT DUE'];
const List<String> _notTotal = ['TOTAL ITEM', 'TOTAL QTY', 'TOTAL DISKON', 'TOTAL HEMAT', 'TOTAL DISC', 'JUMLAH ITEM', 'TOTAL PPN'];
const List<String> _taxWords = ['PB1', 'PB 1', 'PBJT', 'PPN', 'PAJAK', 'TAX', 'PJK'];
const List<String> _serviceWords = ['SERVICE', 'SERVIS', 'SVC', 'SC', 'SERVICE CHARGE'];
const List<String> _discountWords = ['DISKON', 'DISC', 'DISCOUNT', 'HEMAT', 'POTONGAN', 'PROMO', 'VOUCHER'];
const List<String> _feeWords = ['ONGKIR', 'DELIVERY', 'BIAYA KIRIM', 'BIAYA LAYANAN', 'PACKAGING', 'KEMASAN'];
const List<String> _changeWords = ['KEMBALI', 'KEMBALIAN', 'CHANGE', 'SISA'];
const List<String> _paymentWords = [
  'QRIS', 'GOPAY', 'OVO', 'DANA', 'SHOPEEPAY', 'SPAY', 'LINKAJA', 'DEBIT', 'KREDIT', 'CREDIT', 'BCA', 'BRI', 'MANDIRI', 'BNI',
  'FLAZZ', 'E-MONEY', 'EMONEY', 'TUNAI', 'CASH',
];
const List<String> _headerLabels = [
  'RECEIPT', 'ORDER', 'BILL', 'SERVED', 'COLLECTED', 'KASIR', 'CASHIER', 'TABLE', 'MEJA', 'DINE IN', 'TAKE AWAY',
  'TAKEAWAY', 'CUSTOMER', 'PELANGGAN', 'TRANSAKSI', 'STRUK', 'INVOICE',
];
const List<String> _headerNoise = ['JL', 'JL.', 'JALAN', 'TELP', 'TLP', 'TEL', 'NPWP', 'NO', 'NO.', 'KASIR', 'CASHIER', 'STRUK', 'MEJA', 'TABLE', 'ALAMAT', 'WA'];

bool _isSummary(String up) =>
    _has(up, _subtotalWords) ||
    up.replaceAll(' ', '').startsWith('SUBTOTA') ||
    (_has(up, _totalWords) && !_has(up, _notTotal)) ||
    _has(up, _taxWords) ||
    _has(up, _serviceWords) ||
    _has(up, _changeWords);

// ---------------------------------------------------------------- tanggal

const Map<String, int> _months = {
  'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MEI': 5, 'MAY': 5, 'JUN': 6, 'JUL': 7, 'AGU': 8, 'AGS': 8, 'AUG': 8,
  'SEP': 9, 'OKT': 10, 'OCT': 10, 'NOV': 11, 'DES': 12, 'DEC': 12,
};

/// Tanggal (& jam) di struk. `twoDigitYear` → perlu dicek pengguna.
({DateTime date, bool twoDigitYear})? parseReceiptDate(String row) {
  final String up = row.toUpperCase();
  int? d, m, y;
  bool two = false;
  RegExpMatch? x = RegExp(r'(?<!\d)(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})(?!\d)').firstMatch(up);
  if (x != null) {
    y = int.parse(x.group(1)!);
    m = int.parse(x.group(2)!);
    d = int.parse(x.group(3)!);
  } else if ((x = RegExp(r'(?<!\d)(\d{1,2})\s?[-/.]\s?(\d{1,2})\s?[-/.]\s?(\d{2,4})(?!\d)').firstMatch(up)) != null) {
    d = int.parse(x!.group(1)!);
    m = int.parse(x.group(2)!);
    final String ys = x.group(3)!;
    two = ys.length == 2;
    y = two ? 2000 + int.parse(ys) : int.parse(ys);
  } else if ((x = RegExp(r'(?<!\d)(\d{1,2})\s*([A-Z]{3})[A-Z]*\.?\s*(\d{2,4})(?!\d)').firstMatch(up)) != null) {
    final int? mm = _months[x!.group(2)!];
    if (mm == null) return null;
    d = int.parse(x.group(1)!);
    m = mm;
    final String ys = x.group(3)!;
    two = ys.length == 2;
    y = two ? 2000 + int.parse(ys) : int.parse(ys);
  }
  if (d == null || m == null || y == null || m < 1 || m > 12 || d < 1 || d > 31 || y < 2000 || y > 2100) return null;
  int hh = 0, mi = 0;
  final RegExpMatch? t = RegExp(r'(?<!\d)([01]?\d|2[0-3])[:.]([0-5]\d)(?::[0-5]\d)?(?!\d)').allMatches(up).where((t) {
    // Lewati bagian tanggal "18.10" yang terlihat seperti jam.
    return !(x!.start <= t.start && t.end <= x.end);
  }).firstOrNull;
  if (t != null) {
    hh = int.parse(t.group(1)!);
    mi = int.parse(t.group(2)!);
  }
  return (date: DateTime(y, m, d, hh, mi), twoDigitYear: two);
}

// ---------------------------------------------------------------- utama

final RegExp _qtyPattern = RegExp(r'(?<![\d.,])(\d{1,3})\s*(?:[xX×]\s*@?|@)\s*(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{3,7})', caseSensitive: false);
final RegExp _letters = RegExp(r'[A-Za-z]{2,}');
/// Baris berisi nominal saja, boleh diawali "Rp" yang salah baca ("kp", "Ru").
final RegExp _bareAmount = RegExp(r'^\s*(?:[A-Za-z]{1,2}\.?\s*)?\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?\s*$');

/// Nama item: buang pola "2 x 3.500", harga paling kanan, dan qty di depan.
/// Angka lain (mis. "600ML") dipertahankan.
String _cleanName(String s) {
  String t = s.replaceAll(_qtyPattern, ' ');
  final List<RegExpMatch> ms = _amountToken.allMatches(t).toList();
  if (ms.isNotEmpty && t.substring(ms.last.end).trim().isEmpty) t = t.substring(0, ms.last.start);
  t = t.replaceAll(RegExp(r'^\s*\d{1,3}\s*(?:[xX×]\s+)?(?=[A-Za-z])'), ''); // "2 NASI GORENG", "1 x ICE LATTE"
  t = t.replaceAll(RegExp(r'[*#|]+'), ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return _titleCase(t);
}

/// Masih ada huruf setelah qty & nominal dibuang (bukan sekadar "Rp").
bool _hasName(String row) => _letters.hasMatch(row.replaceAll(_qtyPattern, ' ').replaceAll(_amountToken, ' '));

String _titleCase(String s) {
  if (s.isEmpty) return s;
  final bool allCaps = s == s.toUpperCase();
  if (!allCaps) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Baris acak dari logo (mis. "imukk", "1seoaII X ["): diawali huruf kecil,
/// atau tidak punya satu pun kata huruf ≥ 4 / dua kata huruf ≥ 3.
bool _looksLikeLogoNoise(String row) {
  final String t = row.trim();
  if (t.isEmpty) return true;
  if (RegExp(r'^[a-z]').hasMatch(t)) return true;
  final List<String> words = [for (final w in t.split(RegExp(r'[\s,]+'))) if (RegExp(r"^[A-Za-z&.'-]+$").hasMatch(w)) w];
  final bool longWord = words.any((w) => w.replaceAll(RegExp(r'[^A-Za-z]'), '').length >= 4);
  final bool twoWords = words.where((w) => w.length >= 3).length >= 2;
  return !(longWord || twoWords);
}

int? _leadingQty(String row) {
  final RegExpMatch? m = RegExp(r'^\s*(\d{1,3})\s*(?:[xX×]\s+)?[A-Za-z]').firstMatch(row);
  if (m == null) return null;
  final int q = int.parse(m.group(1)!);
  return q >= 1 && q <= 99 ? q : null;
}

/// Perbaiki salah baca OCR yang umum: huruf O di antara angka → 0.
String normalizeOcrRow(String row) => row
    .replaceAllMapped(RegExp(r'(?<=\d)[Oo](?=[\d.,]|[A-Za-z]{1,2}\b|$)'), (_) => '0')
    .replaceAllMapped(RegExp(r'(?<=[\d.,])[Oo](?=\d)'), (_) => '0');

ReceiptScan parseReceipt(List<String> rawRows, {DateTime? now}) {
  final List<String> rows = [for (final r in rawRows) normalizeOcrRow(r)];
  final List<String> up = [for (final r in rows) r.toUpperCase()];
  final DateTime today = now ?? DateTime.now();

  // Toko: baris berhuruf pertama di bagian atas yang bukan alamat/telepon.
  String? merchant;
  for (int i = 0; i < rows.length && i < 6; i++) {
    final String u = up[i];
    if (!_letters.hasMatch(u) || _isSummary(u) || parseReceiptDate(u) != null) continue;
    if (_looksLikeLogoNoise(rows[i])) continue;
    final List<String> words = u.split(RegExp(r'[\s,]+'));
    if (words.any(_headerNoise.contains)) continue;
    if (RegExp(r'\d{5,}').hasMatch(u)) continue;
    merchant = _titleCase(rows[i].replaceAll(RegExp(r'[*#|=_-]{2,}'), ' ').trim());
    break;
  }

  // Tanggal.
  DateTime? date;
  bool dateUnsure = false;
  for (final String r in rows) {
    final p = parseReceiptDate(r);
    if (p != null) {
      date = p.date;
      dateUnsure = p.twoDigitYear || p.date.isAfter(today.add(const Duration(days: 1))) || today.difference(p.date).inDays > 366;
      break;
    }
  }

  // Ringkasan & item.
  int? subtotal;
  int tax = 0, service = 0, discount = 0, extraFee = 0;
  final List<int> totalCandidates = [];
  String? payment;
  int? paymentAmount;
  final List<ReceiptItem> items = [];
  int firstSummary = rows.length;
  for (int i = 0; i < rows.length; i++) {
    final String u = up[i];
    int? amt = _lastAmount(rows[i]);
    // Nominal di baris berikutnya ("TOTAL" lalu "87.400").
    if (amt == null && i + 1 < rows.length && !_letters.hasMatch(up[i + 1])) amt = _lastAmount(rows[i + 1]);
    // …atau di baris sebelumnya bila baris itu hanya nominal ("kp 565.000" lalu "Total").
    if (amt == null && i > 0 && _bareAmount.hasMatch(rows[i - 1])) amt = _lastAmount(rows[i - 1]);
    final bool isSub = _has(u, _subtotalWords) || u.replaceAll(' ', '').startsWith('SUBTOTA');
    final bool isTotal = !isSub && _has(u, _totalWords) && !_has(u, _notTotal);
    if (isSub || isTotal || _has(u, _taxWords) || _has(u, _serviceWords)) firstSummary = i < firstSummary ? i : firstSummary;
    if (amt == null) continue;
    if (isSub) {
      subtotal = amt;
    } else if (isTotal) {
      totalCandidates.add(amt);
    } else if (_has(u, _taxWords) && !_has(u, _notTotal)) {
      tax += amt;
    } else if (_has(u, _serviceWords)) {
      service += amt;
    } else if (_has(u, _discountWords)) {
      discount += amt;
      if (i < firstSummary) continue;
    } else if (_has(u, _feeWords)) {
      extraFee += amt;
    } else if (_has(u, _changeWords)) {
      // kembalian — abaikan
    } else if (_has(u, _paymentWords)) {
      payment ??= _paymentWords.firstWhere((w) => _has(u, [w]));
      paymentAmount ??= amt;
    }
  }
  // Cara bayar tanpa nominal (mis. "PEMBAYARAN: QRIS").
  if (payment == null) {
    for (final String u in up) {
      final String? w = _paymentWords.where((w) => _has(u, [w]) && w != 'CASH' && w != 'TUNAI').firstOrNull;
      if (w != null) {
        payment = w;
        break;
      }
    }
  }

  // Item: baris sebelum ringkasan pertama yang punya harga & huruf.
  // Baris nama tanpa harga sejak harga terakhir ("PANGGANG", "1 PORSI").
  final List<String> pending = [];
  bool lastQtyKnown = false;
  final int headerEnd = rows.indexWhere((r) => parseReceiptDate(r) != null);
  for (int i = headerEnd < 0 ? 0 : headerEnd + 1; i < firstSummary && i < rows.length; i++) {
    final String row = rows[i];
    final String u = up[i];
    if (RegExp(r'^[-=_*.\s]{3,}$').hasMatch(row) ||
        _has(u, _paymentWords) ||
        _has(u, _discountWords) ||
        _has(u, _headerLabels) ||
        RegExp(r'^\*.*\*$').hasMatch(row.trim()) ||
        row.contains(':')) {
      pending.clear();
      continue;
    }
    final int? price = _lastAmount(row);
    final RegExpMatch? q = _qtyPattern.firstMatch(row);
    final bool hasName = _hasName(row);
    // Baris "7x @44.000" / "@16.500" di bawah item: hanya harga satuan, jadi
    // qty = harga item terakhir ÷ harga satuan.
    final RegExpMatch? at = RegExp(r'@\s*(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{3,7})', caseSensitive: false).firstMatch(row);
    final int? unit = at == null ? null : parseAmount(at.group(1)!);
    if (!hasName && unit != null && unit > 0 && price == unit) {
      final ReceiptItem? last = items.isEmpty ? null : items.last;
      if (last != null && !lastQtyKnown && last.price % unit == 0 && last.price ~/ unit <= 99) {
        items[items.length - 1] = ReceiptItem(name: last.name, qty: last.price ~/ unit, price: last.price);
        lastQtyKnown = true;
      }
      pending.clear();
      continue;
    }
    if (price == null) {
      if (hasName && i > 0) pending.add(row);
      continue;
    }
    int qty = 1;
    if (q != null) {
      qty = int.parse(q.group(1)!);
      final int unit = parseAmount(q.group(2)!) ?? 0;
      if (unit > 0 && unit * qty != price && unit == price) qty = 1;
    } else {
      qty = _leadingQty(row) ?? 1;
    }
    // Nama di baris sebelumnya (maks. 2 baris terdekat); baris "1 PORSI 5.500"
    // melengkapi nama di atasnya.
    final List<String> near = pending.length > 2 ? pending.sublist(pending.length - 2) : pending;
    final String own = hasName ? _cleanName(row) : '';
    final bool descriptor = hasName && near.isNotEmpty && own.split(' ').length <= 2 && _leadingQty(row) != null;
    final String name = !hasName
        ? _cleanName(near.join(' '))
        : descriptor
            ? _cleanName('${near.last} ${row.replaceAll(RegExp(r'^\s*\d{1,3}\s+'), '')}')
            : near.isNotEmpty && own.split(' ').length == 1 && _leadingQty(row) == null
                // "Kerupuk Kulit Babi" / "Besar 60.000": sambungan nama di atasnya.
                ? _cleanName('${near.join(' ')} $own')
                : own;
    pending.clear();
    // Baris varian/topping ("- Original 7.000") yang mengulang harga item di atasnya.
    if (RegExp(r'^\s*[-+]').hasMatch(row) && items.isNotEmpty && items.last.price == price) continue;
    if (name.isEmpty || name.length < 2) continue;
    if (merchant != null && name.toLowerCase() == merchant.toLowerCase()) continue;
    items.add(ReceiptItem(name: name, qty: qty, price: price));
    lastQtyKnown = q != null || (_leadingQty(row) != null && !descriptor);
  }

  // Total: kandidat yang cocok dengan rincian, lalu yang terbesar; tanpa kata
  // TOTAL → nominal pembayaran.
  final int itemsSum = items.fold(0, (a, i) => a + i.price);
  final int expected = (subtotal ?? itemsSum) + tax + service + extraFee - discount;
  int? total;
  bool totalUnsure = false;
  if (totalCandidates.isNotEmpty) {
    total = totalCandidates.contains(expected) && expected > 0
        ? expected
        : totalCandidates.reduce((a, b) => a > b ? a : b);
  } else if (paymentAmount != null) {
    total = paymentAmount;
    totalUnsure = true;
  } else if (expected > 0) {
    total = expected;
    totalUnsure = true;
  }

  final Set<String> unsure = {
    if (total == null || totalUnsure) 'total',
    if (date == null || dateUnsure) 'date',
    if (merchant == null) 'merchant',
    if (items.isNotEmpty && total != null && itemsSum + tax + service + extraFee - discount != total && subtotal != itemsSum) 'items',
  };
  return ReceiptScan(
    merchant: merchant,
    total: total,
    date: date,
    payment: payment,
    items: items,
    subtotal: subtotal,
    tax: tax,
    service: service,
    discount: discount,
    extraFee: extraFee,
    unsure: unsure,
    rows: rows,
  );
}
