import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/widgets/app_icons.dart';
import 'package:hitungin/core/widgets/emoji_picker.dart';
import 'package:hitungin/features/backup/data/backup_codec.dart';
import 'package:hitungin/features/backup/data/backup_service.dart';
import 'package:hitungin/features/transactions/quick_entry_parser.dart';

void main() {
  test('kunci emoji: simpan sebagai e:…, ikon lama tetap terbaca', () {
    expect(AppIcons.emojiKey('🐱'), 'e:🐱');
    expect(AppIcons.emojiOf('e:🐱'), '🐱');
    expect(AppIcons.emojiOf('food'), isNull);
    expect(AppIcons.emojiOf('e:'), isNull);
    expect(AppIcons.categoryKeys.length, 30);
    expect(AppIcons.emojiChoices.length, 40);
  });

  test('"Emoji lain": ambil emoji pertama, tolak huruf/angka', () {
    expect(firstEmoji('🐱🐶'), '🐱');
    expect(firstEmoji(' 👨‍👩‍👧 '), '👨‍👩‍👧', reason: 'emoji gabungan tetap satu');
    expect(firstEmoji('a'), isNull);
    expect(firstEmoji('7'), isNull);
    expect(firstEmoji(''), isNull);
  });

  test('backup → pulihkan: emoji kategori & dompet tetap sama', () async {
    final src = AppDatabase(NativeDatabase.memory());
    await src.categoriesDao.add(name: 'Kucing', kind: TxKind.pengeluaran, icon: 'e:🐱', keywords: 'whiskas');
    await src.walletsDao.add(name: 'Tabungan', type: WalletType.bank, icon: 'e:🏦');
    final bytes = await BackupCodec.encrypt(await BackupService(src).snapshot(), 'rahasia123', iterations: 1000);
    final dst = AppDatabase(NativeDatabase.memory());
    await BackupService(dst).restore(await BackupCodec.decrypt(bytes, 'rahasia123'));
    expect((await dst.categoriesDao.active()).firstWhere((c) => c.name == 'Kucing').icon, 'e:🐱');
    expect((await dst.walletsDao.active()).single.icon, 'e:🏦');
    await src.close();
    await dst.close();
  });

  test('Catat cepat mengenali kategori beremoji lewat nama & kata kunci', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.categoriesDao.add(name: 'Kucing', kind: TxKind.pengeluaran, icon: 'e:🐱', keywords: 'whiskas');
    final wallet = await db.walletsDao.add(name: 'Tunai', type: WalletType.tunai);
    final parser = QuickEntryParser(wallets: await db.walletsDao.active(), categories: await db.categoriesDao.active());
    final e = parser.parse('whiskas 50rb', now: DateTime(2026, 10, 19));
    final cat = (await db.categoriesDao.active()).firstWhere((c) => c.id == e.categoryId);
    expect((cat.name, e.amount), ('Kucing', 50000));
    expect(wallet, isPositive);
    await db.close();
  });
}
