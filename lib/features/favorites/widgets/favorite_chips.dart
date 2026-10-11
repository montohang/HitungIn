import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/data_providers.dart';
import '../../../core/db/providers.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../security/app_gate.dart';
import '../../settings/widgets/settings_tile.dart' show showAppSheet;
import '../../transactions/widgets/balance_confirm.dart';
import '../data/favorites.dart';
import '../favorites_provider.dart';

/// Nama chip: catatan, atau nama kategori bila catatan kosong.
String favoriteLabel(Favorite f, List<Category> categories) {
  if (f.note.isNotEmpty) return f.note[0].toUpperCase() + f.note.substring(1);
  return categories.where((c) => c.id == f.categoryId).firstOrNull?.name ?? 'Transaksi';
}

/// Baris "Sekali ketuk" di Beranda (P1-3). Tidak tampil bila belum ada favorit.
class FavoriteChips extends ConsumerWidget {
  const FavoriteChips({super.key, required this.hidden});

  /// Mode sembunyikan saldo: nominal disamarkan.
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Favorite> favs = ref.watch(favoritesProvider);
    if (favs.isEmpty) return const SizedBox.shrink();
    final List<Category> cats = ref.watch(activeCategoriesProvider).valueOrNull ?? const [];
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.block),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sekali ketuk', style: t.caption.copyWith(color: c.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpace.x8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              key: const Key('favorit'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: favs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x8),
              itemBuilder: (context, i) {
                final Favorite f = favs[i];
                final Category? cat = cats.where((x) => x.id == f.categoryId).firstOrNull;
                final String label = favoriteLabel(f, cats);
                final int color = cat?.color ?? 0;
                return Pressable(
                  onTap: () => _save(context, ref, f, label),
                  onLongPress: () => _menu(context, ref, f, label),
                  semanticLabel: 'Catat $label ${Rupiah.format(f.amount)}',
                  child: Container(
                    padding: const EdgeInsets.only(left: 6, right: 14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: AppRadius.pillAll,
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppPalette.soft(context, color), shape: BoxShape.circle),
                          child: Icon(AppIcons.of(cat?.icon ?? 'other'), size: 16, color: AppPalette.ink(context, color)),
                        ),
                        const SizedBox(width: AppSpace.x8),
                        Text(label, style: t.caption.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text(hidden ? '••' : Rupiah.compact(f.amount).replaceFirst('Rp', ''),
                            style: t.caption.copyWith(color: c.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Ketuk: langsung tersimpan untuk hari ini, dengan Urungkan.
  static Future<void> _save(BuildContext context, WidgetRef ref, Favorite f, String label) async {
    final bool ok = await confirmWalletBalance(context, ref, kind: f.kind, walletId: f.walletId, amount: f.amount);
    if (!ok || !context.mounted) return;
    final dao = ref.read(appDatabaseProvider).transactionsDao;
    final int id = await dao.add(
      kind: f.kind,
      amount: f.amount,
      walletId: f.walletId,
      categoryId: f.categoryId,
      sub: f.sub,
      note: f.note,
      occurredAt: ref.read(clockProvider)(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$label ${Rupiah.format(f.amount)} dicatat'),
        action: SnackBarAction(label: 'Urungkan', onPressed: () => dao.remove(id)),
      ));
  }

  /// Tekan lama: ubah dulu, atau keluarkan dari favorit.
  static Future<void> _menu(BuildContext context, WidgetRef ref, Favorite f, String label) async {
    final String? choice = await showAppSheet<String>(
      context,
      title: '$label · ${Rupiah.format(f.amount)}',
      aboveNav: true,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(label: 'Ubah dulu', large: true, onPressed: () => Navigator.pop(context, 'ubah')),
          const SizedBox(height: AppSpace.x8),
          AppButton(
            label: f.pinned ? 'Hapus dari favorit' : 'Sembunyikan dari favorit',
            variant: AppButtonVariant.soft,
            onPressed: () => Navigator.pop(context, 'hapus'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'ubah') {
      final Txn? source = f.lastTxId == null ? null : await ref.read(appDatabaseProvider).transactionsDao.byId(f.lastTxId!);
      if (!context.mounted) return;
      context.push(source != null
          ? Uri(path: Routes.catat, queryParameters: {'copy': '${source.id}'}).toString()
          : Uri(path: Routes.catat, queryParameters: {'text': '${f.note} ${f.amount}'}).toString());
    } else if (choice == 'hapus') {
      await removeFavorite(ref.read(appDatabaseProvider).settingsDao, f);
    }
  }
}
