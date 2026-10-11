import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../settings/data/settings_dao.dart';
import '../transactions/data/transactions_dao.dart' show TxDetail;
import 'data/favorites.dart';

final _pinnedProvider = StreamProvider<List<Favorite>>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.favoritesPinned).map(decodeFavorites),
);

final _hiddenProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.favoritesHidden).map(decodeKeys),
);

final _last60DaysProvider = StreamProvider<List<TxDetail>>((ref) {
  final DateTime day = ref.watch(currentDayProvider);
  return ref
      .watch(appDatabaseProvider)
      .transactionsDao
      .watchBetween(day.subtract(const Duration(days: 60)), day.add(const Duration(days: 1)));
});

/// Kunci favorit yang dipasang manual (untuk tombol di Detail transaksi).
final pinnedFavoriteKeysProvider = Provider<Set<String>>(
  (ref) => {for (final f in ref.watch(_pinnedProvider).valueOrNull ?? const <Favorite>[]) f.key},
);

/// Chip "Sekali ketuk" (maks. 6). Kosong selama data belum termuat.
final favoritesProvider = Provider<List<Favorite>>((ref) {
  final List<Favorite>? pinned = ref.watch(_pinnedProvider).valueOrNull;
  final Set<String>? hidden = ref.watch(_hiddenProvider).valueOrNull;
  final List<TxDetail>? recent = ref.watch(_last60DaysProvider).valueOrNull;
  final wallets = ref.watch(walletBalancesProvider).valueOrNull;
  if (pinned == null || hidden == null || recent == null || wallets == null) return const [];
  final Set<int> active = {for (final w in wallets) w.wallet.id};
  return learnFavorites(
    [for (final d in recent) d.tx],
    pinned: pinned,
    hidden: hidden,
  ).where((f) => active.contains(f.walletId)).toList();
});

/// "Jadikan favorit" / "Hapus dari favorit".
Future<void> setPinned(SettingsDao dao, Txn tx, bool pinned) async {
  final List<Favorite> list = decodeFavorites(await dao.read(SettingKeys.favoritesPinned));
  final String key = favoriteKeyOf(tx);
  final List<Favorite> next = [
    for (final f in list)
      if (f.key != key) f,
    if (pinned) favoriteFromTx(tx, pinned: true),
  ];
  await dao.write(SettingKeys.favoritesPinned, encodeFavorites(next));
  if (pinned) {
    final Set<String> hidden = {...decodeKeys(await dao.read(SettingKeys.favoritesHidden))};
    if (hidden.remove(key)) await dao.write(SettingKeys.favoritesHidden, encodeKeys(hidden));
  }
}

/// Tekan lama chip → sembunyikan (otomatis) atau lepas (manual).
Future<void> removeFavorite(SettingsDao dao, Favorite f) async {
  if (f.pinned) {
    final List<Favorite> list = decodeFavorites(await dao.read(SettingKeys.favoritesPinned));
    await dao.write(SettingKeys.favoritesPinned, encodeFavorites([for (final p in list) if (p.key != f.key) p]));
  } else {
    final Set<String> hidden = {...decodeKeys(await dao.read(SettingKeys.favoritesHidden)), f.key};
    await dao.write(SettingKeys.favoritesHidden, encodeKeys(hidden));
  }
}
