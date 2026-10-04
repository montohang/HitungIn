import 'package:flutter/services.dart';

import 'rupiah.dart';

/// Format isian nominal saat diketik: `2500000` → `2.500.000`.
/// Hanya angka; maksimal 13 digit (di bawah 10 triliun).
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  static const int maxDigits = 13;

  /// `2.500.000` → 2500000; kosong → 0.
  static int parse(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > maxDigits) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    final String text = Rupiah.digits(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
