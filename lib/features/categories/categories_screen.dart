import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/color_swatches.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/bottom_note_scroll_view.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/segmented_control.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/categories_dao.dart';

final _categoriesByKindProvider = StreamProvider.autoDispose.family<List<Category>, TxKind>(
  (ref, kind) => ref.watch(appDatabaseProvider).categoriesDao.watchAll(kind),
);

/// Kelola kategori (Claude Design › Kategori): grid 2 kolom, ikon berwarna,
/// sub-kategori. Ketuk → ubah; tahan & geser → urutkan.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  TxKind _kind = TxKind.pengeluaran;

  void _move(List<Category> active, int draggedId, int targetId) {
    if (draggedId == targetId) return;
    final List<int> ids = [for (final cat in active) cat.id];
    final int from = ids.indexOf(draggedId);
    final int to = ids.indexOf(targetId);
    ids.removeAt(from);
    ids.insert(to, draggedId);
    ref.read(appDatabaseProvider).categoriesDao.reorder(ids);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<Category> all = ref.watch(_categoriesByKindProvider(_kind)).valueOrNull ?? const [];
    final List<Category> active = [
      for (final cat in all)
        if (!cat.archived) cat
    ];
    final List<Category> archived = [
      for (final cat in all)
        if (cat.archived) cat
    ];

    Widget grid(List<Category> items, {bool draggable = true}) => LayoutBuilder(
          builder: (context, box) {
            final double w = (box.maxWidth - AppSpace.x8) / 2;
            return Wrap(
              spacing: AppSpace.x8,
              runSpacing: AppSpace.x8,
              children: [
                for (final Category cat in items)
                  SizedBox(
                    width: w,
                    child: draggable
                        ? _DraggableTile(
                            category: cat,
                            width: w,
                            onTap: () => _open(cat),
                            onDrop: (dragged) => _move(active, dragged, cat.id),
                          )
                        : _CategoryTile(category: cat, onTap: () => _open(cat)),
                  ),
              ],
            );
          },
        );

    return Scaffold(
      body: SafeArea(
        child: BottomNoteScrollView(
          items: [
            ScreenHeader(
              title: 'Kategori',
              large: true,
              trailing: Pressable(
                onTap: () => _open(null),
                semanticLabel: 'Kategori baru',
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                  child: Text('+ Baru', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            AppSegmentedControl<TxKind>(
              options: const [TxKind.pengeluaran, TxKind.pemasukan],
              selected: _kind,
              labelOf: (k) => k.label,
              onChanged: (k) => setState(() => _kind = k),
            ),
            const SizedBox(height: AppSpace.x16),
            grid(active),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x16),
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.x4, bottom: AppSpace.x8),
                child: Text('Diarsipkan', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub)),
              ),
              Opacity(opacity: 0.6, child: grid(archived, draggable: false)),
            ],
          ],
          footer: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
            child: Text(
              'Ketuk kategori untuk mengganti nama, ikon, warna, sub-kategori, atau kata kunci Catat cepat. '
              'Tahan & geser untuk mengubah urutan.',
              textAlign: TextAlign.center,
              style: t.label.copyWith(fontWeight: FontWeight.w500, height: 1.5, color: c.muted),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(Category? existing) => showAppSheet<void>(
        context,
        title: existing == null ? 'Kategori ${_kind.label.toLowerCase()} baru' : 'Ubah kategori',
        builder: (_) => _CategoryForm(existing: existing, kind: existing?.kind ?? _kind),
      );
}

/// Petak kategori yang bisa ditahan lalu dijatuhkan di petak lain (urutkan).
class _DraggableTile extends StatelessWidget {
  const _DraggableTile({required this.category, required this.width, required this.onTap, required this.onDrop});

  final Category category;
  final double width;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != category.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => LongPressDraggable<int>(
        data: category.id,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: width, child: _CategoryTile(category: category, onTap: () {}, lifted: true)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _CategoryTile(category: category, onTap: onTap)),
        child: _CategoryTile(category: category, onTap: onTap, highlight: candidates.isNotEmpty),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap, this.highlight = false, this.lifted = false});

  final Category category;
  final VoidCallback onTap;
  final bool highlight;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<String> subs = subsOf(category);
    final String sub = subs.isNotEmpty ? '${subs.length} sub-kategori' : 'Tanpa sub-kategori';
    return Pressable.card(
      onTap: onTap,
      semanticLabel: category.name,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.x12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: highlight ? c.accent : c.line, width: highlight ? 2 : 1),
          boxShadow: lifted ? const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppPalette.soft(context, category.color), borderRadius: AppRadius.smAll),
              child: Icon(AppIcons.of(category.icon), size: 20, color: AppPalette.ink(context, category.color)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                  ),
                  const SizedBox(height: AppSpace.x2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final TextEditingController _newSub = TextEditingController();
  late String _icon = _cat?.icon ?? 'other';
  late int _color = _cat?.color ?? 0;
  late List<String> _subs = [...subsOf(_cat)];
  bool _addingSub = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _keywords.dispose();
    _newSub.dispose();
    super.dispose();
  }

  void _commitSub() {
    final List<String> merged = normalizeSubs([..._subs, _newSub.text].join(',')).split(',');
    setState(() {
      _subs = [
        for (final s in merged)
          if (s.isNotEmpty) s
      ];
      _newSub.clear();
      _addingSub = false;
    });
  }

  Future<void> _save() async {
    if (_newSub.text.trim().isNotEmpty) _commitSub();
    final String name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Isi nama kategori.');
    final dao = ref.read(appDatabaseProvider).categoriesDao;
    final bool taken =
        (await dao.allOfKind(widget.kind)).any((c) => c.id != _cat?.id && c.name.toLowerCase() == name.toLowerCase());
    if (taken) return setState(() => _error = 'Nama kategori sudah dipakai.');
    final String keywords = normalizeCategoryKeywords(_keywords.text);
    final String subs = normalizeSubs(_subs.join(','));
    if (_cat == null) {
      await dao.add(name: name, kind: widget.kind, icon: _icon, keywords: keywords, color: _color, subs: subs);
    } else {
      await dao.edit(_cat.copyWith(name: name, icon: _icon, keywords: keywords, color: _color, subs: subs));
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(top: AppSpace.x4),
              decoration: BoxDecoration(color: AppPalette.soft(context, _color), borderRadius: AppRadius.mdAll),
              child: Icon(AppIcons.of(_icon), size: 28, color: AppPalette.ink(context, _color)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: TextField(
                controller: _name,
                autofocus: _cat == null,
                maxLength: 40,
                style: t.item,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nama kategori', counterText: ''),
              ),
            ),
          ],
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
                      color: key == _icon ? AppPalette.of(context, _color) : c.chip,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(AppIcons.of(key), size: 22, color: key == _icon ? Colors.white : c.sub),
                  ),
                ),
              ),
          ],
        ),
        const FieldLabel('Warna'),
        ColorSwatches(selected: _color, onChanged: (i) => setState(() => _color = i)),
        const FieldLabel('Sub-kategori'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final String sub in _subs)
              Container(
                height: 32,
                padding: const EdgeInsets.only(left: AppSpace.x12, right: AppSpace.x4),
                decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.pillAll),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sub, style: t.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.sub2)),
                    Pressable(
                      onTap: () => setState(() => _subs.remove(sub)),
                      semanticLabel: 'Hapus sub-kategori $sub',
                      child: SizedBox.square(dimension: 28, child: Icon(HiIcons.close, size: 14, color: c.muted)),
                    ),
                  ],
                ),
              ),
            if (_addingSub)
              SizedBox(
                width: 150,
                height: 36,
                child: TextField(
                  key: const Key('sub-baru'),
                  controller: _newSub,
                  autofocus: true,
                  style: t.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commitSub(),
                  decoration: const InputDecoration(
                    hintText: 'Nama sub',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8),
                  ),
                ),
              )
            else
              Pressable(
                onTap: () => setState(() => _addingSub = true),
                semanticLabel: 'Tambah sub-kategori',
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(color: c.line2),
                  ),
                  child: Text('+ Tambah', style: t.label.copyWith(fontSize: 13, color: c.accentText)),
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
            helperText: 'Pisahkan dengan koma. Nama sub-kategori juga dikenali.',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        Row(
          children: [
            Expanded(
              child:
                  AppButton(label: 'Batal', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context)),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(child: AppButton(label: 'Simpan', onPressed: _save)),
          ],
        ),
        if (_cat != null) ...[
          const SizedBox(height: AppSpace.x8),
          AppButton(
            label: _cat.archived ? 'Aktifkan lagi' : 'Arsipkan',
            variant: AppButtonVariant.soft,
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
