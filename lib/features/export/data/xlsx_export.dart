import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/date_format.dart';
import '../../debts/data/debts_dao.dart';
import '../../goals/data/goals_dao.dart';
import 'export_report.dart';

/// Excel (.xlsx) P3g: sampai 13 sheet, hanya yang ada datanya. Nominal
/// berupa angka berformat Rupiah; baris judul dibekukan & diberi filter.
abstract final class XlsxExport {
  static final CellStyle _head = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#ECE9FF'),
    fontColorHex: ExcelColor.fromHexString('#17152B'),
  );
  static final CellStyle _rp = CellStyle(numberFormat: NumFormat.custom(formatCode: '"Rp"#,##0;-"Rp"#,##0'));
  static final CellStyle _rpBold = CellStyle(bold: true, numberFormat: NumFormat.custom(formatCode: '"Rp"#,##0;-"Rp"#,##0'));
  static final CellStyle _pct = CellStyle(numberFormat: NumFormat.custom(formatCode: '0%'));
  static final CellStyle _date = CellStyle(numberFormat: NumFormat.custom(formatCode: 'dd/mm/yyyy'));

  /// Nama sheet yang dibuat untuk [x] (urut).
  static List<String> sheetNames(ExportInput x) => [for (final s in _sheets(x)) s.name];

  static Uint8List build(ExportInput x) {
    final Excel book = Excel.createExcel();
    final String first = book.getDefaultSheet()!;
    final sheets = _sheets(x);
    for (final s in sheets) {
      final Sheet sheet = book[s.name];
      s.fill(sheet);
    }
    book.setDefaultSheet(sheets.first.name);
    book.delete(first);
    final List<int> bytes = book.encode()!;
    return _freezeAndFilter(Uint8List.fromList(bytes), {for (final s in sheets) s.name: s.filter});
  }

  // ---- penulisan baris ---------------------------------------------------

  static void _row(Sheet s, List<Object?> values, {CellStyle? style, bool header = false}) {
    final int r = s.maxRows;
    for (int i = 0; i < values.length; i++) {
      final Object? v = values[i];
      final (CellValue? cell, CellStyle? st) = switch (v) {
        null => (null, null),
        _Rp(:final int amount, :final bool bold) => (IntCellValue(amount), bold ? _rpBold : _rp),
        _Pct(:final double value) => (DoubleCellValue(value), _pct),
        DateTime d => (DateCellValue(year: d.year, month: d.month, day: d.day), _date),
        int n => (IntCellValue(n), null),
        double n => (DoubleCellValue(n), null),
        _ => (TextCellValue('$v'), null),
      };
      s.updateCell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r), cell,
          cellStyle: header ? _head : (style ?? st));
    }
  }

  static void _header(Sheet s, List<String> titles, List<double> widths) {
    _row(s, titles, header: true);
    for (int i = 0; i < widths.length; i++) {
      s.setColumnWidth(i, widths[i]);
    }
  }

  static String _monthName(DateTime m) => '${DateFmt.monthsShort[m.month - 1]} ${m.year}';

  // ---- sheet -------------------------------------------------------------

  static List<_SheetDef> _sheets(ExportInput x) {
    final ExportSummary sum = summarize(x);
    final out = <_SheetDef>[
      _SheetDef('Ringkasan', false, (s) {
        _header(s, ['HitungIn · Laporan keuangan', ''], [32, 22]);
        _row(s, ['Periode', x.periodLabel]);
        _row(s, ['Dompet', x.walletLabel]);
        _row(s, ['Dibuat', '${DateFmt.dayKey(x.createdAt)} ${DateFmt.time(x.createdAt)}']);
        _row(s, []);
        _row(s, ['Pemasukan', _Rp(sum.income)]);
        _row(s, ['Pengeluaran', _Rp(sum.expense)]);
        _row(s, ['Selisih', _Rp(sum.net, bold: true)], style: null);
        _row(s, ['Tingkat menabung', sum.savingRate == null ? '-' : _Pct(sum.savingRate!)]);
        _row(s, ['Rata-rata pengeluaran per hari', _Rp(sum.avgDaily)]);
        _row(s, ['Jumlah transaksi', sum.count]);
        _row(s, ['Kategori terbesar', sum.topCategory ?? '-']);
        _row(s, []);
        _row(s, ['Transfer antar-dompet dan utang-piutang tidak dihitung sebagai pemasukan/pengeluaran.']);
      }),
    ];
    if (x.txs.isNotEmpty) {
      out.add(_SheetDef('Transaksi', true, (s) {
        _header(s, ['Tanggal', 'Jam', 'Jenis', 'Kategori', 'Sub-kategori', 'Dompet', 'Ke dompet', 'Nominal', 'Catatan'],
            [12, 7, 14, 18, 16, 14, 14, 16, 32]);
        for (final d in x.txs.reversed) {
          _row(s, [
            d.tx.occurredAt,
            DateFmt.time(d.tx.occurredAt),
            d.tx.kind.label,
            d.category?.name ?? '',
            d.tx.sub,
            d.wallet.name,
            d.toWallet?.name ?? '',
            _Rp(signedAmount(d)),
            d.tx.note,
          ]);
        }
      }));
      out.add(_SheetDef('Bulanan', true, (s) {
        _header(s, ['Bulan', 'Pemasukan', 'Pengeluaran', 'Selisih', 'Tingkat menabung'], [12, 16, 16, 16, 16]);
        for (final m in monthly(x)) {
          _row(s, [
            _monthName(m.month),
            _Rp(m.income),
            _Rp(m.expense),
            _Rp(m.income - m.expense),
            m.income > 0 ? _Pct((m.income - m.expense) / m.income) : '-',
          ]);
        }
      }));
      final cats = expenseMatrix(x, (d) => d.category?.name ?? 'Tanpa kategori');
      if (cats.isNotEmpty) {
        out.add(_SheetDef('Per kategori', true, (s) {
          final int total = cats.fold(0, (a, c) => a + c.total);
          _header(s, ['Kategori', for (final m in x.months) _monthName(m), 'Total', 'Porsi'],
              [18, for (final _ in x.months) 13, 15, 9]);
          for (final c in cats) {
            _row(s, [c.name, for (final m in x.months) _Rp(c.perMonth[m] ?? 0), _Rp(c.total, bold: true), _Pct(total == 0 ? 0 : c.total / total)]);
          }
        }));
      }
      final subs = expenseMatrix(x, (d) => d.tx.sub.isEmpty ? null : '${d.category?.name ?? '-'} › ${d.tx.sub}');
      if (subs.isNotEmpty) {
        out.add(_SheetDef('Sub-kategori', true, (s) {
          _header(s, ['Sub-kategori', for (final m in x.months) _monthName(m), 'Total'], [28, for (final _ in x.months) 13, 15]);
          for (final c in subs) {
            _row(s, [c.name, for (final m in x.months) _Rp(c.perMonth[m] ?? 0), _Rp(c.total, bold: true)]);
          }
        }));
      }
    }
    if (x.wallets.isNotEmpty) {
      out.add(_SheetDef('Per dompet', true, (s) {
        _header(s, ['Dompet', 'Masuk', 'Keluar', 'Transfer masuk', 'Transfer keluar', 'Saldo akhir periode'], [16, 15, 15, 15, 15, 18]);
        for (final w in perWallet(x)) {
          _row(s, [w.wallet.name, _Rp(w.inflow), _Rp(w.outflow), _Rp(w.transferIn), _Rp(w.transferOut), _Rp(w.balance, bold: true)]);
        }
      }));
    }
    final days = daily(x);
    if (days.isNotEmpty) {
      out.add(_SheetDef('Harian', true, (s) {
        _header(s, ['Tanggal', 'Hari', 'Pengeluaran', 'Jumlah transaksi'], [12, 10, 15, 16]);
        const List<String> names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        for (final d in days) {
          _row(s, [d.day, names[d.day.weekday - 1], _Rp(d.expense), d.count]);
        }
      }));
    }
    if (x.budgets.isNotEmpty) {
      out.add(_SheetDef('Budget', true, (s) {
        _header(s, ['Bulan', 'Kategori', 'Batas', 'Terpakai', 'Sisa', 'Pemakaian'], [12, 20, 15, 15, 15, 11]);
        for (final e in x.budgets.entries) {
          for (final b in e.value) {
            final int lim = b.budget.limitAmount;
            _row(s, [
              _monthName(e.key),
              b.category?.name ?? 'Total',
              _Rp(lim),
              _Rp(b.spent),
              _Rp(lim - b.spent),
              _Pct(lim == 0 ? 0 : b.spent / lim),
            ]);
          }
        }
      }));
    }
    if (x.debts.isNotEmpty) {
      out.add(_SheetDef('Utang-piutang', true, (s) {
        _header(s, ['Nama', 'Arah', 'Tanggal', 'Total', 'Sudah dibayar', 'Sisa', 'Jatuh tempo', 'Status', 'Catatan'],
            [18, 10, 12, 15, 15, 15, 12, 10, 26]);
        for (final d in x.debts) {
          _row(s, [
            d.debt.name,
            d.debt.direction == DebtDirection.piutang ? 'Piutang' : 'Utang',
            d.debt.occurredAt,
            _Rp(d.debt.amount),
            _Rp(d.paid),
            _Rp(d.left),
            d.debt.dueDate,
            d.left <= 0 ? 'Lunas' : 'Berjalan',
            d.debt.note,
          ]);
        }
      }));
    }
    if (x.bills.isNotEmpty) {
      out.add(_SheetDef('Tagihan & cicilan', true, (s) {
        _header(s, ['Nama', 'Nominal', 'Jatuh tempo berikut', 'Pengulangan', 'Cicilan ke', 'Dari', 'Sisa cicilan'], [20, 15, 18, 13, 11, 8, 15]);
        for (final b in x.bills) {
          final int? total = b.installmentTotal;
          _row(s, [
            b.name,
            _Rp(b.amount),
            b.nextDue,
            b.repeat.label,
            total == null ? null : b.installmentPaid + 1,
            total,
            total == null ? null : _Rp((total - b.installmentPaid) * b.amount),
          ]);
        }
      }));
    }
    if (x.goals.isNotEmpty) {
      out.add(_SheetDef('Target tabungan', true, (s) {
        _header(s, ['Target', 'Nominal target', 'Terkumpul', 'Progres', 'Tenggat', 'Perkiraan'], [20, 15, 15, 10, 12, 36]);
        for (final g in x.goals) {
          _row(s, [
            g.goal.name,
            _Rp(g.goal.target),
            _Rp(g.saved),
            _Pct(g.goal.target == 0 ? 0 : (g.saved / g.goal.target).clamp(0, 1).toDouble()),
            g.goal.dueDate,
            goalLine(g, x.createdAt),
          ]);
        }
      }));
    }
    if (x.splits.isNotEmpty) {
      out.add(_SheetDef('Patungan', true, (s) {
        _header(s, ['Tanggal', 'Acara', 'Total', 'Peserta', 'Bagian', 'Status'], [12, 20, 15, 18, 15, 12]);
        final Map<int, DebtWithPayments> debtById = {for (final d in x.debts) d.debt.id: d};
        for (final sp in x.splits) {
          for (final m in sp.members) {
            final DebtWithPayments? debt = m.debtId == null ? null : debtById[m.debtId];
            _row(s, [
              sp.split.occurredAt,
              sp.split.title,
              _Rp(sp.split.total),
              m.isMe ? '${m.name} (aku)' : m.name,
              _Rp(m.share),
              m.isMe || m.payer
                  ? (m.payer ? 'Membayar' : '-')
                  : debt == null
                      ? '-'
                      : debt.left <= 0
                          ? 'Lunas'
                          : 'Belum lunas',
            ]);
          }
        }
      }));
    }
    if (x.recurring.isNotEmpty) {
      out.add(_SheetDef('Transaksi berulang', true, (s) {
        _header(s, ['Catatan', 'Jenis', 'Nominal', 'Pengulangan', 'Jadwal berikut', 'Dompet', 'Aktif'], [22, 14, 15, 13, 15, 14, 8]);
        for (final r in x.recurring) {
          _row(s, [
            r.note,
            r.kind.label,
            _Rp(r.amount),
            r.repeat.label,
            r.nextRun,
            x.walletNames[r.walletId] ?? '',
            r.active ? 'Ya' : 'Tidak',
          ]);
        }
      }));
    }
    return out;
  }

  // ---- bekukan baris judul & filter otomatis (tidak didukung paket excel) ----

  static Uint8List _freezeAndFilter(Uint8List xlsx, Map<String, bool> filterBySheet) {
    final Archive zip = ZipDecoder().decodeBytes(xlsx);
    // workbook.xml: urutan sheet → nama; rels: rId → berkas sheet.
    final String wb = utf8.decode(zip.findFile('xl/workbook.xml')!.content as List<int>);
    final String rels = utf8.decode(zip.findFile('xl/_rels/workbook.xml.rels')!.content as List<int>);
    final Map<String, String> target = {
      for (final m in RegExp(r'<Relationship[^>]*Id="(\w+)"[^>]*Target="([^"]+)"').allMatches(rels)) m[1]!: m[2]!,
      for (final m in RegExp(r'<Relationship[^>]*Target="([^"]+)"[^>]*Id="(\w+)"').allMatches(rels)) m[2]!: m[1]!,
    };
    final Map<String, String> fileToName = {};
    for (final m in RegExp(r'<sheet [^>]*name="([^"]+)"[^>]*r:id="(\w+)"').allMatches(wb)) {
      final String? t = target[m[2]!];
      if (t != null) fileToName['xl/${t.replaceFirst(RegExp(r'^/?xl/'), '')}'] = _unescape(m[1]!);
    }
    final Archive out = Archive();
    for (final ArchiveFile f in zip.files) {
      final String? name = fileToName[f.name];
      if (name == null || !f.isFile) {
        out.addFile(f);
        continue;
      }
      String xml = utf8.decode(f.content as List<int>);
      xml = _freeze(xml);
      if (filterBySheet[name] ?? false) xml = _filter(xml);
      final List<int> data = utf8.encode(xml);
      out.addFile(ArchiveFile(f.name, data.length, data));
    }
    return Uint8List.fromList(ZipEncoder().encode(out)!);
  }

  static String _unescape(String s) => s.replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>');

  static const String _pane = '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>';

  static String _freeze(String xml) {
    final RegExp selfClosing = RegExp(r'<sheetView([^>]*)/>');
    if (selfClosing.hasMatch(xml)) return xml.replaceFirstMapped(selfClosing, (m) => '<sheetView${m[1]}>$_pane</sheetView>');
    final RegExp open = RegExp(r'<sheetView([^>]*)>');
    if (open.hasMatch(xml)) return xml.replaceFirstMapped(open, (m) => '<sheetView${m[1]}>$_pane');
    // Tanpa sheetViews: sisipkan sebelum sheetFormatPr / cols / sheetData.
    final int at = [xml.indexOf('<sheetFormatPr'), xml.indexOf('<cols'), xml.indexOf('<sheetData')].where((i) => i >= 0).reduce((a, b) => a < b ? a : b);
    return '${xml.substring(0, at)}<sheetViews><sheetView workbookViewId="0">$_pane</sheetView></sheetViews>${xml.substring(at)}';
  }

  static String _filter(String xml) {
    final Iterable<RegExpMatch> cells = RegExp(r'<c r="([A-Z]+)(\d+)"').allMatches(xml);
    if (cells.isEmpty) return xml;
    String lastCol = 'A';
    int lastRow = 1;
    for (final m in cells) {
      final String col = m[1]!;
      if (col.length > lastCol.length || (col.length == lastCol.length && col.compareTo(lastCol) > 0)) lastCol = col;
      final int row = int.parse(m[2]!);
      if (row > lastRow) lastRow = row;
    }
    final String filter = '<autoFilter ref="A1:$lastCol$lastRow"/>';
    return xml.replaceFirst('</sheetData>', '</sheetData>$filter');
  }
}

/// Nominal Rupiah (ditulis sebagai angka berformat Rp).
class _Rp {
  const _Rp(this.amount, {this.bold = false});
  final int amount;
  final bool bold;
}

class _Pct {
  const _Pct(this.value);
  final double value;
}

class _SheetDef {
  _SheetDef(this.name, this.filter, this.fill);
  final String name;

  /// Baris pertama = judul kolom → filter otomatis.
  final bool filter;
  final void Function(Sheet) fill;
}
