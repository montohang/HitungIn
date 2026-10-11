import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../favorites/data/favorites.dart';
import '../favorites/favorites_provider.dart';
import '../favorites/widgets/favorite_chips.dart' show favoriteLabel;
import 'allowance_provider.dart';
import 'data/allowance.dart';
import 'widgets/allowance_card.dart' show allowanceAmount, allowanceLine;

/// Ringkasan kecil untuk widget layar utama (P1-2). Widget tidak membaca
/// database terenkripsi; hanya ringkasan ini yang disimpan di luar aplikasi.
/// Mode sembunyikan saldo → tidak ada nominal sama sekali.
Map<String, Object?> buildWidgetSnapshot({
  required DateTime now,
  required Allowance? allowance,
  required List<Favorite> favorites,
  required List<Category> categories,
  required bool hidden,
}) {
  final Allowance? a = allowance;
  final bool warn = a != null &&
      (a.state == AllowanceState.menipis || a.state == AllowanceState.lewat || a.state == AllowanceState.habis);
  return {
    'date': DateFmt.dayKey(now),
    'hidden': hidden,
    'jatah': a == null ? '—' : allowanceAmount(a, hidden: hidden),
    'line': a == null ? 'Buka HitungIn untuk melihat jatah' : allowanceLine(a, now, hidden: hidden),
    'progress': a == null || a.jatah == 0 || hidden ? 0 : (a.spentToday * 100 ~/ a.jatah).clamp(0, 100),
    'warn': warn && !hidden,
    'favs': [
      for (final f in favorites.take(3))
        {
          'label': favoriteLabel(f, categories),
          'amount': hidden ? '••' : Rupiah.compact(f.amount).replaceFirst('Rp', ''),
          'route': f.lastTxId != null ? '/catat?copy=${f.lastTxId}' : '/catat',
        },
    ],
  };
}

final widgetSnapshotProvider = Provider<Map<String, Object?>>((ref) {
  ref.watch(currentDayProvider);
  return buildWidgetSnapshot(
    now: ref.read(clockProvider)(),
    allowance: ref.watch(allowanceProvider),
    favorites: ref.watch(favoritesProvider),
    categories: ref.watch(activeCategoriesProvider).valueOrNull ?? const [],
    hidden: ref.watch(hideBalanceProvider).valueOrNull ?? false,
  );
});

/// Kirim ringkasan ke widget Android bila berubah.
abstract final class HomeWidgetSync {
  static const MethodChannel _channel = MethodChannel('com.capt.hitungin/widget');
  static String? _last;

  static Future<void> push(Map<String, Object?> snapshot) async {
    final String json = jsonEncode(snapshot);
    if (json == _last) return;
    _last = json;
    try {
      await _channel.invokeMethod<void>('update', {'json': json});
    } on MissingPluginException {
      // Tes / platform tanpa widget.
    } on PlatformException {
      _last = null;
    }
  }
}
