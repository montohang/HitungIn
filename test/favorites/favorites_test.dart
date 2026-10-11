import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/favorites/data/favorites.dart';
import 'package:hitungin/features/favorites/favorites_provider.dart';
import 'package:hitungin/features/settings/data/settings_dao.dart';

int _id = 0;
Txn _tx(String note, int amount, DateTime at, {int wallet = 1, int? cat = 3, TxKind kind = TxKind.pengeluaran}) => Txn(
      id: ++_id,
      kind: kind,
      amount: amount,
      walletId: wallet,
      toWalletId: kind == TxKind.transfer ? 2 : null,
      categoryId: kind == TxKind.transfer ? null : cat,
      sub: '',
      note: note,
      occurredAt: at,
      createdAt: at,
      updatedAt: at,
    );

List<Txn> _times(String note, int amount, int n, {int startDay = 1, int wallet = 1}) =>
    [for (int i = 0; i < n; i++) _tx(note, amount, DateTime(2026, 10, startDay + i, 8), wallet: wallet)];

void main() {
  test('dicatat ≥ 3 kali → favorit; kurang dari itu tidak', () {
    final f = learnFavorites([..._times('Kopi', 25000, 3), ..._times('Bensin', 50000, 2)]);
    expect(f.map((x) => x.note), ['Kopi']);
    expect(f.single.count, 3);
  });

  test('catatan beda huruf besar/spasi tetap satu kelompok; nominal/dompet beda = beda favorit', () {
    final f = learnFavorites([
      _tx('kopi', 25000, DateTime(2026, 10, 1)),
      _tx('Kopi ', 25000, DateTime(2026, 10, 2)),
      _tx('KOPI', 25000, DateTime(2026, 10, 3)),
      ..._times('Kopi', 30000, 3),
      ..._times('Kopi', 25000, 3, wallet: 2),
    ]);
    expect(f.length, 3);
  });

  test('urut paling sering lalu paling baru; batas 6', () {
    final f = learnFavorites([
      ..._times('A', 1000, 5),
      ..._times('B', 2000, 3, startDay: 10),
      ..._times('C', 3000, 3, startDay: 1),
      for (final n in ['D', 'E', 'F', 'G']) ..._times(n, 4000, 3),
    ]);
    expect(f.length, 6);
    expect(f.first.note, 'A');
    expect(f[1].note, 'B', reason: 'sama-sama 3 kali, B lebih baru');
  });

  test('disembunyikan tidak muncul; manual tampil paling depan walau baru sekali', () {
    final txs = [..._times('Kopi', 25000, 4), ..._times('Bensin', 50000, 3)];
    final hidden = {favoriteKeyOf(txs.first)};
    final pinned = [favoriteFromTx(_tx('Galon', 22000, DateTime(2026, 10, 5)), pinned: true)];
    final f = learnFavorites(txs, hidden: hidden, pinned: pinned);
    expect(f.map((x) => x.note), ['Galon', 'Bensin']);
    expect(f.first.pinned, isTrue);
  });

  test('Pindah saldo tidak pernah jadi favorit', () {
    final f = learnFavorites([for (int i = 0; i < 4; i++) _tx('Topup', 100000, DateTime(2026, 10, i + 1), kind: TxKind.transfer)]);
    expect(f, isEmpty);
  });

  test('simpan/baca favorit manual & kunci tersembunyi; data rusak diabaikan', () {
    final fav = favoriteFromTx(_tx('Galon', 22000, DateTime(2026, 10, 5)), pinned: true);
    final back = decodeFavorites(encodeFavorites([fav]));
    expect((back.single.key, back.single.pinned), (fav.key, true));
    expect(decodeFavorites('{rusak'), isEmpty);
    expect(decodeFavorites('[{"kind":"transfer","walletId":1,"amount":5}]'), isEmpty);
    expect(decodeKeys(encodeKeys({'b', 'a'})), {'a', 'b'});
  });

  test('Jadikan favorit / lepas / sembunyikan tersimpan di pengaturan', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final tx = _tx('Galon', 22000, DateTime(2026, 10, 5));
    await setPinned(db.settingsDao, tx, true);
    expect(decodeFavorites(await db.settingsDao.read(SettingKeys.favoritesPinned)).single.note, 'Galon');
    await setPinned(db.settingsDao, tx, false);
    expect(decodeFavorites(await db.settingsDao.read(SettingKeys.favoritesPinned)), isEmpty);
    await removeFavorite(db.settingsDao, favoriteFromTx(tx));
    expect(decodeKeys(await db.settingsDao.read(SettingKeys.favoritesHidden)), {favoriteKeyOf(tx)});
    await setPinned(db.settingsDao, tx, true);
    expect(decodeKeys(await db.settingsDao.read(SettingKeys.favoritesHidden)), isEmpty,
        reason: 'dipasang manual lagi → tidak tersembunyi');
    await db.close();
  });
}
