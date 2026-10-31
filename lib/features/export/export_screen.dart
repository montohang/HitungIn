import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../backup/data/csv_export.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'data/export_report.dart';
import 'data/xlsx_export.dart';
import 'export_actions.dart';

/// Rute Export data, opsional dengan format terpilih.
String exportLink({ExportFormat? format}) =>
    Uri(path: Routes.export, queryParameters: {if (format != null) 'format': format.name}).toString();

/// Nama sheet Excel yang mungkin dibuat (untuk chip "Isi file").
const List<String> excelSheetNames = [
  'Ringkasan', 'Transaksi', 'Bulanan', 'Per kategori', 'Sub-kategori', 'Per dompet', 'Harian', 'Budget',
  'Kekayaan bersih', 'Tren kekayaan', 'Utang-piutang', 'Tagihan & cicilan', 'Target tabungan', 'Patungan', 'Transaksi berulang',
];

/// Export data (P3g, Claude Design › Export data): format, periode, dompet.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, this.format = ExportFormat.pdf});

  final ExportFormat format;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late ExportFormat _format = widget.format;
  ExportPeriod _period = ExportPeriod.bulanIni;
  DateRange? _custom;
  DateTime? _firstData;
  Wallet? _wallet;
  List<Wallet> _wallets = const [];
  bool _attachment = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
    purgeExportFiles();
  }

  Future<void> _load() async {
    final AppDatabase db = ref.read(appDatabaseProvider);
    final List<Wallet> ws = await db.walletsDao.active();
    final all = await db.transactionsDao.allDetails();
    if (!mounted) return;
    setState(() {
      _wallets = ws;
      _firstData = all.isEmpty ? null : all.map((d) => d.tx.occurredAt).reduce((a, b) => a.isBefore(b) ? a : b);
    });
  }

  DateTime get _now => ref.read(clockProvider)();
  DateRange get _range => exportRange(_period, _now, custom: _custom, firstData: _firstData);
  bool get _isPro => ref.watch(isProProvider);

  bool _periodLocked(ExportPeriod p) =>
      !_isPro && _format == ExportFormat.pdf && !exportAllowedFree(ExportFormat.pdf, exportRange(p, _now, custom: _custom, firstData: _firstData), _now);

  bool get _needPro => switch (_format) {
        ExportFormat.xlsx => !_isPro,
        ExportFormat.pdf => _periodLocked(_period),
        ExportFormat.csv => false,
      };

  Future<void> _pickPeriod(ExportPeriod p) async {
    if (p == ExportPeriod.pilih) {
      final DateTime now = _now;
      final DateTimeRange? r = await showDateRangePicker(
        context: context,
        firstDate: _firstData ?? DateTime(now.year - 1),
        lastDate: DateTime(now.year, now.month, now.day),
        initialDateRange: _custom == null ? null : DateTimeRange(start: _custom!.from, end: _custom!.to.subtract(const Duration(days: 1))),
        helpText: 'Pilih periode',
      );
      if (r == null || !mounted) return;
      setState(() {
        _custom = (from: DateTime(r.start.year, r.start.month, r.start.day), to: DateTime(r.end.year, r.end.month, r.end.day + 1));
        _period = p;
      });
      return;
    }
    setState(() => _period = p);
  }

  Future<void> _pickWallet() async {
    final Wallet none = Wallet(id: -1, name: '', type: WalletType.lainnya, initialBalance: 0, icon: '', color: 0, sortOrder: 0, archived: false, createdAt: DateTime(2000));
    final Wallet? picked = await showAppSheet<Wallet>(
      context,
      title: 'Dompet',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final Wallet w in [none, ..._wallets])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(w.id == -1 ? 'Semua dompet (${_wallets.length})' : w.name),
              trailing: (w.id == -1 ? _wallet == null : _wallet?.id == w.id) ? Icon(HiIcons.check, color: context.colors.accentText) : null,
              onTap: () => Navigator.pop(context, w),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _wallet = picked.id == -1 ? null : picked);
  }

  Future<void> _go({required bool save}) async {
    if (_needPro) {
      openPremium(context, ProReason.export);
      return;
    }
    if (_format == ExportFormat.pdf && !save) {
      setState(() => _busy = true);
      try {
        await openPdfReport(context, ref, range: _range, walletId: _wallet?.id, attachment: _attachment);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    if (_format == ExportFormat.csv && !await unlockCsvExport(context, ref)) return;
    setState(() => _busy = true);
    try {
      final ExportInput x = await loadExportInput(ref.read(appDatabaseProvider), range: _range, now: _now, walletId: _wallet?.id, includeManualNet: ref.read(isProProvider));
      if (_format != ExportFormat.pdf && x.txs.isEmpty && _format == ExportFormat.csv) {
        _toast('Belum ada transaksi di periode ini.');
        return;
      }
      final Uint8List bytes = switch (_format) {
        ExportFormat.xlsx => XlsxExport.build(x),
        ExportFormat.csv => CsvExport.bytes(x.txs),
        ExportFormat.pdf => await _pdf(x),
      };
      final String name = exportFileName(_format, _range);
      if (save) {
        if (await saveExportFile(ref, bytes, name, _format.mimeType)) {
          _toast('$name tersimpan. Berkas ini tidak terenkripsi.');
        }
      } else {
        await shareExportFile(ref, bytes, name, _format.mimeType);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _pdf(ExportInput x) async {
    final Color accent = context.colors.accent;
    final fonts = await loadPdfFonts();
    return buildPdfBytes(x, attachment: _attachment, accent: accent, fonts: fonts);
  }

  void _toast(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool isPro = _isPro;
    final DateRange range = _range;
    final String periodLine = _periodLocked(_period)
        ? 'Versi gratis: PDF bulan berjalan. Periode lain dengan Pro.'
        : rangeLabel(range, _now);
    final String fmtName = switch (_format) {
      ExportFormat.pdf => 'PDF',
      ExportFormat.xlsx => 'Excel',
      ExportFormat.csv => 'CSV',
    };

    Widget label(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.x4, AppSpace.x16, AppSpace.x4, AppSpace.x8),
          child: Text(s, style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub)),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x16, AppSpace.screenH, AppSpace.x16),
          child: Column(
            children: [
              const ScreenHeader(title: 'Export data'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    label('Format'),
                    for (final ExportFormat f in ExportFormat.values) ...[
                      _FormatCard(
                        format: f,
                        selected: f == _format,
                        badge: switch (f) {
                          ExportFormat.pdf => isPro ? null : 'GRATIS BULAN INI',
                          ExportFormat.xlsx => isPro ? null : 'PRO',
                          ExportFormat.csv => isPro ? null : 'GRATIS LEWAT IKLAN',
                        },
                        pro: f == ExportFormat.xlsx,
                        onTap: () => setState(() {
                          _format = f;
                          if (!isPro && f == ExportFormat.pdf && _periodLocked(_period)) _period = ExportPeriod.bulanIni;
                        }),
                      ),
                      const SizedBox(height: AppSpace.x8),
                    ],
                    label('Periode'),
                    Wrap(
                      spacing: AppSpace.x8,
                      runSpacing: AppSpace.x8,
                      children: [
                        for (final ExportPeriod p in ExportPeriod.values)
                          AppChip(
                            label: p.label,
                            selected: p == _period,
                            icon: _periodLocked(p) ? HiIcons.lock : null,
                            onTap: () => _pickPeriod(p),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.x4, AppSpace.x8, AppSpace.x4, 0),
                      child: Text(periodLine, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                      child: Column(
                        children: [
                          Pressable(
                            onTap: _pickWallet,
                            semanticLabel: 'Pilih dompet',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
                              child: Row(
                                children: [
                                  Icon(HiIcons.wallet, size: 20, color: c.muted),
                                  const SizedBox(width: AppSpace.x12),
                                  Expanded(child: Text('Dompet', style: t.item.copyWith(fontSize: 14))),
                                  Text(_wallet?.name ?? 'Semua (${_wallets.length})', style: t.caption.copyWith(color: c.sub)),
                                  Icon(HiIcons.forward, size: 16, color: c.muted),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, color: c.line),
                          switch (_format) {
                            ExportFormat.pdf => Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpace.x8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Lampiran transaksi', style: t.item.copyWith(fontSize: 14)),
                                          Text('Tabel semua transaksi di akhir PDF',
                                              style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                                        ],
                                      ),
                                    ),
                                    Switch(value: _attachment, onChanged: (v) => setState(() => _attachment = v)),
                                  ],
                                ),
                              ),
                            ExportFormat.xlsx => Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Isi file · sampai ${excelSheetNames.length} sheet', style: t.item.copyWith(fontSize: 14)),
                                    const SizedBox(height: AppSpace.x8),
                                    Wrap(spacing: 6, runSpacing: 6, children: [
                                      for (final String s in excelSheetNames)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.pillAll),
                                          child: Text(s, style: t.label.copyWith(color: c.sub)),
                                        ),
                                    ]),
                                    const SizedBox(height: AppSpace.x8),
                                    Text('Sheet tanpa data tidak dibuat. Nominal berupa angka Rupiah, siap dijumlah.',
                                        style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                                  ],
                                ),
                              ),
                            ExportFormat.csv => Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
                                child: Text('Satu file berisi semua transaksi periode ini. Cocok untuk diimpor ke aplikasi lain.',
                                    style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
                              ),
                          },
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.x12),
                      decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.mdAll),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(HiIcons.warning, size: 18, color: c.warnInk),
                          const SizedBox(width: AppSpace.x8),
                          Expanded(
                            child: Text(
                              'Dibuat di HP-mu, offline. File $fmtName tidak terenkripsi — siapa pun yang menerimanya bisa membaca isinya.',
                              style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.ink, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x16),
                  ],
                ),
              ),
              if (_needPro)
                Pressable(
                  key: const Key('export-pro'),
                  onTap: () => openPremium(context, ProReason.export),
                  semanticLabel: 'Buka dengan Pro',
                  child: Container(
                    height: 54,
                    decoration: const BoxDecoration(color: Color(0xFFF6D27A), borderRadius: AppRadius.mdAll),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(HiIcons.lock, size: 18, color: Color(0xFF1A1733)),
                      const SizedBox(width: AppSpace.x8),
                      Text('Buka dengan Pro', style: t.title.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1A1733))),
                    ]),
                  ),
                )
              else ...[
                AppButton(
                  key: const Key('export-bagikan'),
                  label: _format == ExportFormat.pdf ? 'Pratinjau & bagikan' : 'Buat & bagikan',
                  icon: HiIcons.share,
                  large: true,
                  onPressed: _busy ? null : () => _go(save: false),
                ),
                const SizedBox(height: AppSpace.x8),
                AppButton(
                  key: const Key('export-simpan'),
                  label: 'Simpan ke folder',
                  variant: AppButtonVariant.outline,
                  onPressed: _busy ? null : () => _go(save: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({required this.format, required this.selected, required this.badge, required this.pro, required this.onTap});

  final ExportFormat format;
  final bool selected;
  final String? badge;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final (IconData icon, String desc) = switch (format) {
      ExportFormat.pdf => (HiIcons.document, 'Ringkasan, posisi keuangan & lampiran transaksi. Siap dikirim atau diarsipkan.'),
      ExportFormat.xlsx => (HiIcons.table, 'Sampai 15 sheet: transaksi, bulanan, kategori, dompet, budget, utang, target…'),
      ExportFormat.csv => (HiIcons.document, 'Daftar transaksi mentah untuk aplikasi lain.'),
    };
    return Pressable.card(
      key: Key('format-${format.name}'),
      onTap: onTap,
      semanticLabel: format.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.x12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent : c.line, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(icon, size: 20, color: c.accentText),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpace.x8, runSpacing: 4, children: [
                    Text(format.label, style: t.title),
                    if (badge != null)
                      pro
                          ? const AppBadge.pro()
                          : AppBadge(badge!, background: c.goodSoft, foreground: c.goodInk),
                  ]),
                  const SizedBox(height: 2),
                  Text(desc, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.accent : c.line, width: 2)),
              child: selected
                  ? Container(width: 10, height: 10, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
