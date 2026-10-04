import 'dart:convert';
import 'dart:typed_data';

import '../../../core/db/app_database.dart';
import '../../transactions/data/transactions_dao.dart';

/// Ekspor transaksi ke CSV (UTF-8 + BOM supaya Excel membaca huruf dengan benar).
abstract final class CsvExport {
  static const List<String> header = ['Tanggal', 'Jam', 'Jenis', 'Kategori', 'Dompet', 'Ke dompet', 'Nominal', 'Catatan'];

  static String build(List<TxDetail> items) {
    final StringBuffer out = StringBuffer()..writeln(header.map(_cell).join(','));
    for (final d in items) {
      final DateTime at = d.tx.occurredAt;
      out.writeln([
        '${at.year}-${_two(at.month)}-${_two(at.day)}',
        '${_two(at.hour)}:${_two(at.minute)}',
        d.tx.kind.label,
        d.category?.name ?? '',
        d.wallet.name,
        d.toWallet?.name ?? '',
        // Bertanda supaya mudah dijumlah: pengeluaran negatif.
        '${d.tx.kind == TxKind.pengeluaran ? -d.tx.amount : d.tx.amount}',
        d.tx.note,
      ].map(_cell).join(','));
    }
    return out.toString();
  }

  static Uint8List bytes(List<TxDetail> items) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(build(items))]);

  /// Kutip bila perlu; cegah formula injection (=, +, -, @) di aplikasi spreadsheet.
  static String _cell(String v) {
    String s = v;
    final bool formula = s.isNotEmpty && ('=+@'.contains(s[0]) || (s[0] == '-' && int.tryParse(s) == null));
    if (formula) s = "'$s";
    if (s.contains(RegExp(r'[",\n\r]'))) return '"${s.replaceAll('"', '""')}"';
    return s;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
