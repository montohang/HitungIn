/// Format nominal Rupiah gaya Indonesia, tanpa ketergantungan locale
/// sistem (supaya hasilnya sama di semua HP).
///
/// Nominal disimpan sebagai bilangan bulat Rupiah (tanpa sen).
abstract final class Rupiah {
  /// Minus tipografis (U+2212), bukan tanda hubung.
  static const String minus = '−';

  /// `8450000` → `Rp8.450.000`.
  /// Dengan [signed]: `+Rp9.200.000` / `−Rp25.000`.
  static String format(int amount, {bool signed = false}) {
    final String body = 'Rp${_group(amount.abs())}';
    if (!signed || amount == 0) return amount < 0 ? '$minus$body' : body;
    return amount > 0 ? '+$body' : '$minus$body';
  }

  /// Ringkas untuk ruang sempit: `164210` → `Rp164rb`,
  /// `3120000` → `Rp3,12 jt`, `1500000000` → `Rp1,5 M`.
  static String compact(int amount) {
    final int a = amount.abs();
    final String sign = amount < 0 ? minus : '';
    if (a >= 1000000000) return '${sign}Rp${_dec(a / 1000000000)} M';
    if (a >= 1000000) return '${sign}Rp${_dec(a / 1000000)} jt';
    if (a >= 1000) return '${sign}Rp${(a / 1000).round()}rb';
    return '${sign}Rp$a';
  }

  /// Angka saja dengan titik ribuan: `25000` → `25.000`.
  static String digits(int amount) => _group(amount.abs());

  static String _group(int n) {
    final String s = n.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// Maksimal 2 desimal, koma sebagai pemisah, tanpa nol di belakang.
  static String _dec(double v) {
    String s = v.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }
}
