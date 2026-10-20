import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/home/data/home_layout.dart';

void main() {
  test('bawaan = urutan Beranda sekarang, semua tampil', () {
    expect(HomeLayout.standard.visible, HomeCard.values);
    expect(HomeLayout.standard.isStandard, isTrue);
  });

  test('pindah & sembunyikan, lalu simpan-baca utuh', () {
    final l = HomeLayout.standard.move(HomeCard.terbaru.index, 0).toggle(HomeCard.budget, false);
    expect(l.visible,
        [HomeCard.terbaru, HomeCard.jatah, HomeCard.cepat, HomeCard.favorit, HomeCard.target, HomeCard.tagihan]);
    final back = HomeLayout.decode(l.encode());
    expect(back.order, l.order);
    expect(back.hidden, {HomeCard.budget});
    expect(back.isStandard, isFalse);
    expect(back.toggle(HomeCard.budget, true).hidden, isEmpty);
  });

  test('nilai rusak → bawaan; kartu yang belum tersimpan ditambahkan, nama asing diabaikan', () {
    expect(HomeLayout.decode('{rusak').isStandard, isTrue);
    final l = HomeLayout.decode('{"order":["terbaru","neon","jatah"],"hidden":["neon","cepat"]}');
    expect(l.order.first, HomeCard.terbaru);
    expect(l.order.toSet(), HomeCard.values.toSet());
    expect(l.order, hasLength(HomeCard.values.length));
    expect(l.hidden, {HomeCard.cepat});
  });
}
