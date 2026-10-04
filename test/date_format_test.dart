import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/utils/date_format.dart';
import 'package:hitungin/features/reports/widgets/daily_chart.dart';

void main() {
  final now = DateTime(2026, 10, 2, 9);

  test('nama bulan & tanggal', () {
    expect(DateFmt.month(DateTime(2026, 10)), 'Oktober 2026');
    expect(DateFmt.date(DateTime(2026, 9, 19), now: now), '19 Sep');
    expect(DateFmt.date(DateTime(2025, 12, 1), now: now), '1 Des 2025');
    expect(DateFmt.longDate(DateTime(2026, 10, 2), now: now), 'Jumat, 2 Oktober');
    expect(DateFmt.time(DateTime(2026, 1, 1, 8, 5)), '08.05');
  });

  test('hari relatif', () {
    expect(DateFmt.relativeDay(DateTime(2026, 10, 2, 23), now: now), 'Hari ini');
    expect(DateFmt.relativeDay(DateTime(2026, 10, 1), now: now), 'Kemarin');
    expect(DateFmt.relativeDay(DateTime(2026, 9, 28), now: now), 'Senin, 28 Sep');
  });

  test('kunci bulan untuk URL', () {
    expect(DateFmt.monthKey(DateTime(2026, 3, 9)), '2026-03');
    expect(DateFmt.parseMonthKey('2026-03'), DateTime(2026, 3));
    expect(DateFmt.parseMonthKey('2026-13'), isNull);
    expect(DateFmt.parseMonthKey(null), isNull);
  });

  test('batas atas sumbu dibulatkan', () {
    expect(niceCeil(0), 0);
    expect(niceCeil(87500), 100000);
    expect(niceCeil(120000), 200000);
    expect(niceCeil(230000), 250000);
    expect(niceCeil(410000), 500000);
    expect(niceCeil(1000000), 1000000);
  });
}
