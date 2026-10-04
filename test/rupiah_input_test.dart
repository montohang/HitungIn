import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/utils/rupiah_input.dart';

void main() {
  const f = RupiahInputFormatter();
  String type(String text) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text)).text;

  test('memberi titik ribuan saat mengetik', () {
    expect(type('2500000'), '2.500.000');
    expect(type('2.500.0001'), '25.000.001');
    expect(type('007'), '7');
    expect(type('abc'), '');
  });

  test('menolak lebih dari 13 digit', () {
    const old = TextEditingValue(text: '1.234.567.890.123');
    expect(f.formatEditUpdate(old, const TextEditingValue(text: '12345678901234')), old);
  });

  test('parse', () {
    expect(RupiahInputFormatter.parse('2.500.000'), 2500000);
    expect(RupiahInputFormatter.parse(''), 0);
  });
}
