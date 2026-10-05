import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import '../utils/date_format.dart';
import 'pressable.dart';

/// `‹  Oktober 2026  ›`. Tidak bisa maju melewati bulan ini.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged, this.now});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final DateTime n = now ?? DateTime.now();
    final bool canNext = DateTime(month.year, month.month + 1).isBefore(DateTime(n.year, n.month + 1));
    Widget arrow(IconData icon, String label, VoidCallback? onTap) => Pressable(
          onTap: onTap,
          semanticLabel: label,
          child: SizedBox.square(
            dimension: AppSpace.touch,
            child: Icon(icon, color: onTap == null ? c.line2 : c.sub),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
      child: Row(
        children: [
          arrow(Icons.chevron_left, 'Bulan sebelumnya', () => onChanged(DateTime(month.year, month.month - 1))),
          Expanded(
            child: Text(
              DateFmt.month(month),
              textAlign: TextAlign.center,
              style: context.text.title,
            ),
          ),
          arrow(Icons.chevron_right, 'Bulan berikutnya', canNext ? () => onChanged(DateTime(month.year, month.month + 1)) : null),
        ],
      ),
    );
  }
}

/// Pil kecil `‹ Okt 2026 ›` di samping judul (desain Laporan).
class MonthPill extends StatelessWidget {
  const MonthPill({super.key, required this.month, required this.onChanged, this.now});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final DateTime n = now ?? DateTime.now();
    final bool canNext = DateTime(month.year, month.month + 1).isBefore(DateTime(n.year, n.month + 1));
    Widget arrow(IconData icon, String label, VoidCallback? onTap) => Pressable(
          onTap: onTap,
          semanticLabel: label,
          child: SizedBox.square(
            dimension: 32,
            child: Icon(icon, size: 18, color: onTap == null ? c.line2 : c.ink),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll, border: Border.all(color: c.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, 'Bulan sebelumnya', () => onChanged(DateTime(month.year, month.month - 1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
            child: Text(
              '${DateFmt.monthsShort[month.month - 1]} ${month.year}',
              style: context.text.title.copyWith(fontSize: 14),
            ),
          ),
          arrow(Icons.chevron_right, 'Bulan berikutnya', canNext ? () => onChanged(DateTime(month.year, month.month + 1)) : null),
        ],
      ),
    );
  }
}
