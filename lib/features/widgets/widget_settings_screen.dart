import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../home/widget_sync.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/widget_photo.dart';
import 'data/widget_style.dart';
import 'widget_styles_provider.dart';

/// Widget terpasang di layar utama; dimuat ulang tiap layar ini dibuka.
final installedWidgetsProvider =
    FutureProvider.autoDispose<List<({int id, String kind})>>((ref) => HomeWidgetSync.installed());

/// Atur widget (P2b, Claude Design › Atur widget): gaya per widget terpasang.
class WidgetSettingsScreen extends ConsumerStatefulWidget {
  const WidgetSettingsScreen({super.key, this.initialId});

  /// Widget yang baru dipasang / dipilih "Atur ulang" di launcher.
  final int? initialId;

  @override
  ConsumerState<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen> with WidgetsBindingObserver {
  int? _selected;

  /// Perubahan yang belum disimpan, per id widget.
  final Map<int, WidgetStyle> _draft = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_cleanUp);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Foto draf yang tidak jadi disimpan dihapus (bukan foto yang sedang dipakai widget).
    final Map<int, WidgetStyle> saved = ref.read(widgetStylesProvider).valueOrNull ?? const {};
    for (final MapEntry<int, WidgetStyle> e in _draft.entries) {
      if (e.value.photoPath != null && e.value.photoPath != saved[e.key]?.photoPath) deleteWidgetPhoto(e.value.photoPath);
    }
    super.dispose();
  }

  /// Kembali dari launcher (mis. widget baru dipasang) → muat ulang daftar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(installedWidgetsProvider);
  }

  /// Gaya milik widget yang sudah dilepas dihapus, termasuk fotonya.
  Future<void> _cleanUp() async {
    final List<({int id, String kind})> installed = await ref.read(installedWidgetsProvider.future);
    final Map<int, WidgetStyle> styles = await ref.read(widgetStylesProvider.future);
    if (installed.isEmpty) return; // Tes / platform tanpa widget: jangan hapus apa pun.
    final Set<int> ids = {for (final w in installed) w.id};
    final Map<int, WidgetStyle> keep = {
      for (final e in styles.entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    if (keep.length == styles.length) return;
    for (final e in styles.entries) {
      if (!ids.contains(e.key)) await deleteWidgetPhoto(e.value.photoPath);
    }
    await ref.read(appDatabaseProvider).settingsDao.write('widget.styles', encodeWidgetStyles(keep));
  }

  WidgetStyle _styleOf(int id) =>
      _draft[id] ?? (ref.read(widgetStylesProvider).valueOrNull ?? const {})[id] ?? const WidgetStyle();

  void _edit(int id, WidgetStyle Function(WidgetStyle) f) => setState(() => _draft[id] = f(_styleOf(id)));

  Future<void> _pickPhoto(int id) async {
    final PlatformFile? file =
        await withAutoLockPaused(ref, () => FilePicker.pickFile(dialogTitle: 'Pilih foto widget', type: FileType.image));
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final Directory dir = Directory('${(await getApplicationSupportDirectory()).path}/widget_photos');
      final ({String path, double luma}) saved =
          await saveWidgetPhoto(await file.xFile.readAsBytes(), dir: dir, widgetId: id);
      final String? old = _draft[id]?.photoPath;
      final String? stored = (ref.read(widgetStylesProvider).valueOrNull ?? const {})[id]?.photoPath;
      // Foto draf sebelumnya (belum disimpan) tidak dipakai lagi.
      if (old != null && old != stored) await deleteWidgetPhoto(old);
      _edit(id, (s) => s.copyWith(bg: WidgetBg.foto, photoPath: saved.path, photoLuma: saved.luma, focusY: 0.5));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto tidak bisa dibuka. Coba foto lain.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(int id) async {
    final WidgetStyle? draft = _draft[id];
    if (draft == null) return;
    final Map<int, WidgetStyle> styles = ref.read(widgetStylesProvider).valueOrNull ?? const {};
    final String? oldPhoto = styles[id]?.photoPath;
    final WidgetStyle clean = draft.bg == WidgetBg.foto ? draft : draft.copyWith(clearPhoto: true);
    await saveWidgetStyle(ref.read(appDatabaseProvider).settingsDao, styles, id, clean);
    if (oldPhoto != null && oldPhoto != clean.photoPath) await deleteWidgetPhoto(oldPhoto);
    if (clean.photoPath == null && draft.photoPath != null) await deleteWidgetPhoto(draft.photoPath);
    setState(() => _draft.remove(id));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Widget diperbarui')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<({int id, String kind})>> async = ref.watch(installedWidgetsProvider);
    ref.watch(widgetStylesProvider);
    final List<({int id, String kind})> widgets = async.valueOrNull ?? const [];
    final int? id = widgets.any((w) => w.id == _selected) ? _selected : widgets.firstOrNull?.id;
    final ({int id, String kind})? current = widgets.where((w) => w.id == id).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, 0),
              child: ScreenHeader(title: 'Atur widget', large: true),
            ),
            Expanded(
              child: current == null
                  ? _Empty(loading: async.isLoading)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
                      children: [
                        _Tabs(widgets: widgets, selected: current.id, onPick: (i) => setState(() => _selected = i)),
                        const SizedBox(height: AppSpace.x12),
                        _Preview(kind: current.kind, style: _styleOf(current.id)),
                        const SizedBox(height: AppSpace.x16),
                        _Controls(
                          style: _styleOf(current.id),
                          busy: _busy,
                          onChanged: (f) => _edit(current.id, f),
                          onPickPhoto: () => _pickPhoto(current.id),
                        ),
                      ],
                    ),
            ),
            if (current != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x16),
                child: AppButton(
                  key: const Key('simpan-widget'),
                  label: 'Simpan widget',
                  large: true,
                  onPressed: _draft.containsKey(current.id) ? () => _save(current.id) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _kindLabel(String kind) => kind == 'catat' ? 'Catat 2×1' : 'Jatah 4×2';

class _Tabs extends StatelessWidget {
  const _Tabs({required this.widgets, required this.selected, required this.onPick});

  final List<({int id, String kind})> widgets;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> seen = {};
    final Map<String, int> total = {};
    for (final w in widgets) {
      total[w.kind] = (total[w.kind] ?? 0) + 1;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final w in widgets) ...[
            Builder(builder: (context) {
              final int n = seen[w.kind] = (seen[w.kind] ?? 0) + 1;
              final String label = (total[w.kind] ?? 0) > 1 ? '${_kindLabel(w.kind)} · $n' : _kindLabel(w.kind);
              return AppChip(label: label, selected: w.id == selected, onTap: () => onPick(w.id));
            }),
            const SizedBox(width: AppSpace.x8),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.loading});

  final bool loading;

  Future<void> _pin(BuildContext context, String kind) async {
    final bool ok = await HomeWidgetSync.requestPin(kind);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tekan lama layar utama › Widget › HitungIn untuk memasang widget.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpace.screenH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: HiIcons.grid,
            title: 'Belum ada widget HitungIn',
            body: 'Pasang widget di layar utama, lalu atur warna, gradien, atau fotonya di sini.',
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Pasang widget Jatah 4×2', onPressed: () => _pin(context, 'jatah')),
          const SizedBox(height: AppSpace.x8),
          AppButton(
              label: 'Pasang widget Catat 2×1', variant: AppButtonVariant.outline, onPressed: () => _pin(context, 'catat')),
        ],
      ),
    );
  }
}

