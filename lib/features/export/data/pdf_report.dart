import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/db/app_database.dart';
import '../../../core/utils/date_format.dart';
import '../../budget/data/budgets_dao.dart';
import '../../debts/data/debts_dao.dart';
import '../../goals/data/goals_dao.dart';
import '../../networth/data/net_worth.dart';
import 'export_report.dart';

/// Font PDF (berkas TTF Plus Jakarta Sans & Bricolage dari aset aplikasi).
typedef PdfFonts = ({ByteData regular, ByteData bold, ByteData display});

/// PDF laporan P3g: ringkasan, posisi keuangan, lampiran transaksi.
/// Halaman selalu terang (kertas), warna aksen mengikuti tema.
abstract final class PdfReport {
  static const PdfColor _ink = PdfColor.fromInt(0xFF17152B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6782);
  static const PdfColor _faint = PdfColor.fromInt(0xFFA5A0C0);
  static const PdfColor _line = PdfColor.fromInt(0xFFDCD9E8);
  static const PdfColor _line2 = PdfColor.fromInt(0xFFF1F0F6);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF7F6FB);
  static const PdfColor _track = PdfColor.fromInt(0xFFEFEDF5);
  static const PdfColor _good = PdfColor.fromInt(0xFF157F5B);
  static const PdfColor _goodSoft = PdfColor.fromInt(0xFFE6F4EE);
  static const PdfColor _goodInk = PdfColor.fromInt(0xFF11694B);
  static const PdfColor _warn = PdfColor.fromInt(0xFFB45309);
  static const PdfColor _danger = PdfColor.fromInt(0xFFB42318);
  static const PdfColor _gold = PdfColor.fromInt(0xFFF2C14E);

  static String rp(int v) {
    final String digits = v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '${v < 0 ? '-' : ''}Rp$digits';
  }

  static String _short(int v) {
    final int a = v.abs();
    final String sign = v < 0 ? '-' : '';
    if (a >= 1000000) {
      final double jt = a / 1000000;
      final String s = (jt == jt.roundToDouble() ? jt.toStringAsFixed(0) : jt.toStringAsFixed(jt >= 10 ? 1 : 2))
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '')
          .replaceAll('.', ',');
      return '${sign}Rp$s jt';
    }
    return '$sign${rp(a)}';
  }

  static Future<Uint8List> build(
    ExportInput x, {
    required bool attachment,
    required PdfColor accent,
    PdfFonts? fonts,
  }) async {
    final pw.ThemeData theme = fonts == null
        ? pw.ThemeData.base()
        : pw.ThemeData.withFont(base: pw.Font.ttf(fonts.regular), bold: pw.Font.ttf(fonts.bold));
    final pw.Font? display = fonts == null ? null : pw.Font.ttf(fonts.display);
    final pw.Document doc = pw.Document(title: 'Laporan keuangan ${x.periodLabel}', author: 'HitungIn', creator: 'HitungIn');
    final ExportSummary sum = summarize(x);
    final String made = '${x.createdAt.day} ${DateFmt.monthsShort[x.createdAt.month - 1]} ${x.createdAt.year}, '
        '${DateFmt.time(x.createdAt)}';

    pw.Widget title(String t) => pw.Text(t, style: pw.TextStyle(font: display, fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink));
    pw.Widget section(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
        );

    doc.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
      maxPages: 400,
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Dibuat di HP dengan HitungIn · $made', style: const pw.TextStyle(fontSize: 7, color: _faint)),
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 7, color: _faint)),
        ]),
      ),
      build: (ctx) => [
        // ---- Halaman 1: Ringkasan ----
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            _logo(accent),
            pw.SizedBox(width: 8),
            title('Laporan keuangan'),
          ]),
          pw.Text('${x.periodLabel} · ${x.walletLabel}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ]),
        pw.SizedBox(height: 14),
        pw.Row(children: [
          _stat('Pemasukan', _short(sum.income), _good),
          pw.SizedBox(width: 8),
          _stat('Pengeluaran', _short(sum.expense), _ink),
          pw.SizedBox(width: 8),
          _stat('Sisa', _short(sum.net), accent),
        ]),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: const pw.BoxDecoration(color: _goodSoft, borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(
              sum.savingRate == null ? 'Belum ada pemasukan' : 'Tingkat menabung ${(sum.savingRate! * 100).round()}%',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _goodInk),
            ),
            pw.Text('Rata-rata pengeluaran ${_short(sum.avgDaily)}/hari · ${sum.count} transaksi',
                style: const pw.TextStyle(fontSize: 8, color: _goodInk)),
          ]),
        ),
        ..._categories(x, sum, accent, section),
        ..._budget(x, section),
        // ---- Halaman 2: Posisi keuangan ----
        pw.NewPage(),
        title('Posisi keuangan · ${_endLabel(x)}'),
        section('Saldo dompet'),
        _table(
          ['Dompet', 'Jenis', 'Saldo'],
          [
            for (final w in perWallet(x)) [w.wallet.name, w.wallet.type.label, rp(w.balance)],
            ['Total', '', rp(perWallet(x).fold(0, (s, w) => s + w.balance))],
          ],
          numeric: {2},
          boldLast: true,
        ),
        ..._netWorth(x, accent),
        ..._debts(x, section),
        ..._bills(x, section),
        ..._goals(x, section),
        // ---- Lampiran ----
        if (attachment && x.txs.isNotEmpty) ...[
          pw.NewPage(),
          title('Lampiran · Transaksi ${x.periodLabel}'),
          pw.SizedBox(height: 8),
          _table(
            ['Tanggal', 'Keterangan', 'Kategori', 'Dompet', 'Nominal'],
            [
              for (final d in x.txs)
                [
                  '${d.tx.occurredAt.day} ${DateFmt.monthsShort[d.tx.occurredAt.month - 1]}',
                  d.tx.note.isEmpty ? (d.tx.sub.isEmpty ? d.tx.kind.label : d.tx.sub) : d.tx.note,
                  d.tx.kind == TxKind.transfer ? 'Transfer' : (d.category?.name ?? d.tx.kind.label),
                  d.toWallet == null ? d.wallet.name : '${d.wallet.name} > ${d.toWallet!.name}',
                  d.tx.kind == TxKind.transfer ? rp(d.tx.amount) : '${signedAmount(d) > 0 ? '+' : ''}${rp(signedAmount(d))}',
                ],
            ],
            numeric: {4},
            flex: const [12, 30, 20, 18, 16],
          ),
        ],
      ],
    ));
    return doc.save();
  }

  static String _endLabel(ExportInput x) {
    final DateTime last = x.range.to.subtract(const Duration(days: 1));
    final DateTime d = last.isAfter(x.createdAt) ? x.createdAt : last;
    return '${d.day} ${DateFmt.monthsShort[d.month - 1]} ${d.year}';
  }

  static pw.Widget _logo(PdfColor accent) => pw.Container(
        width: 18,
        height: 18,
        decoration: pw.BoxDecoration(color: accent, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4.5))),
        child: pw.Stack(alignment: pw.Alignment.center, children: [
          pw.Positioned(left: 4.5, top: 4, child: pw.Container(width: 2.4, height: 10, decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.2))))),
          pw.Positioned(right: 4.5, top: 4, child: pw.Container(width: 2.4, height: 10, decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.2))))),
          pw.Container(width: 5.4, height: 5.4, decoration: const pw.BoxDecoration(color: _gold, shape: pw.BoxShape.circle)),
        ]),
      );

  static pw.Widget _stat(String label, String value, PdfColor color) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(9),
          decoration: const pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          ]),
        ),
      );

  static pw.Widget _bar(double ratio, PdfColor color, {double height = 6}) => pw.Container(
        height: height,
        decoration: pw.BoxDecoration(color: _track, borderRadius: pw.BorderRadius.all(pw.Radius.circular(height / 2))),
        child: pw.Row(children: [
          if (ratio > 0)
            pw.Expanded(
              flex: (ratio.clamp(0, 1) * 1000).round().clamp(1, 1000),
              child: pw.Container(decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.all(pw.Radius.circular(height / 2)))),
            ),
          if (ratio < 1) pw.Expanded(flex: ((1 - ratio.clamp(0, 1)) * 1000).round().clamp(1, 1000), child: pw.SizedBox()),
        ]),
      );

  static List<pw.Widget> _categories(ExportInput x, ExportSummary sum, PdfColor accent, pw.Widget Function(String) section) {
    final rows = expenseMatrix(x, (d) => d.category?.name ?? 'Tanpa kategori').take(5).toList();
    if (rows.isEmpty) return const [];
    final int max = rows.first.total;
    return [
      section('Pengeluaran per kategori'),
      for (final r in rows)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(children: [
            pw.SizedBox(width: 96, child: pw.Text(r.name, style: const pw.TextStyle(fontSize: 8.5, color: _ink))),
            pw.Expanded(child: _bar(max == 0 ? 0 : r.total / max, accent)),
            pw.SizedBox(
              width: 110,
              child: pw.Text('${rp(r.total)} · ${sum.expense == 0 ? 0 : (r.total * 100 / sum.expense).round()}%',
                  textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
            ),
          ]),
        ),
    ];
  }

  static List<pw.Widget> _budget(ExportInput x, pw.Widget Function(String) section) {
    if (x.budgets.isEmpty) return const [];
    final MapEntry<DateTime, List<BudgetProgress>> last = x.budgets.entries.last;
    final List<BudgetProgress> rows = [for (final b in last.value) if (b.category != null) b];
    if (rows.isEmpty) return const [];
    return [
      section('Budget vs realisasi · ${DateFmt.month(last.key)}'),
      _table(
        ['Kategori', 'Batas', 'Terpakai', 'Sisa', '%'],
        [
          for (final b in rows)
            [
              b.category!.name,
              rp(b.budget.limitAmount),
              rp(b.spent),
              rp(b.budget.limitAmount - b.spent),
              '${b.budget.limitAmount == 0 ? 0 : (b.spent * 100 / b.budget.limitAmount).round()}%',
            ],
        ],
        numeric: {1, 2, 3, 4},
        colorOf: (row, col) {
          if (col != 4) return null;
          final b = rows[row];
          final double r = b.budget.limitAmount == 0 ? 0 : b.spent / b.budget.limitAmount;
          return r > 1 ? _danger : r >= 0.8 ? _warn : null;
        },
      ),
    ];
  }

  static List<pw.Widget> _netWorth(ExportInput x, PdfColor accent) {
    final NetWorth? w = x.netWorth;
    if (w == null) return const [];
    final List<String> manual = {for (final l in w.assets) if (l.item != null) l.group!.label.toLowerCase()}.toList();
    return [
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
        child: pw.Row(children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Kekayaan bersih', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
              pw.Text(
                'Aset ${rp(w.totalAssets)} - kewajiban ${rp(w.totalLiabilities)}'
                '${manual.isEmpty ? '' : ' · ${manual.join(', ')} diisi sendiri'}',
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ]),
          ),
          pw.SizedBox(width: 8),
          pw.Text(rp(w.net), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accent)),
        ]),
      ),
    ];
  }

  static List<pw.Widget> _debts(ExportInput x, pw.Widget Function(String) section) {
    final List<DebtWithPayments> open = [for (final d in x.debts) if (d.left > 0) d];
    if (open.isEmpty) return const [];
    return [
      section('Utang-piutang berjalan'),
      _table(
        ['Nama', 'Arah', 'Sisa', 'Jatuh tempo'],
        [
          for (final d in open)
            [
              d.debt.name,
              d.debt.direction == DebtDirection.piutang ? 'Piutang' : 'Utang',
              rp(d.left),
              d.debt.dueDate == null ? '-' : '${d.debt.dueDate!.day} ${DateFmt.monthsShort[d.debt.dueDate!.month - 1]}',
            ],
        ],
        numeric: {2, 3},
      ),
    ];
  }

  static List<pw.Widget> _bills(ExportInput x, pw.Widget Function(String) section) {
    final DateTime until = x.createdAt.add(const Duration(days: 31));
    final List<Bill> soon = [for (final b in x.bills) if (b.nextDue.isBefore(until)) b]..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    if (soon.isEmpty) return const [];
    return [
      section('Tagihan & cicilan sebulan ke depan'),
      _table(
        ['Tagihan', 'Nominal', 'Jatuh tempo', 'Cicilan'],
        [
          for (final b in soon)
            [
              b.name,
              rp(b.amount),
              '${b.nextDue.day} ${DateFmt.monthsShort[b.nextDue.month - 1]}',
              b.installmentTotal == null ? '-' : '${b.installmentPaid + 1} / ${b.installmentTotal}',
            ],
        ],
        numeric: {1, 2, 3},
      ),
    ];
  }

  static List<pw.Widget> _goals(ExportInput x, pw.Widget Function(String) section) {
    if (x.goals.isEmpty) return const [];
    return [
      section('Target tabungan'),
      for (final GoalWithDeposits g in x.goals)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Row(children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(g.goal.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
                pw.Text('${rp(g.saved)} dari ${rp(g.goal.target)} · ${goalLine(g, x.createdAt)}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              ]),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(width: 140, child: _bar(g.goal.target == 0 ? 0 : g.saved / g.goal.target, _good, height: 7)),
          ]),
        ),
    ];
  }

  static pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Set<int> numeric = const {},
    bool boldLast = false,
    List<int>? flex,
    PdfColor? Function(int row, int col)? colorOf,
  }) {
    pw.Widget cell(String s, int col, {bool head = false, bool bold = false, PdfColor? color}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          child: pw.Text(
            s,
            textAlign: numeric.contains(col) ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: head || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: head ? _muted : (color ?? _ink),
            ),
          ),
        );
    return pw.Table(
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: pw.FlexColumnWidth((flex?[i] ?? 1).toDouble()),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line))),
          children: [for (int i = 0; i < headers.length; i++) cell(headers[i], i, head: true)],
        ),
        for (int r = 0; r < rows.length; r++)
          pw.TableRow(
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line2))),
            children: [
              for (int i = 0; i < rows[r].length; i++)
                cell(rows[r][i], i, bold: boldLast && r == rows.length - 1, color: colorOf?.call(r, i)),
            ],
          ),
      ],
    );
  }
}
