import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';

/// Satu item menu: harga & posisi peserta yang ikut menanggungnya.
typedef MenuLine = ({String name, int price, Set<int> who});

/// Bagikan [amount] menurut [weights] dengan sisa terbesar: hasilnya bulat
/// dan jumlahnya tepat [amount]. Bobot 0 → 0.
List<int> allocate(int amount, List<double> weights) {
  final double sum = weights.fold(0, (a, w) => a + w);
  if (sum <= 0) return List<int>.filled(weights.length, 0);
  final List<double> exact = [for (final w in weights) amount * w / sum];
  final List<int> out = [for (final e in exact) e.floor()];
  int left = amount - out.fold(0, (a, v) => a + v);
  final List<int> order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final int c = (exact[b] - out[b]).compareTo(exact[a] - out[a]);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final int i in order) {
    if (left <= 0) break;
    if (weights[i] <= 0) continue;
    out[i]++;
    left--;
  }
  return out;
}

/// Bagi rata [total] ke [n] orang; sisa pembulatan rupiah ditanggung [payer].
List<int> splitEven(int total, int n, {required int payer}) {
  if (n <= 0) return const [];
  final int base = total ~/ n;
  return [for (int i = 0; i < n; i++) base + (i == payer ? total - base * n : 0)];
}

/// Rincian tagihan per menu. Pajak & service dalam permil (100 = 10%).
typedef MenuBill = ({int subtotal, int tax, int service, int extraFee, int discount, int total});

MenuBill menuBill(List<MenuLine> lines, {int taxPermille = 0, int servicePermille = 0, int extraFee = 0, int discount = 0}) {
  final int sub = lines.fold(0, (a, l) => a + l.price);
  final int tax = (sub * taxPermille / 1000).round();
  final int service = (sub * servicePermille / 1000).round();
  return (
    subtotal: sub,
    tax: tax,
    service: service,
    extraFee: extraFee,
    discount: discount,
    total: sub + tax + service + extraFee - discount,
  );
}

/// Bagian tiap peserta per menu: harga item dibagi rata di antara yang ikut,
/// lalu pajak/service/ongkir/diskon proporsional terhadap subtotal tiap orang.
List<int> splitMenu(List<MenuLine> lines, int n, MenuBill bill) {
  final List<double> base = List<double>.filled(n, 0);
  for (final MenuLine l in lines) {
    final List<int> who = [for (final i in l.who) if (i >= 0 && i < n) i];
    for (final int i in who) {
      base[i] += l.price / who.length;
    }
  }
  return allocate(bill.total < 0 ? 0 : bill.total, base);
}

/// Masalah isian patungan, atau null bila siap disimpan.
String? splitProblem({
  required int total,
  required List<String> names,
  required List<int> shares,
  List<MenuLine>? lines,
}) {
  if (names.length < 2) return 'Tambahkan minimal satu teman.';
  final Set<String> seen = {};
  for (final String n in names) {
    final String k = n.trim().toLowerCase();
    if (k.isEmpty) return 'Nama peserta belum diisi.';
    if (!seen.add(k)) return 'Nama "$n" dobel.';
  }
  if (total <= 0) return 'Isi total tagihannya.';
  if (lines != null) {
    if (lines.isEmpty) return 'Tambahkan item menunya.';
    final MenuLine? orphan = lines.where((l) => l.who.isEmpty).firstOrNull;
    if (orphan != null) return '"${orphan.name}" belum dipilih siapa yang ikut.';
  }
  final int sum = shares.fold(0, (a, v) => a + v);
  if (sum != total) {
    final int left = total - sum;
    return left > 0 ? 'Sisa ${Rupiah.format(left)} belum terbagi.' : 'Kelebihan ${Rupiah.format(-left)} dari total.';
  }
  return null;
}

/// Peserta untuk ringkasan.
typedef ShareLine = ({String name, int share, bool isMe, bool payer, bool paid, List<String> items});

/// Teks WhatsApp ringkasan patungan.
String splitShareText({
  required String title,
  required DateTime date,
  required int total,
  required String modeNote,
  required List<ShareLine> people,
  String? transfer,
}) {
  final ShareLine? payer = people.where((p) => p.payer).firstOrNull;
  final StringBuffer b = StringBuffer()
    ..writeln('Patungan $title (${DateFmt.longDate(date, now: date)})')
    ..writeln('Total ${Rupiah.format(total)} · $modeNote');
  for (final ShareLine p in people) {
    if (p.payer) continue;
    b.write('• ${p.isMe ? 'Aku' : p.name} ${Rupiah.format(p.share)}');
    if (p.items.isNotEmpty) b.write(' (${p.items.join(', ')})');
    if (p.paid) b.write(' ✓');
    b.writeln();
  }
  if (payer != null) b.writeln('Dibayar dulu oleh ${payer.isMe ? 'aku' : payer.name}.');
  if (transfer != null && transfer.trim().isNotEmpty) b.writeln('Transfer ke ${transfer.trim()} 🙏');
  return b.toString().trimRight();
}
