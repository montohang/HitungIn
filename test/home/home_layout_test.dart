import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/home/data/home_layout.dart';

void main() {
  test('bawaan = urutan Beranda sekarang, semua tampil kecuali Kekayaan bersih (bawaan mati)', () {
    expect(HomeLayout.standard.visible, [for (final c in HomeCard.values) if (c != HomeCard.kekayaan) c]);
    expect(HomeLayout.standard.isStandard, isTrue);
  });

  test('pindah & sembunyikan, lalu simpan-baca utuh', () {
    final l = HomeLayout.standard.move(HomeCard.terbaru.index, 0).toggle(HomeCard.budget, false);
    expect(l.visible,
        [HomeCard.terbaru, HomeCard.jatah, HomeCard.prakiraan, HomeCard.cepat, HomeCard.favorit, HomeCard.target, HomeCard.tagihan]);
    final back = HomeLayout.decode(l.encode());
    expect(back.order, l.order);
    expect(back.hidden, {HomeCard.budget, HomeCard.kekayaan});
    expect(back.isStandard, isFalse);
    expect(back.toggle(HomeCard.budget, true).hidden, {HomeCard.kekayaan});
  });

  test('nilai rusak → bawaan; kartu yang belum tersimpan ditambahkan, nama asing diabaikan', () {
    expect(HomeLayout.decode('{rusak').isStandard, isTrue);
    final l = HomeLayout.decode('{"order":["terbaru","neon","jatah"],"hidden":["neon","cepat"]}');
    expect(l.order.first, HomeCard.terbaru);
    expect(l.order.toSet(), HomeCard.values.toSet());
    expect(l.order, hasLength(HomeCard.values.length));
    expect(l.hidden, {HomeCard.cepat, HomeCard.kekayaan}, reason: 'kartu baru yang bawaannya mati tetap mati');
    final shown = HomeLayout.decode(HomeLayout.standard.toggle(HomeCard.kekayaan, true).encode());
    expect(shown.hidden, isEmpty, reason: 'pilihan pengguna menyalakan tetap tersimpan');
  });
}
