import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/transactions/widgets/amount_keypad.dart';

int _type(String keys, [int start = 0]) {
  int v = start;
  for (final String k in keys.split(' ')) {
    v = applyKeypad(v, k);
  }
  return v;
}

void main() {
  test('angka ditambahkan di belakang; 000 menambah tiga nol', () {
    expect(_type('2 5 000'), 25000);
    expect(_type('9 2 000 0 0'), 9200000);
  });

  test('nol di depan diabaikan', () {
    expect(_type('0 0 000 5'), 5);
  });

  test('hapus satu digit; dari satu digit jadi nol', () {
    expect(_type('⌫', 25000), 2500);
    expect(_type('⌫ ⌫', 7), 0);
  });

  test('maksimal 11 digit', () {
    expect(_type('000', 99999999999), 99999999999);
    expect(_type('1', 9999999999), 99999999991);
  });
}
