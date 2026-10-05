import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/categories/data/categories_dao.dart';

void main() {
  test('normalizeSubs merapikan, kapital awal, tanpa duplikat', () {
    expect(normalizeSubs(' kopi ,Makan  siang,\nKOPI,, jajan '), 'Kopi,Makan siang,Jajan');
    expect(normalizeSubs(''), '');
  });
}
