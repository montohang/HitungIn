import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/accent_color.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/theme/photo_palette.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../premium/data/pro_limits.dart';
import '../../premium/pro_controller.dart';
import '../../premium/widgets/pro_teaser.dart';
import '../../security/app_gate.dart';
import '../../widgets/data/widget_style.dart';
import '../../widgets/widget_styles_provider.dart';
import 'settings_tile.dart';

/// Pilihan warna aksen (P2b): preset, Wallpaper (Material You), Bebas & Dari
/// foto (Pro).
class AccentPicker extends ConsumerWidget {
  const AccentPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeSettings s = ref.watch(themeControllerProvider);
    final ThemeController ctl = ref.read(themeControllerProvider.notifier);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool isPro = ref.watch(isProProvider);
    void needPro() => openPremium(context, ProReason.personalisasi);

    return Wrap(
      spacing: AppSpace.x12,
      runSpacing: AppSpace.x12,
      children: [
        for (final a in AccentPreset.values)
          _Swatch(
            label: a.pro && !isPro ? '${a.label} · Pro' : a.label,
            fill: BoxDecoration(color: dark ? a.dark : a.light, shape: BoxShape.circle),
            ring: dark ? a.dark : a.light,
            selected: s.source == AccentSource.preset && a == s.accent,
            locked: a.pro && !isPro,
            onTap: () => a.pro && !isPro ? openPremium(context, ProReason.tema) : ctl.setAccent(a),
          ),
        if (s.wallpaper != null)
          _Swatch(
            label: 'Wallpaper',
            fill: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [Color(0xFF4F6B8A), Color(0xFF8AA6C1), Color(0xFFC9A27A), Color(0xFF4F6B8A)]),
            ),
            ring: s.wallpaper!,
            selected: s.source == AccentSource.wallpaper,
            onTap: ctl.setWallpaperAccent,
          ),
        _Swatch(
          label: isPro ? 'Bebas' : 'Bebas · Pro',
          fill: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              Color(0xFFE0457B), Color(0xFFF2C14E), Color(0xFF2FA37A), Color(0xFF3B78C4), Color(0xFF8B5CF6), Color(0xFFE0457B),
            ]),
          ),
          ring: s.custom ?? s.accentLight,
          selected: s.source == AccentSource.custom,
          locked: !isPro,
          onTap: () => isPro
              ? showAppSheet<void>(context, title: 'Warna bebas', builder: (_) => const _FreeColorSheet())
              : needPro(),
        ),
        _Swatch(
          label: isPro ? 'Dari foto' : 'Dari foto · Pro',
          fill: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4B183), Color(0xFFE57A6B), Color(0xFF6E5BA8), Color(0xFF26315C)],
            ),
          ),
          ring: s.accentLight,
          selected: false,
          locked: !isPro,
          onTap: () => isPro
              ? showAppSheet<void>(context, title: 'Warna dari foto', builder: (_) => const _PhotoColorSheet())
              : needPro(),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.fill,
    required this.ring,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final BoxDecoration fill;
  final Color ring;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Aksen $label',
        child: Column(
          children: [
            AnimatedContainer(
              duration: context.reduceMotion ? Duration.zero : AppMotion.press,
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(AppSpace.x4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? ring : Colors.transparent, width: 2),
              ),
              child: DecoratedBox(
                decoration: fill,
                child: selected
                    ? const Icon(HiIcons.check, color: Colors.white, size: 20)
                    : locked
                        ? const Icon(HiIcons.lock, color: Colors.white, size: 18)
                        : null,
              ),
            ),
            const SizedBox(height: AppSpace.x4),
            Text(label, style: t.label.copyWith(color: c.sub)),
          ],
        ),
      ),
    );
  }
}

/// Penggeser rona & kecerahan dengan cek kontras langsung.
class _FreeColorSheet extends ConsumerStatefulWidget {
  const _FreeColorSheet();

  @override
  ConsumerState<_FreeColorSheet> createState() => _FreeColorSheetState();
}

