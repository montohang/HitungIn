import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/reports/widgets/donut_chart.dart';
import 'package:hitungin/features/transactions/data/transactions_dao.dart';

CategoryTotal _t(int id, int total) => (
      category: Category(id: id, name: 'K$id', kind: TxKind.pengeluaran, icon: 'x', keywords: '', color: 0, subs: '', sortOrder: 0, archived: false),
      total: total,
    );

void main() {
  test('kosong / nol diabaikan', () {
    expect(donutSlices(const []), isEmpty);
    expect(donutSlices([_t(1, 0)]), isEmpty);
  });

  test('≤5 kategori tampil semua, terbesar dulu, persen berjumlah 100', () {
    final s = donutSlices([_t(1, 100), _t(2, 300), _t(3, 200)]);
    expect([for (final x in s) x.name], ['K2', 'K3', 'K1']);
    expect([for (final x in s) x.pct], [50, 33, 17]);
  });

  test('>5 kategori: 4 terbesar + Lainnya', () {
    final s = donutSlices([for (int i = 1; i <= 7; i++) _t(i, i * 10)]);
    expect(s, hasLength(5));
    expect(s.last.name, 'Lainnya');
    expect(s.last.category, isNull);
    expect(s.last.total, 10 + 20 + 30);
    expect(s.fold(0, (a, x) => a + x.pct), 100);
  });
}
