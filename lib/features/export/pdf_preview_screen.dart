import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/screen_header.dart';
import 'export_actions.dart';

/// Pratinjau PDF laporan (Claude Design › Pratinjau PDF): halaman kertas
/// putih yang bisa digulir, lalu Simpan / Bagikan.
class PdfPreviewScreen extends ConsumerStatefulWidget {
  const PdfPreviewScreen({super.key, required this.bytes, required this.fileName, required this.periodLabel});

  final Uint8List bytes;
  final String fileName;
  final String periodLabel;

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  final List<ui.Image> _pages = [];
  bool _done = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      await for (final PdfRaster page in Printing.raster(widget.bytes, dpi: 110)) {
        final ui.Image img = await page.toImage();
        if (!mounted) return;
        setState(() => _pages.add(img));
      }
    } on Object {
      // Pratinjau gagal dirender (perangkat tanpa PdfRenderer): tetap bisa disimpan/dibagikan.
    }
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    for (final ui.Image i in _pages) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _act(Future<bool> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      final bool done = await action();
      if (done && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final String kb = '${(widget.bytes.length / 1024).round()} KB';
    return Scaffold(
      backgroundColor: dark ? c.bg : const Color(0xFFE9E7F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x8),
              child: Column(
                children: [
                  const ScreenHeader(title: 'Pratinjau PDF'),
                  Text(
                    '${widget.periodLabel} · ${_done ? '${_pages.length} halaman · ' : ''}$kb',
                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _pages.isEmpty && !_done
                  ? const Center(child: CircularProgressIndicator())
                  : _pages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpace.x24),
                            child: Text('Pratinjau tidak tersedia di HP ini. PDF tetap bisa disimpan atau dibagikan.',
                                textAlign: TextAlign.center, style: t.body.copyWith(color: c.sub)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpace.x24, AppSpace.x4, AppSpace.x24, AppSpace.x24),
                          itemCount: _pages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x16),
                          itemBuilder: (_, i) => Semantics(
                            label: 'Halaman ${i + 1} dari ${_pages.length}',
                            image: true,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 24, offset: Offset(0, 6))],
                              ),
                              child: AspectRatio(
                                aspectRatio: _pages[i].width / _pages[i].height,
                                // Halaman PDF transparan: latar kertas putih.
                                child: ColoredBox(color: Colors.white, child: RawImage(image: _pages[i], fit: BoxFit.contain)),
                              ),
                            ),
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x12, AppSpace.screenH, AppSpace.x16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: AppButton(
                      label: 'Simpan',
                      icon: HiIcons.download,
                      variant: AppButtonVariant.outline,
                      onPressed: _busy
                          ? null
                          : () => _act(() => saveExportFile(ref, widget.bytes, widget.fileName, 'application/pdf'),
                              'PDF tersimpan. Berkas ini tidak terenkripsi.'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    flex: 14,
                    child: AppButton(
                      key: const Key('bagikan-pdf'),
                      label: 'Bagikan',
                      icon: HiIcons.share,
                      onPressed: _busy
                          ? null
                          : () => _act(() async {
                                await shareExportFile(ref, widget.bytes, widget.fileName, 'application/pdf');
                                return false;
                              }, ''),
                    ),
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