class _FreeColorSheetState extends ConsumerState<_FreeColorSheet> {
  late double _hue = HSL.of(ref.read(themeControllerProvider).accentLight).hue;
  double _light = 0.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Color raw = colorFromHue(_hue, lightness: _light);
    final Color safe = ensureWhiteContrast(raw);
    final double ratio = contrastOnWhite(raw);
    final bool ok = ratio >= 4.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillAll,
            gradient: LinearGradient(colors: [for (int h = 0; h <= 360; h += 60) colorFromHue(h.toDouble())]),
          ),
        ),
        Slider(value: _hue, max: 359, onChanged: (v) => setState(() => _hue = v), label: 'Rona'),
        Text('Kecerahan', style: t.caption.copyWith(color: c.sub)),
        Slider(value: _light, min: 0.25, max: 0.7, onChanged: (v) => setState(() => _light = v)),
        const SizedBox(height: AppSpace.x8),
        Row(
          children: [
            Container(
              width: 56,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: safe, borderRadius: AppRadius.smAll),
              child: Text('Aa', style: t.item.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Text(
                ok
                    ? 'Kontras teks putih ${ratio.toStringAsFixed(1).replaceAll('.', ',')}:1 — terbaca'
                    : 'Terlalu terang (${ratio.toStringAsFixed(1).replaceAll('.', ',')}:1) — digelapkan sedikit supaya terbaca',
                style: t.caption.copyWith(color: ok ? c.good : c.warnInk),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Pakai warna ini',
          large: true,
          onPressed: () {
            ref.read(themeControllerProvider.notifier).setCustomAccent(safe);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

/// Ambil 3–4 warna dari foto widget atau foto pilihan.
class _PhotoColorSheet extends ConsumerStatefulWidget {
  const _PhotoColorSheet();

  @override
  ConsumerState<_PhotoColorSheet> createState() => _PhotoColorSheetState();
}

class _PhotoColorSheetState extends ConsumerState<_PhotoColorSheet> {
  Uint8List? _photo;
  List<Color> _colors = const [];
  bool _busy = false;

  Future<void> _load(Uint8List bytes) async {
    setState(() => _busy = true);
    try {
      final List<Color> colors = await paletteFromImageBytes(bytes);
      if (mounted) {
        setState(() {
          _photo = bytes;
          _colors = colors;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _colors = const []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final PlatformFile? f =
        await withAutoLockPaused(ref, () => FilePicker.pickFile(dialogTitle: 'Pilih foto', type: FileType.image));
    if (f != null) await _load(await f.xFile.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<String> widgetPhotos = [
      for (final WidgetStyle s in (ref.watch(widgetStylesProvider).valueOrNull ?? const <int, WidgetStyle>{}).values)
        if (s.photoPath != null && File(s.photoPath!).existsSync()) s.photoPath!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widgetPhotos.isNotEmpty) ...[
          Text('Foto widget-mu', style: t.caption.copyWith(color: c.sub)),
          const SizedBox(height: AppSpace.x8),
          Wrap(
            spacing: AppSpace.x8,
            children: [
              for (final String p in widgetPhotos)
                Pressable(
                  onTap: () async => _load(await File(p).readAsBytes()),
                  semanticLabel: 'Pakai foto widget',
                  child: ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.file(File(p), width: 56, height: 56, fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
        ],
        AppButton(
          label: _busy ? 'Memproses…' : 'Pilih foto dari galeri',
          icon: HiIcons.camera,
          variant: AppButtonVariant.outline,
          onPressed: _busy ? null : _pick,
        ),
        if (_photo != null) ...[
          const SizedBox(height: AppSpace.x16),
          Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: Image.memory(_photo!, width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: _colors.isEmpty
                    ? Text('Foto ini kurang berwarna. Coba foto lain.', style: t.caption.copyWith(color: c.muted))
                    : Wrap(
                        spacing: AppSpace.x8,
                        children: [
                          for (final Color col in _colors)
                            Pressable(
                              onTap: () {
                                ref.read(themeControllerProvider.notifier).setCustomAccent(col);
                                Navigator.pop(context);
                              },
                              semanticLabel: 'Pakai warna ini',
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.x8),
        Text('Foto hanya dibaca di HP-mu untuk mengambil warnanya, tidak disimpan.',
            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
      ],
    );
  }
}
