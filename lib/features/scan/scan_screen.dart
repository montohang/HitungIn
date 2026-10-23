import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show MissingPluginException, PlatformException;
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import '../transactions/quick_entry_parser.dart';
import '../wallets/data/wallets_dao.dart' show WalletBalance;
import 'data/receipt_parser.dart';
import 'receipt_ocr.dart';

/// Hasil scan yang sudah diperiksa pengguna.
typedef ScanResult = ({ReceiptScan scan, int amount, String note, DateTime? date, int? walletId, int? categoryId});

/// Tebak dompet & kategori dari teks struk lewat pembaca Catat cepat.
({int? walletId, int? categoryId}) guessFromReceipt(ReceiptScan s, List<Wallet> wallets, List<Category> categories) {
  final QuickEntryParser p = QuickEntryParser(wallets: wallets, categories: categories);
  final int? wallet = s.payment == null ? null : p.parse(s.payment!.toLowerCase()).walletId;
  // Nama toko lebih menentukan daripada nama item (Indomaret → Belanja walau ada "indomie").
  int? cat = s.merchant == null ? null : p.parse(s.merchant!.toLowerCase()).categoryId;
  if (cat == null) {
    final String text = [for (final i in s.items.take(4)) i.name].join(' ').toLowerCase();
    cat = text.trim().isEmpty ? null : p.parse(text).categoryId;
  }
  return (walletId: wallet, categoryId: cat);
}

/// Scan struk dari Catat ([forSplit] false) atau Patungan per menu.
/// Null bila dibatalkan atau kuota habis.
Future<ScanResult?> startReceiptScan(BuildContext context, WidgetRef ref, {required bool forSplit}) async {
  final bool isPro = ref.read(isProProvider);
  final int used = await scansUsed(ref.read(appDatabaseProvider).settingsDao, ref.read(clockProvider)());
  if (!context.mounted) return null;
  if (!FreeLimits.canScanReceipt(usedThisMonth: used, isPro: isPro)) {
    await showAppSheet<void>(context, title: 'Jatah scan gratis bulan ini habis', builder: (_) => const _QuotaSheet());
    return null;
  }
  final _Source? source = await showAppSheet<_Source>(
    context,
    title: 'Scan struk',
    builder: (_) => _SourceSheet(forSplit: forSplit, left: isPro ? null : FreeLimits.receiptScans - used),
  );
  if (source == null || !context.mounted) return null;
  final String? path = source == _Source.pindai
      ? await withAutoLockPaused(ref, scanWithDocumentScanner)
      : await withAutoLockPaused(ref, () => _pick(ImageSource.gallery));
  if (path == null || !context.mounted) return null;
  return Navigator.of(context, rootNavigator: true).push<ScanResult>(
    MaterialPageRoute(builder: (_) => ScanReviewScreen(path: path, forSplit: forSplit)),
  );
}

enum _Source { pindai, galeri }

Future<String?> _pick(ImageSource source) async {
  final String? path =
      (await ImagePicker().pickImage(source: source, maxWidth: 2200, imageQuality: 92, requestFullMetadata: false))?.path;
  // Batal dari kamera tetap meninggalkan berkas kosong.
  if (path == null) await purgePickerTemp();
  return path;
}

final RegExp _uuidName = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');

/// Hapus salinan sementara dari pemilih gambar & pemindai (folder/berkas
/// bernama UUID di cache, dan isi folder pemindai ML Kit). Foto struk tidak
/// boleh tertinggal di HP.
Future<void> purgePickerTemp([Directory? dir]) async {
  try {
    final Directory tmp = dir ?? await getTemporaryDirectory();
    if (!await tmp.exists()) return;
    await for (final FileSystemEntity e in tmp.list()) {
      final String name = e.uri.pathSegments.where((x) => x.isNotEmpty).last;
      if (_uuidName.hasMatch(name) || name == 'mlkit_docscan_ui_client') {
        if (e is Directory && name == 'mlkit_docscan_ui_client') {
          await for (final FileSystemEntity c in e.list()) {
            await c.delete(recursive: true);
          }
        } else if (e is Directory) {
          await e.delete(recursive: true);
        } else if (e is File) {
          await e.delete();
        }
      }
    }
  } catch (_) {
    // Pembersihan tidak boleh menggagalkan scan.
  }
}

