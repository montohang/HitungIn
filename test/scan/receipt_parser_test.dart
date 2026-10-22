import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/features/scan/data/receipt_parser.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 21, 15);

  test('angka rupiah: titik, koma, Rp, desimal ,00, tanpa pemisah', () {
    expect(parseAmount('25.000'), 25000);
    expect(parseAmount('25,000'), 25000);
    expect(parseAmount('Rp 25.000'), 25000);
    expect(parseAmount('Rp.411.700'), 411700);
    expect(parseAmount('25.000,00'), 25000);
    expect(parseAmount('1.250.000'), 1250000);
    expect(parseAmount('7000'), 7000);
    expect(parseAmount('12.5'), isNull);
  });

  test('tanggal: dd.mm.yy (tahun 2 digit perlu dicek), dd/mm/yyyy + jam, dd MMM yyyy, yyyy-mm-dd', () {
    expect(parseReceiptDate('18.10.26-19:42  2KM1-08'), (date: DateTime(2026, 10, 18, 19, 42), twoDigitYear: true));
    expect(parseReceiptDate('21/10/2026 19:12  MEJA 14'), (date: DateTime(2026, 10, 21, 19, 12), twoDigitYear: false));
    expect(parseReceiptDate('Tgl: 5 Okt 2026 08.15'), (date: DateTime(2026, 10, 5, 8, 15), twoDigitYear: false));
    expect(parseReceiptDate('2026-09-30 21:05:11'), (date: DateTime(2026, 9, 30, 21, 5), twoDigitYear: false));
    expect(parseReceiptDate('TOTAL 87.400'), isNull);
  });

  test('baris OCR yang terpisah kiri-kanan digabung per baris struk', () {
    final List<OcrLine> lines = [
      (text: 'INDOMARET', left: 80, top: 10, right: 220, bottom: 30),
      (text: 'AQUA 600ML 2x3.500', left: 10, top: 100, right: 200, bottom: 118),
      (text: '7.000', left: 250, top: 102, right: 300, bottom: 120),
      (text: 'TOTAL BELANJA', left: 10, top: 140, right: 150, bottom: 158),
      (text: '87.400', left: 245, top: 139, right: 300, bottom: 157),
    ];
    expect(receiptRows(lines), ['INDOMARET', 'AQUA 600ML 2x3.500  7.000', 'TOTAL BELANJA  87.400']);
  });

  test('minimarket: total, toko, tanggal (cek lagi), GoPay, 7 item cocok', () {
    final ReceiptScan r = parseReceipt([
      'INDOMARET',
      'JL. KEMANG RAYA 12',
      'NPWP 01.337.994.6-092',
      '18.10.26-19:42  2KM1-08',
      '-----------------------------',
      'AQUA 600ML 2x3.500  7.000',
      'INDOMIE GRG 5x3.100  15.500',
      'ULTRA UHT 1L  19.900',
      'SARI ROTI TAWAR  14.500',
      'LIFEBUOY 85G  12.900',
      'TEH KOTAK 2x4.900  9.800',
      'TELUR 1/4 KG  7.800',
      '-----------------------------',
      'TOTAL BELANJA  87.400',
      'GOPAY  87.400',
      'TERIMA KASIH',
    ], now: now);
    expect((r.merchant, r.total, r.payment), ('Indomaret', 87400, 'GOPAY'));
    expect(r.date, DateTime(2026, 10, 18, 19, 42));
    expect(r.unsure, {'date'});
    expect(r.items.length, 7);
    expect((r.items.first.name, r.items.first.qty, r.items.first.price), ('Aqua 600ml', 2, 7000));
    expect((r.items[1].name, r.items[1].qty), ('Indomie Grg', 5));
    expect(r.itemsMatchTotal, isTrue);
  });

  test('resto: item, PB1 10% & service 5% terbaca, total cocok, QRIS', () {
    final ReceiptScan r = parseReceipt([
      'SOLARIA',
      'PLAZA SEMANGGI LT.3',
      '21/10/2026 19:12  MEJA 14',
      '-----------------------------',
      'NASI GORENG SPESIAL  48.000',
      'AYAM BAKAR MADU  62.000',
      'KWETIAU GORENG  45.000',
      'GURAME ASAM MANIS  120.000',
      'ES TEH MANIS 4x12.000  48.000',
      'KENTANG GORENG  35.000',
      '-----------------------------',
      'SUBTOTAL  358.000',
      'PB1 10%  35.800',
      'SERVICE 5%  17.900',
      'TOTAL  411.700',
      'QRIS  411.700',
    ], now: now);
    expect((r.merchant, r.total, r.subtotal, r.tax, r.service, r.payment), ('Solaria', 411700, 358000, 35800, 17900, 'QRIS'));
    expect([for (final i in r.items) '${i.qty}×${i.name}=${i.price}'], [
      '1×Nasi Goreng Spesial=48000',
      '1×Ayam Bakar Madu=62000',
      '1×Kwetiau Goreng=45000',
      '1×Gurame Asam Manis=120000',
      '4×Es Teh Manis=48000',
      '1×Kentang Goreng=35000',
    ]);
    expect((r.taxPermille, r.servicePermille), (100, 50));
    expect(r.itemsMatchTotal, isTrue);
    expect(r.unsure, isEmpty);
  });

  test('kafe: Rp & ,00, qty di depan nama, harga di baris berikutnya, diskon, kembalian diabaikan', () {
    final ReceiptScan r = parseReceipt([
      'Kopi Kenangan',
      'Tel. 021-5550123',
      'Tgl: 5 Okt 2026 08.15',
      '2 Kopi Kenangan Mantan  Rp 44.000,00',
      'Croissant Butter',
      '1 x 22.000  Rp 22.000,00',
      'Diskon Member  -Rp 6.600,00',
      'Total  Rp 59.400,00',
      'Tunai  Rp 100.000,00',
      'Kembali  Rp 40.600,00',
    ], now: now);
    expect((r.merchant, r.total, r.discount), ('Kopi Kenangan', 59400, 6600));
    expect([for (final i in r.items) '${i.qty}×${i.name}=${i.price}'], ['2×Kopi Kenangan Mantan=44000', '1×Croissant Butter=22000']);
    expect(r.itemsMatchTotal, isTrue);
    expect(r.payment, 'TUNAI');
  });

  test('tanpa kata TOTAL → nominal pembayaran dipakai tapi ditandai kurang yakin; struk kosong', () {
    final ReceiptScan r = parseReceipt(['WARUNG BU SRI', 'NASI RAMES  18.000', 'ES JERUK  5.000', 'QRIS  23.000'], now: now);
    expect((r.total, r.unsure.contains('total')), (23000, true));
    expect(parseReceipt(const [], now: now).isEmpty, isTrue);
  });

  test('hasil OCR nyata: spasi di tengah tanggal & huruf O dibaca sebagai 0', () {
    expect(parseReceiptDate('18.10. 26-19:42 2KM1-08')?.date, DateTime(2026, 10, 18, 19, 42));
    expect(normalizeOcrRow('AQUA 60OML 2x3.500  7.0O0'), 'AQUA 600ML 2x3.500  7.000');
    final ReceiptScan r = parseReceipt([
      'INDOMARET',
      'JL. KEMANG RAYA 12',
      '18.10. 26-19:42 2KM1-08',
      'AQUA 60OML 2x3.500  7.000',
      'TOTAL BELANJA  7.000',
    ], now: now);
    expect((r.date, r.items.single.name), (DateTime(2026, 10, 18, 19, 42), 'Aqua 600ml'));
  });

  test('pola struk POS resto: logo jadi teks acak, nama item beberapa baris, "7x @44.000", "Subtota l", header kunci-nilai', () {
    final ReceiptScan r = parseReceipt([
      'xukk',
      '1seoaII X [',
      'Warung Contoh Sejahtera',
      'Jl. Fiktif No. 1, Kota Contoh',
      '081200000000',
      '25 Sep 2026  13:38',
      'Receipt Number  ABC123',
      'Served By  Kasir',
      '*Dine In*',
      'AYAM GORENG',
      '1 PORSI',
      '7x @44.000  308.000',
      'SAYUR ASEM',
      '3x @5.500  16.500',
      'Kerupuk Udang',
      'Besar',
      '3x 020.000  60.000',
      'NASI',
      '1 PORSI  5.500',
      'Subtota l  Rp 390.000',
      'Total  Ru 390.000',
      'Gopay  kp 390.000',
    ], now: now);
    expect(r.merchant, 'Warung Contoh Sejahtera');
    expect(r.date, DateTime(2026, 9, 25, 13, 38));
    expect([for (final i in r.items) '${i.qty}×${i.name}=${i.price}'], [
      '7×Ayam Goreng 1 Porsi=308000',
      '3×Sayur Asem=16500',
      '3×Kerupuk Udang Besar=60000',
      '1×Nasi Porsi=5500',
    ]);
    expect((r.subtotal, r.total, r.payment, r.itemsMatchTotal), (390000, 390000, 'GOPAY', true));
  });

  test('"1 x Nama" di depan: qty terbaca, nama tanpa "x"', () {
    final ReceiptScan r = parseReceipt(['Kedai Contoh', '1 x Es Kopi Susu  18.000', '2 x Roti Bakar  30.000', 'Total  48.000'], now: now);
    expect([for (final i in r.items) '${i.qty}×${i.name}'], ['1×Es Kopi Susu', '2×Roti Bakar']);
  });

  test('baris varian "- Original" yang mengulang harga tidak jadi item kedua; Cash terbaca', () {
    final ReceiptScan r = parseReceipt([
      'Kopi Contoh',
      'Tanggal: 26/09/2026, 14:03',
      'Take away',
      '1 x Es Kopi Aren  7.000',
      'Shot',
      '- 1x (Original)  7.000',
      'Subtotal  7.000',
      'Total  7.000',
      'Cash  7.000',
      'Change  0',
    ], now: now);
    expect([for (final i in r.items) '${i.qty}×${i.name}=${i.price}'], ['1×Es Kopi Aren=7000']);
    expect((r.total, r.payment, r.itemsMatchTotal), (7000, 'CASH', true));
  });
}
