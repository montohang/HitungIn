import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/default_data.dart';
import 'package:hitungin/features/transactions/quick_entry_parser.dart';

Wallet _w(int id, String name, WalletType type) => Wallet(
      id: id,
      name: name,
      type: type,
      initialBalance: 0,
      icon: 'wallet',
      sortOrder: id,
      archived: false,
      createdAt: DateTime(2026),
    );

void main() {
  final wallets = [
    _w(1, 'Tunai', WalletType.tunai),
    _w(2, 'GoPay', WalletType.ewallet),
    _w(3, 'BCA', WalletType.bank),
    _w(4, 'Bank Jago', WalletType.bank),
  ];
  final categories = [
    for (final (int i, (String name, TxKind kind, String icon, String keywords)) in defaultCategories.indexed)
      Category(id: i + 1, name: name, kind: kind, icon: icon, keywords: keywords, sortOrder: i, archived: false),
  ];
  int catId(String name, TxKind kind) => categories.firstWhere((c) => c.name == name && c.kind == kind).id;

  final parser = QuickEntryParser(wallets: wallets, categories: categories);
  final now = DateTime(2026, 10, 2, 8, 42);
  QuickEntry parse(String s) => parser.parse(s, now: now);

  test('contoh utama: kopi 25rb gopay', () {
    final e = parse('kopi 25rb gopay');
    expect(e.kind, TxKind.pengeluaran);
    expect(e.amount, 25000);
    expect(e.walletId, 2);
    expect(e.categoryId, catId('Makan & Minum', TxKind.pengeluaran));
    expect(e.note, 'Kopi');
    expect(e.occurredAt, now);
    expect(e.isComplete, isTrue);
  });

  group('nominal', () {
    final cases = {
      'kopi 25rb': 25000,
      'kopi 25k': 25000,
      'kopi 25 rb': 25000,
      'kopi 25 ribu': 25000,
      'kopi 25.000': 25000,
      'kopi 25,000': 25000,
      'kopi Rp25.000': 25000,
      'kopi rp 25000': 25000,
      'gaji 9,2jt': 9200000,
      'gaji 9.2jt': 9200000,
      'gaji 1,5 juta': 1500000,
      'motor 1.500.000': 1500000,
      'rumah 1,25m': 1250000000,
      'kopi 1.500rb': 1500000,
      'parkir 2000': 2000,
    };
    cases.forEach((input, expected) {
      test(input, () => expect(parse(input).amount, expected));
    });

    test('angka kecil kalah oleh nominal yang jelas', () {
      final e = parse('beli 2 kopi 25rb');
      expect(e.amount, 25000);
      expect(e.note, 'Beli 2 kopi');
    });

    test('tanpa angka → nominal kosong', () {
      final e = parse('kopi gopay');
      expect(e.amount, isNull);
      expect(e.isComplete, isFalse);
    });
  });

  group('jenis & kategori', () {
    test('kata kunci pemasukan', () {
      final e = parse('gaji oktober 9,2jt bca');
      expect(e.kind, TxKind.pemasukan);
      expect(e.categoryId, catId('Gaji', TxKind.pemasukan));
      expect(e.walletId, 3);
      expect(e.note, 'Gaji oktober');
    });

    test('tanda + memaksa pemasukan', () {
      final e = parse('+50rb dikasih ibu');
      expect(e.kind, TxKind.pemasukan);
      expect(e.amount, 50000);
      expect(e.categoryId, catId('Hadiah', TxKind.pemasukan));
    });

    test('awalan kata kunci tetap cocok (makanan → makan)', () {
      expect(parse('makanan kucing 40rb').categoryId, catId('Makan & Minum', TxKind.pengeluaran));
    });

    test('nama kategori langsung', () {
      expect(parse('transportasi 20rb').categoryId, catId('Transportasi', TxKind.pengeluaran));
    });

    test('tak dikenal → kategori kosong, tetap pengeluaran', () {
      final e = parse('xyz 10rb');
      expect(e.kind, TxKind.pengeluaran);
      expect(e.categoryId, isNull);
    });

    test('isi bensin bukan transfer', () {
      final e = parse('isi bensin 50rb');
      expect(e.kind, TxKind.pengeluaran);
      expect(e.categoryId, catId('Transportasi', TxKind.pengeluaran));
    });
  });

  group('dompet', () {
    test('cocok tanpa peduli huruf besar', () {
      expect(parse('kopi 25rb GOPAY').walletId, 2);
    });

    test('nama dua kata', () {
      final e = parse('kopi 25rb bank jago');
      expect(e.walletId, 4);
      expect(e.note, 'Kopi');
    });

    test('satu kata dari nama dompet', () {
      expect(parse('kopi 25rb jago').walletId, 4);
    });

    test('alias cash → dompet tunai', () {
      expect(parse('bakso 15rb cash').walletId, 1);
    });

    test('kata sambung sebelum dompet dibuang dari catatan', () {
      final e = parse('makan siang 30rb pakai gopay');
      expect(e.walletId, 2);
      expect(e.note, 'Makan siang');
    });
  });

  group('transfer', () {
    test('tf bca ke gopay', () {
      final e = parse('tf bca ke gopay 100rb');
      expect(e.kind, TxKind.transfer);
      expect(e.walletId, 3);
      expect(e.toWalletId, 2);
      expect(e.amount, 100000);
      expect(e.categoryId, isNull);
      expect(e.isComplete, isTrue);
    });

    test('tanpa kata transfer, cukup "ke" di antara dua dompet', () {
      final e = parse('100rb bca ke gopay');
      expect(e.kind, TxKind.transfer);
      expect((e.walletId, e.toWalletId), (3, 2));
    });

    test('topup gopay dari bca', () {
      final e = parse('topup gopay 100rb dari bca');
      expect(e.kind, TxKind.transfer);
      expect((e.walletId, e.toWalletId), (3, 2));
    });

    test('tujuan saja → belum lengkap', () {
      final e = parse('tf ke gopay 50rb');
      expect(e.kind, TxKind.transfer);
      expect(e.walletId, isNull);
      expect(e.toWalletId, 2);
      expect(e.isComplete, isFalse);
    });
  });

  group('tanggal', () {
    test('kemarin', () {
      final e = parse('bensin 50rb kemarin');
      expect(e.occurredAt, DateTime(2026, 10, 1, 8, 42));
      expect(e.note, 'Bensin');
    });

    test('N hari lalu', () {
      expect(parse('nonton 3 hari lalu 50rb').occurredAt, DateTime(2026, 9, 29, 8, 42));
    });
  });

  test('parseNumber', () {
    expect(QuickEntryParser.parseNumber('25.000'), 25000);
    expect(QuickEntryParser.parseNumber('1.234.567'), 1234567);
    expect(QuickEntryParser.parseNumber('1.234,5'), 1234.5);
    expect(QuickEntryParser.parseNumber('2,5', hasSuffix: true), 2.5);
    expect(QuickEntryParser.parseNumber('1.2.3'), isNull);
  });
}
