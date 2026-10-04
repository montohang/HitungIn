import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/utils/rupiah.dart';

void main() {
  group('Rupiah.format', () {
    test('ribuan memakai titik', () {
      expect(Rupiah.format(0), 'Rp0');
      expect(Rupiah.format(500), 'Rp500');
      expect(Rupiah.format(25000), 'Rp25.000');
      expect(Rupiah.format(8450000), 'Rp8.450.000');
      expect(Rupiah.format(1234567890), 'Rp1.234.567.890');
    });

    test('nilai negatif memakai minus tipografis', () {
      expect(Rupiah.format(-25000), '−Rp25.000');
    });

    test('mode bertanda', () {
      expect(Rupiah.format(9200000, signed: true), '+Rp9.200.000');
      expect(Rupiah.format(-87500, signed: true), '−Rp87.500');
      expect(Rupiah.format(0, signed: true), 'Rp0');
    });
  });

  group('Rupiah.compact', () {
    test('ribuan jadi rb', () {
      expect(Rupiah.compact(164210), 'Rp164rb');
      expect(Rupiah.compact(250000), 'Rp250rb');
    });

    test('jutaan jadi jt dengan koma', () {
      expect(Rupiah.compact(3120000), 'Rp3,12 jt');
      expect(Rupiah.compact(9200000), 'Rp9,2 jt');
      expect(Rupiah.compact(1000000), 'Rp1 jt');
    });

    test('miliaran jadi M', () {
      expect(Rupiah.compact(1500000000), 'Rp1,5 M');
    });

    test('di bawah seribu tetap utuh dan negatif bertanda', () {
      expect(Rupiah.compact(750), 'Rp750');
      expect(Rupiah.compact(-3120000), '−Rp3,12 jt');
    });
  });

  test('digits', () {
    expect(Rupiah.digits(25000), '25.000');
  });
}