/// Pemindai dokumen ML Kit (Google Play Services): tepi struk dideteksi,
/// dipotong & diluruskan. Dibatalkan → null. Pemindai tidak tersedia (tanpa
/// Play Services / modul belum terunduh) → kamera bawaan.
Future<String?> scanWithDocumentScanner() async {
  final DocumentScanner scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormats: const {DocumentFormat.jpeg},
      mode: ScannerMode.filter,
      pageLimit: 1,
      isGalleryImport: false,
    ),
  );
  try {
    final DocumentScanningResult r = await scanner.scanDocument();
    final String? uri = r.images?.firstOrNull;
    return uri == null ? null : Uri.parse(uri).isScheme('file') ? Uri.parse(uri).toFilePath() : uri;
  } on PlatformException catch (e) {
    if ((e.message ?? '').toLowerCase().contains('cancel')) {
      await purgePickerTemp();
      return null;
    }
    return _pick(ImageSource.camera);
  } on MissingPluginException {
    return _pick(ImageSource.camera);
  } finally {
    await scanner.close();
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.forSplit, required this.left});

  final bool forSplit;

  /// Sisa kuota gratis; null = Pro.
  final int? left;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget source(IconData icon, String label, _Source s, {String? hint, bool primary = false}) => Expanded(
          child: Pressable(
            onTap: () => Navigator.pop(context, s),
            semanticLabel: label,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: primary ? c.accentSoft : c.bg,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: primary ? c.accent : c.line),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 28, color: c.accent),
                const SizedBox(height: AppSpace.x4),
                Text(label, style: t.title.copyWith(fontSize: 14)),
                if (hint != null) Text(hint, style: t.label.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: c.muted)),
              ]),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          forSplit
              ? 'Foto struk restoran — semua menu, PB1, dan service langsung masuk ke Patungan per menu.'
              : 'Foto struk belanja — total, toko, tanggal, dan cara bayar langsung terisi di Catat.',
          style: t.body.copyWith(color: c.sub),
        ),
        const SizedBox(height: AppSpace.x16),
        Row(children: [
          source(HiIcons.scan, 'Pindai', _Source.pindai, hint: 'potong & luruskan otomatis', primary: true),
          const SizedBox(width: AppSpace.x12),
          source(HiIcons.image, 'Galeri', _Source.galeri),
        ]),
        const SizedBox(height: AppSpace.x16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8 + 2),
          decoration: BoxDecoration(color: c.goodSoft, borderRadius: AppRadius.smAll),
          child: Row(children: [
            Icon(HiIcons.shield, size: 16, color: c.goodInk),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: Text('Dibaca di HP-mu, offline. Foto langsung dihapus.',
                  style: t.caption.copyWith(color: c.goodInk, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        if (left != null) ...[
          const SizedBox(height: AppSpace.x12),
          Row(children: [
            const AppBadge.pro(),
            const SizedBox(width: AppSpace.x8),
            Text('Gratis: sisa $left dari ${FreeLimits.receiptScans} scan bulan ini', style: t.caption.copyWith(color: c.sub)),
          ]),
        ],
        const SizedBox(height: AppSpace.x12),
        Text('Pindai memakai pemindai dokumen Google di HP-mu (gratis, diproses di HP). Bila belum tersedia, kamera bawaan yang dipakai.',
            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
      ],
    );
  }
}

class _QuotaSheet extends StatelessWidget {
  const _QuotaSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = DateTime.now();
    final DateTime next = DateTime(now.year, now.month + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: Text('🧾', style: TextStyle(fontSize: 40))),
        const SizedBox(height: AppSpace.x8),
        Text(
          'Kamu sudah memakai ${FreeLimits.receiptScans} scan bulan ini. Jatah kembali 1 ${DateFmt.months[next.month - 1]} — '
          'atau buka Premium untuk scan tanpa batas, sekali bayar.',
          textAlign: TextAlign.center,
          style: t.body.copyWith(color: c.sub),
        ),
        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Lihat Premium',
          large: true,
          onPressed: () {
            final NavigatorState nav = Navigator.of(context);
            nav.pop();
            openPremium(nav.context, ProReason.scan);
          },
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(label: 'Ketik manual saja', variant: AppButtonVariant.soft, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

/// Membaca struk lalu menampilkan hasil untuk diperiksa (P3e).
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key, required this.path, required this.forSplit});

  final String path;
  final bool forSplit;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  Uint8List? _image;
  ReceiptScan? _scan;
  String? _error;
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  DateTime? _date;
  int? _walletId;
  int? _categoryId;
  List<ReceiptItem> _items = [];
  bool _countedLeft = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    final File f = File(widget.path);
    try {
      _image = await f.readAsBytes();
      if (mounted) setState(() {});
      final List<OcrLine> lines = await ref.read(receiptOcrProvider).read(widget.path);
      final List<String> rows = receiptRows(lines);
      if (kDebugMode) debugPrint('SCAN rows:\n${rows.join('\n')}');
      final ReceiptScan scan = parseReceipt(rows, now: ref.read(clockProvider)());
      if (!mounted) return;
      if (scan.isEmpty) {
        setState(() => _error = 'Teks struk tidak terbaca. Coba foto lebih terang dan lurus.');
        return;
      }
      await markScanIntroDone(ref.read(appDatabaseProvider).settingsDao);
      if (!ref.read(isProProvider)) {
        await countScan(ref.read(appDatabaseProvider).settingsDao, ref.read(clockProvider)());
        _countedLeft = true;
      }
      final List<Wallet> wallets = [
        for (final WalletBalance w in ref.read(walletBalancesProvider).valueOrNull ?? const <WalletBalance>[]) w.wallet,
      ];
      final List<Category> cats = ref.read(activeCategoriesProvider).valueOrNull ?? const [];
      final g = guessFromReceipt(scan, wallets, cats);
      setState(() {
        _scan = scan;
        _amount.text = scan.total == null ? '' : Rupiah.digits(scan.total!);
        _note.text = scan.merchant ?? '';
        _date = scan.date;
        _walletId = g.walletId;
        _categoryId = g.categoryId;
        _items = [...scan.items];
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Struk gagal dibaca di HP ini. Coba lagi atau ketik manual.');
    } finally {
      // Foto tidak disimpan: hapus begitu selesai dibaca, beserta salinan sementaranya.
      if (await f.exists()) await f.delete();
      await purgePickerTemp();
    }
  }

  void _use() {
    final ReceiptScan s = _scan!;
    final int amount = RupiahInputFormatter.parse(_amount.text);
    final int itemsSum = _items.fold(0, (a, i) => a + i.price);
    Navigator.pop<ScanResult>(context, (
      scan: ReceiptScan(
        merchant: _note.text.trim().isEmpty ? null : _note.text.trim(),
        total: widget.forSplit ? itemsSum + s.tax + s.service + s.extraFee - s.discount : amount,
        date: _date,
        payment: s.payment,
        items: _items,
        subtotal: widget.forSplit ? itemsSum : s.subtotal,
        tax: s.tax,
        service: s.service,
        discount: s.discount,
        extraFee: s.extraFee,
      ),
      amount: amount,
      note: _note.text.trim(),
      date: _date,
      walletId: _walletId,
      categoryId: _categoryId,
    ));
  }

  Future<void> _editItem(int i) async {
    final ReceiptItem it = _items[i];
    final ReceiptItem? r = await showAppSheet<ReceiptItem>(context, title: 'Ubah item', builder: (_) => _ItemEdit(item: it));
    if (r != null) setState(() => _items[i] = r);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final ReceiptScan? s = _scan;
    if (s == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0918),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.x24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_image != null)
                  ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: Image.memory(_image!, height: 320, fit: BoxFit.contain),
                  ),
                const SizedBox(height: AppSpace.x24),
                if (_error == null) ...[
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
                  const SizedBox(height: AppSpace.x16),
                  Text('Membaca struk…', style: t.section.copyWith(color: Colors.white)),
                  const SizedBox(height: AppSpace.x8),
                  Text('Teks dikenali di HP-mu tanpa internet.',
                      textAlign: TextAlign.center, style: t.caption.copyWith(color: Colors.white70)),
                ] else ...[
                  Text(_error!, textAlign: TextAlign.center, style: t.body.copyWith(color: Colors.white)),
                  const SizedBox(height: AppSpace.x16),
                  AppButton(label: 'Kembali', onPressed: () => Navigator.pop(context)),
                ],
              ]),
            ),
          ),
        ),
      );
    }
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    final List<Category> cats = [
      for (final x in ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        if (x.kind == TxKind.pengeluaran) x,
    ];
    final int itemsSum = _items.fold(0, (a, i) => a + i.price);
    final bool match = _items.isNotEmpty && s.total != null && itemsSum + s.tax + s.service + s.extraFee - s.discount == s.total;
    final String check = _items.isEmpty
        ? 'Rincian item tidak terbaca'
        : match
            ? (widget.forSplit
                ? '✓ ${_items.length} item${s.tax > 0 ? ' + pajak' : ''}${s.service > 0 ? ' + service' : ''} = total'
                : '✓ ${_items.length} item cocok dengan total')
            : '⚠ ${_items.length} item = ${Rupiah.format(itemsSum)}, cek lagi';
    final int left = FreeLimits.receiptScans - (ref.watch(scansUsedProvider).valueOrNull ?? 0);
    final DateTime now = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpace.screen,
                children: [
                  const ScreenHeader(title: 'Periksa hasil scan', large: true),
                  const SizedBox(height: AppSpace.x16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: AppRadius.smAll,
                        child: Image.memory(_image!, width: 92, height: 128, fit: BoxFit.cover),
                      ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Total di struk', style: t.label.copyWith(color: c.muted)),
                        Text(s.total == null ? '—' : Rupiah.format(s.total!), style: t.amountL.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpace.x4),
                        Text(check,
                            style: t.label.copyWith(color: match ? c.goodInk : c.warnInk, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.x16),
                  if (!widget.forSplit) ...[
                    _Field(
                      label: 'Nominal',
                      tag: s.unsure.contains('total') ? _Tag.check : _Tag.sure,
                      child: TextField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [RupiahInputFormatter()],
                        style: t.number,
                        decoration: const InputDecoration(
                            isDense: true, prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
                      ),
                    ),
                    _Field(
                      label: 'Catatan (toko)',
                      tag: s.unsure.contains('merchant') ? _Tag.check : _Tag.sure,
                      child: TextField(controller: _note, maxLength: 60, style: t.item, decoration: const InputDecoration(isDense: true, counterText: '')),
                    ),
                    _Field(
                      label: 'Tanggal',
                      tag: s.unsure.contains('date') ? _Tag.check : _Tag.sure,
                      warn: s.date == null
                          ? 'Tanggal tidak terbaca — dipakai hari ini'
                          : s.unsure.contains('date')
                              ? 'Tahun tertulis 2 digit atau di luar kebiasaan — pastikan benar'
                              : null,
                      child: AppChip(
                        label: _date == null ? 'Hari ini' : '${DateFmt.longDate(_date!, now: now)} · ${DateFmt.time(_date!)}',
                        icon: HiIcons.calendar,
                        selected: true,
                        onTap: () async {
                          final DateTime? d = await showDatePicker(
                              context: context, initialDate: _date ?? now, firstDate: DateTime(2000), lastDate: now);
                          if (d != null) {
                            setState(() => _date = DateTime(d.year, d.month, d.day, _date?.hour ?? 12, _date?.minute ?? 0));
                          }
                        },
                      ),
                    ),
                    _Field(
                      label: s.payment == null ? 'Dompet' : 'Dompet (dari "${s.payment}")',
                      tag: _walletId == null ? _Tag.check : _Tag.sure,
                      child: Wrap(spacing: AppSpace.x8, runSpacing: AppSpace.x8, children: [
                        for (final w in wallets)
                          AppChip(
                            label: w.wallet.name,
                            icon: AppIcons.of(w.wallet.icon),
                            emoji: AppIcons.emojiOf(w.wallet.icon),
                            selected: w.wallet.id == _walletId,
                            onTap: () => setState(() => _walletId = w.wallet.id),
                          ),
                      ]),
                    ),
                    _Field(
                      label: 'Kategori',
                      tag: _Tag.guess,
                      child: Wrap(spacing: AppSpace.x8, runSpacing: AppSpace.x8, children: [
                        for (final x in cats.take(10))
                          AppChip(
                            label: x.name,
                            icon: AppIcons.of(x.icon),
                            emoji: AppIcons.emojiOf(x.icon),
                            selected: x.id == _categoryId,
                            onTap: () => setState(() => _categoryId = x.id),
                          ),
                      ]),
                    ),
                    if (_items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.x8),
                        child: Text('${_items.length} item terbaca. Untuk membagi per orang, pakai Scan di Patungan › Per menu.',
                            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
                      ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                      decoration:
                          BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                      child: Column(children: [
                        for (final (int i, ReceiptItem it) in _items.indexed)
                          Pressable(
                            onTap: () => _editItem(i),
                            onLongPress: () => setState(() => _items.removeAt(i)),
                            semanticLabel: '${it.qty} ${it.name} ${Rupiah.format(it.price)}, ketuk untuk ubah, tahan untuk hapus',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                              child: Row(children: [
                                SizedBox(width: 32, child: Text('${it.qty}×', style: t.label.copyWith(color: c.muted))),
                                Expanded(child: Text(it.name, style: t.item.copyWith(fontSize: 14))),
                                Text(Rupiah.format(it.price), style: t.number.copyWith(fontSize: 14)),
                              ]),
                            ),
                          ),
                        for (final (String k, int v, String tag) in [
                          if (s.tax > 0) ('Pajak ${_pct(s.taxPermille)}', s.tax, 'terbaca'),
                          if (s.service > 0) ('Service ${_pct(s.servicePermille)}', s.service, 'terbaca'),
                          if (s.extraFee > 0) ('Ongkir/biaya', s.extraFee, 'terbaca'),
                          if (s.discount > 0) ('Diskon', -s.discount, 'terbaca'),
                          if (s.payment != null) ('Dibayar', s.total ?? 0, s.payment!),
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 - 2),
                            child: Row(children: [
                              Text(k, style: t.caption.copyWith(color: c.sub)),
                              const SizedBox(width: AppSpace.x8 - 2),
                              AppBadge(tag, background: c.goodSoft, foreground: c.goodInk),
                              const Spacer(),
                              Text(Rupiah.format(v), style: t.caption.copyWith(color: c.sub, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                      ]),
                    ),
                    const SizedBox(height: AppSpace.x8),
                    Text('Ketuk item untuk ubah nama/harga, tahan untuk hapus. Setelah dipakai, pilih siapa ikut tiap item.',
                        style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5)),
                  ],
                  if (_countedLeft) ...[
                    const SizedBox(height: AppSpace.x12),
                    Row(children: [
                      const AppBadge.pro(),
                      const SizedBox(width: AppSpace.x8),
                      Expanded(
                        child: Text('Sisa ${left < 0 ? 0 : left} scan gratis bulan ini · Pro tanpa batas',
                            style: t.caption.copyWith(color: c.sub)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x16),
              child: Row(children: [
                Expanded(
                  child: AppButton(label: 'Batal', large: true, variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context)),
                ),
                const SizedBox(width: AppSpace.x8),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    key: const Key('pakai-scan'),
                    label: widget.forSplit ? 'Pakai ${_items.length} item' : 'Pakai',
                    large: true,
                    onPressed: widget.forSplit && _items.isEmpty ? null : _use,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static String _pct(int permille) => '${(permille / 10).toStringAsFixed(permille % 10 == 0 ? 0 : 1).replaceAll('.', ',')}%';
}

enum _Tag { sure, check, guess }

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.tag, required this.child, this.warn});

  final String label;
  final _Tag tag;
  final Widget child;
  final String? warn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final (String text, Color bg, Color fg) = switch (tag) {
      _Tag.sure => ('Yakin', c.goodSoft, c.goodInk),
      _Tag.check => ('Cek lagi', c.warnSoft, c.warnInk),
      _Tag.guess => ('Tebakan', c.chip, c.sub),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: t.label.copyWith(color: c.muted))),
          AppBadge(text, background: bg, foreground: fg),
        ]),
        const SizedBox(height: AppSpace.x4),
        child,
        if (warn != null) ...[
          const SizedBox(height: AppSpace.x4),
          Text('⚠ $warn', style: t.label.copyWith(color: c.warnInk)),
        ],
      ]),
    );
  }
}

class _ItemEdit extends StatefulWidget {
  const _ItemEdit({required this.item});

  final ReceiptItem item;

  @override
  State<_ItemEdit> createState() => _ItemEditState();
}

class _ItemEditState extends State<_ItemEdit> {
  late final TextEditingController _name = TextEditingController(text: widget.item.name);
  late final TextEditingController _price = TextEditingController(text: Rupiah.digits(widget.item.price));

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _name, autofocus: true, maxLength: 60, style: t.item, decoration: const InputDecoration(labelText: 'Nama item', counterText: '')),
      const SizedBox(height: AppSpace.x12),
      TextField(
        controller: _price,
        keyboardType: TextInputType.number,
        inputFormatters: const [RupiahInputFormatter()],
        style: t.number,
        decoration: const InputDecoration(labelText: 'Harga (total baris)', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
      ),
      const SizedBox(height: AppSpace.x16),
      AppButton(
        label: 'Simpan',
        large: true,
        onPressed: () {
          final int price = RupiahInputFormatter.parse(_price.text);
          if (_name.text.trim().isEmpty || price <= 0) return;
          Navigator.pop(context, ReceiptItem(name: _name.text.trim(), qty: widget.item.qty, price: price));
        },
      ),
    ]);
  }
}
