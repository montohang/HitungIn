import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/transactions/data/transactions_dao.dart';

void main() {
  test('nominal dengan satuan → tepat', () {
    expect(amountSearch('50rb'), (exact: 50000, digits: null));
    expect(amountSearch('1,5jt'), (exact: 1500000, digits: null));
    expect(amountSearch('Rp 25 ribu'), (exact: 25000, digits: null));
  });

  test('angka saja → potongan digit', () {
    expect(amountSearch('25.000'), (exact: null, digits: '25000'));
    expect(amountSearch('250'), (exact: null, digits: '250'));
  });

  test('bukan angka → null', () {
    expect(amountSearch('kopi'), isNull);
    expect(amountSearch('kopi 25rb'), isNull);
  });
}
