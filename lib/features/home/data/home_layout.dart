import 'dart:convert';

/// Kartu Beranda yang bisa diurutkan/disembunyikan (P2b, Pro). Total saldo
/// selalu paling atas dan tidak termasuk di sini.
enum HomeCard {
  jatah('Jatah hari ini', 'Angka aman dibelanjakan hari ini'),
  cepat('Catat cepat', 'Kolom "kopi 25rb gopay"'),
  favorit('Sekali ketuk', 'Chip transaksi favorit'),
  budget('Budget', 'Progres budget bulan ini'),
  target('Target tabungan', 'Progres target teratas'),
  tagihan('Tagihan mendatang', 'Termasuk sisa cicilan'),
  terbaru('Transaksi terbaru', '5 catatan terakhir');

  const HomeCard(this.label, this.hint);
  final String label;
  final String hint;
}

class HomeLayout {
  const HomeLayout({this.order = HomeCard.values, this.hidden = const {}});

  final List<HomeCard> order;
  final Set<HomeCard> hidden;

  static const HomeLayout standard = HomeLayout();

  /// Kartu yang tampil, berurutan.
  List<HomeCard> get visible => [for (final c in order) if (!hidden.contains(c)) c];

  bool get isStandard => _same(order, HomeCard.values) && hidden.isEmpty;

  HomeLayout move(int from, int to) {
    final List<HomeCard> o = [...order];
    final HomeCard c = o.removeAt(from);
    o.insert(to.clamp(0, o.length), c);
    return HomeLayout(order: o, hidden: hidden);
  }

  HomeLayout toggle(HomeCard c, bool show) =>
      HomeLayout(order: order, hidden: show ? ({...hidden}..remove(c)) : {...hidden, c});

  String encode() => jsonEncode({
        'order': [for (final c in order) c.name],
        'hidden': [for (final c in hidden) c.name],
      });

  /// Nilai rusak / kartu baru di versi berikutnya: kartu yang hilang ditambah
  /// di urutan bawaannya, nama yang tidak dikenal diabaikan.
  static HomeLayout decode(String? raw) {
    if (raw == null || raw.isEmpty) return standard;
    try {
      final Object? j = jsonDecode(raw);
      if (j is! Map) return standard;
      HomeCard? byName(Object? n) => HomeCard.values.where((c) => c.name == n).firstOrNull;
      final List<HomeCard> order = [
        for (final n in (j['order'] as List? ?? const []))
          if (byName(n) case final HomeCard c) c,
      ];
      for (final c in HomeCard.values) {
        if (!order.contains(c)) order.insert(c.index.clamp(0, order.length), c);
      }
      return HomeLayout(
        order: order.toSet().toList(),
        hidden: {
          for (final n in (j['hidden'] as List? ?? const []))
            if (byName(n) case final HomeCard c) c,
        },
      );
    } on FormatException {
      return standard;
    }
  }

  static bool _same(List<HomeCard> a, List<HomeCard> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