/// Pratinjau widget di atas "wallpaper", memakai [resolveWidgetLook] yang sama
/// dengan widget Android.
class _Preview extends ConsumerWidget {
  const _Preview({required this.kind, required this.style});

  final String kind;
  final WidgetStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(widgetThemeProvider);
    final WidgetLook look = resolveWidgetLook(style, accent: theme.accent, dark: theme.dark, isPro: true);
    final double opacity = look.alpha / 255;
    final BorderRadius radius = BorderRadius.circular(look.radiusDp.toDouble());
    final TextStyle base = context.text.caption;
    final bool hide = look.hideAmounts;

    Widget bg() {
      if (look.photoPath != null) {
        return Stack(fit: StackFit.expand, children: [
          Image.file(File(look.photoPath!), fit: BoxFit.cover, alignment: Alignment(0, look.focusY * 2 - 1)),
          ColoredBox(color: look.scrim),
        ]);
      }
      return DecoratedBox(
        decoration: BoxDecoration(
          color: look.colors.length == 1 ? look.colors.first : null,
          gradient: look.colors.length > 1
              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: look.colors)
              : null,
        ),
      );
    }

    Widget button(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: look.button, borderRadius: BorderRadius.circular(size / 3)),
          child: Icon(HiIcons.plus, size: size * 0.45, color: look.buttonIcon),
        );

    final Widget content = kind == 'catat'
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(40),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catat', style: base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: look.ink)),
                    Text('Sedikit-sedikit jadi bukit',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: base.copyWith(fontSize: 11, height: 1.3, color: look.muted)),
                  ],
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jatah hari ini', style: base.copyWith(fontSize: 12, color: look.muted)),
                        Text(hide ? 'Rp ••••' : 'Rp85.200',
                            style: base.copyWith(fontSize: 26, fontWeight: FontWeight.w800, color: look.ink)),
                        Text(hide ? 'Angka disamarkan' : 'Sisa Rp57.200 · gajian 12 hari lagi',
                            style: base.copyWith(fontSize: 12, color: look.muted)),
                      ],
                    ),
                  ),
                  button(44),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: 0.33, minHeight: 6, color: look.bar, backgroundColor: look.track),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (int i, String f) in ['Kopi 25rb', 'Bensin 50rb', 'Ojol 18rb'].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: look.chip, borderRadius: BorderRadius.circular(12)),
                        child: Text(hide ? '${f.split(' ').first} ••' : f,
                            style: base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: look.ink)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );

    return Semantics(
      label: 'Pratinjau widget',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: const BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B2F7A), Color(0xFF1C1840), Color(0xFF0F0D1F)],
          ),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: opacity,
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              width: kind == 'catat' ? 210 : double.infinity,
              height: kind == 'catat' ? 80 : null,
              child: Stack(
                children: [
                  Positioned.fill(child: bg()),
                  Padding(
                    padding: EdgeInsets.all(kind == 'catat' ? 12 : 14),
                    child: Center(child: content),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.style, required this.busy, required this.onChanged, required this.onPickPhoto});

  final WidgetStyle style;
  final bool busy;
  final ValueChanged<WidgetStyle Function(WidgetStyle)> onChanged;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool isPro = ref.watch(isProProvider);
    final theme = ref.watch(widgetThemeProvider);

    Widget label(String text, [String? value]) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.x4, AppSpace.x16, AppSpace.x4, AppSpace.x8),
          child: Row(children: [
            Expanded(child: Text(text, style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub))),
            if (value != null) Text(value, style: t.caption.copyWith(color: c.sub)),
          ]),
        );

    void pickBg(WidgetBg bg) {
      if (bg == WidgetBg.foto && !isPro) {
        openPremium(context, ProReason.personalisasi);
        return;
      }
      if (bg == WidgetBg.foto && style.photoPath == null) {
        onPickPhoto();
        return;
      }
      onChanged((s) => s.copyWith(bg: bg));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label('Latar'),
        Row(
          children: [
            for (final (int i, WidgetBg bg) in WidgetBg.values.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.x8),
              Expanded(
                child: _BgOption(
                  bg: bg,
                  selected: style.bg == bg,
                  pro: bg == WidgetBg.foto && !isPro,
                  swatch: switch (bg) {
                    WidgetBg.tema => [theme.dark ? const Color(0xFF1A1730) : Colors.white],
                    WidgetBg.aksen => [theme.accent],
                    WidgetBg.gradien => widgetGradient(0, theme.accent),
                    WidgetBg.foto => const [Color(0xFFF4B183), Color(0xFF6E5BA8)],
                  },
                  onTap: () => pickBg(bg),
                ),
              ),
            ],
          ],
        ),
        if (style.bg == WidgetBg.gradien) ...[
          const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              for (final (int i, String name) in widgetGradientNames.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.x8),
                Expanded(
                  child: Pressable(
                    onTap: () => onChanged((s) => s.copyWith(gradient: i)),
                    semanticLabel: 'Gradien $name',
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.smAll,
                        border: Border.all(color: style.gradient == i ? c.ink : Colors.transparent, width: 2),
                        gradient: LinearGradient(colors: widgetGradient(i, theme.accent)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (style.bg == WidgetBg.foto && style.photoPath != null) ...[
          const SizedBox(height: AppSpace.x8),
          Container(
            padding: const EdgeInsets.all(AppSpace.x12),
            decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.file(File(style.photoPath!), width: 52, height: 52, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(child: Text('Foto dari galeri', style: t.item.copyWith(fontSize: 14))),
                  AppButton(
                      label: busy ? 'Memproses…' : 'Ganti',
                      variant: AppButtonVariant.soft,
                      expand: false,
                      onPressed: busy ? null : onPickPhoto),
                ]),
                _SliderRow(
                  label: 'Posisi foto',
                  value: style.focusY,
                  min: 0,
                  max: 1,
                  valueText: style.focusY < 0.34 ? 'Atas' : style.focusY > 0.66 ? 'Bawah' : 'Tengah',
                  onChanged: (v) => onChanged((s) => s.copyWith(focusY: v)),
                ),
                _SliderRow(
                  label: 'Lapisan agar teks terbaca',
                  value: style.scrim.toDouble(),
                  min: 0,
                  max: 60,
                  valueText: '${style.scrim}%',
                  onChanged: (v) => onChanged((s) => s.copyWith(scrim: v.round())),
                ),
                Text('Foto tetap di HP-mu, tidak ikut backup, dan dihapus saat widget dilepas.',
                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
          ),
        ],
        label('Transparansi', '${style.transparency}%'),
        Slider(
          value: style.transparency.toDouble(),
          max: 80,
          divisions: 16,
          label: '${style.transparency}%',
          onChanged: (v) => onChanged((s) => s.copyWith(transparency: v.round())),
        ),
        label('Sudut'),
        AppSegmentedControl<WidgetCorner>(
          options: WidgetCorner.values,
          selected: style.corner,
          labelOf: (v) => v.label,
          onChanged: (v) => onChanged((s) => s.copyWith(corner: v)),
        ),
        label('Warna teks'),
        AppSegmentedControl<WidgetText>(
          options: WidgetText.values,
          selected: style.text,
          labelOf: (v) => v.label,
          onChanged: (v) => onChanged((s) => s.copyWith(text: v)),
        ),
        const SizedBox(height: AppSpace.x16),
        SettingsGroup(
          children: [
            SwitchListTile.adaptive(
              value: style.hideAmounts,
              activeTrackColor: c.accent,
              title: Text('Samarkan angka di widget ini', style: t.item.copyWith(fontSize: 14)),
              subtitle: Text('Cocok untuk widget yang sering dilihat orang', style: t.caption.copyWith(color: c.muted)),
              onChanged: (v) => onChanged((s) => s.copyWith(hideAmounts: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _BgOption extends StatelessWidget {
  const _BgOption({required this.bg, required this.selected, required this.pro, required this.swatch, required this.onTap});

  final WidgetBg bg;
  final bool selected;
  final bool pro;
  final List<Color> swatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Latar ${bg.label}${pro ? ', Pro' : ''}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: selected ? c.accent : c.line, width: 2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.line),
                    color: swatch.length == 1 ? swatch.first : null,
                    gradient: swatch.length > 1 ? LinearGradient(colors: swatch) : null,
                  ),
                ),
                const SizedBox(height: AppSpace.x4),
                Text(bg.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label.copyWith(color: c.sub2)),
              ],
            ),
            if (pro) const Positioned(top: -4, right: 2, child: AppBadge.pro()),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.onChanged,
  });

  final String label;
  final double value, min, max;
  final String valueText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: t.caption.copyWith(color: c.sub))),
            Text(valueText, style: t.caption.copyWith(color: c.sub)),
          ]),
          Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}
