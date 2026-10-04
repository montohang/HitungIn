import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/segmented_control.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/categories_dao.dart';

final _categoriesByKindProvider = StreamProvider.autoDispose.family<List<Category>, TxKind>(
  (ref, kind) => ref.watch(appDatabaseProvider).categoriesDao.watchAll(kind),
);

/// Kelola kategori: tambah, ubah nama/ikon/kata kunci, urutkan, arsipkan.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  TxKind _kind = TxKind.pengeluaran;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<Category> all = ref.watch(_categoriesByKindProvider(_kind)).valueOrNull ?? const [];
    final List<Category> active = [for (final cat in all) if (!cat.archived) cat];
    final List<Category> archived = [for (final cat in all) if (cat.archived) cat];

    return Scaffold(
      appBar: AppBar(title: Text('Kategori', style: t.screenTitle)),
      floatingActionButton: AppFab(label: 'Tambah kategori', onPressed: () => _open(null)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8, bottom: 96),
        children: [
          AppSegmentedControl<TxKind>(
            options: const [TxKind.pengeluaran, TxKind.pemasukan],
            selected: _kind,
            labelOf: (k) => k.label,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: AppSpace.x12),
          Text('Tahan lalu geser untuk mengubah urutan. Kata kunci dipakai Catat cepat.',
              style: t.caption.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.x8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (from, to) {
              final List<int> ids = [for (final cat in active) cat.id];
              final int id = ids.removeAt(from);
              ids.insert(to > from ? to - 1 : to, id);
              ref.read(appDatabaseProvider).categoriesDao.reorder(ids);
            },
            children: [
              for (final (int i, Category cat) in active.indexed)
                ReorderableDelayedDragStartListener(
                  key: ValueKey(cat.id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.x8),
                    child: _CategoryCard(category: cat, onTap: () => _open(cat)),
                  ),
                ),
            ],
          ),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: AppSpace.x16),
            Text('Diarsipkan', style: t.label.copyWith(color: c.muted)),
            const SizedBox(height: AppSpace.x8),
            for (final cat in archived)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x8),
                child: Opacity(opacity: 0.6, child: _CategoryCard(category: cat, onTap: () => _open(cat))),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(Category? existing) => showAppSheet<void>(
        context,
        title: existing == null ? 'Kategori ${_kind.label.toLowerCase()} baru' : 'Ubah kategori',
        builder: (_) => _CategoryForm(existing: existing, kind: existing?.kind ?? _kind),
      );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final String keywords = category.keywords.split(',').where((k) => k.trim().isNotEmpty).take(5).join(', ');
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconTile(icon: AppIcons.of(category.icon)),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: t.item),
                if (keywords.isNotEmpty)
                  Text(keywords, style: t.caption.copyWith(color: context.colors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.kind, this.existing});

  final TxKind kind;
  final Category? existing;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final Category? _cat = widget.existing;
  late final TextEditingController _name = TextEditingController(text: _cat?.name ?? '');
  late final TextEditingController _keywords = TextEditingController(text: _cat?.keywords.replaceAll(',', ', ') ?? '');
  late String _icon = _cat?.icon ?? 'other';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Isi nama kategori.');
    final dao = ref.read(appDatabaseProvider).categoriesDao;
    final bool taken = (await dao.allOfKind(widget.kind))
        .any((c) => c.id != _cat?.id && c.name.toLowerCase() == name.toLowerCase());
    if (taken) return setState(() => _error = 'Nama kategori sudah dipakai.');
    final String keywords = normalizeCategoryKeywords(_keywords.text);
    if (_cat == null) {
      await dao.add(name: name, kind: widget.kind, icon: _icon, keywords: keywords);
    } else {
      await dao.edit(_cat.copyWith(name: name, icon: _icon, keywords: keywords));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleArchive() async {
    final dao = ref.read(appDatabaseProvider).categoriesDao;
    if (!_cat!.archived && (await dao.active(kind: widget.kind)).length <= 1) {
      return setState(() => _error = 'Minimal harus ada satu kategori aktif.');
    }
    await dao.setArchived(_cat.id, !_cat.archived);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          autofocus: _cat == null,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama kategori', counterText: ''),
        ),
        const FieldLabel('Ikon'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final key in AppIcons.categoryKeys)
              Semantics(
                selected: key == _icon,
                child: Pressable(
                  onTap: () => setState(() => _icon = key),
                  semanticLabel: 'Ikon $key',
                  child: Container(
                    width: AppSpace.touch,
                    height: AppSpace.touch,
                    decoration: BoxDecoration(
                      color: key == _icon ? c.accent : c.chip,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(AppIcons.of(key), size: 22, color: key == _icon ? c.onAccent : c.sub),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        TextField(
          controller: _keywords,
          style: t.item,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Kata kunci Catat cepat',
            hintText: 'kopi, nasi, gofood',
            helperText: 'Pisahkan dengan koma.',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
        if (_cat != null) ...[
          const SizedBox(height: AppSpace.x8),
          AppButton(
            label: _cat.archived ? 'Aktifkan lagi' : 'Arsipkan',
            variant: AppButtonVariant.outline,
            onPressed: _toggleArchive,
          ),
          if (!_cat.archived)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.x8),
              child: Text(
                'Kategori yang diarsipkan tidak muncul di Catat, tapi riwayatnya tetap ada.',
                style: t.caption.copyWith(color: c.muted),
              ),
            ),
        ],
      ],
    );
  }
}
