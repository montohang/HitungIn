import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/pressable.dart';
import '../security/app_gate.dart';

/// Kerangka 4 tab + tombol Catat di tengah.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const List<(IconData, IconData, String)> _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Riwayat'),
    (Icons.insights_outlined, Icons.insights, 'Laporan'),
    (Icons.savings_outlined, Icons.savings, 'Budget'),
  ];

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(int i) {
      final (IconData icon, IconData active, String label) = _tabs[i];
      final bool selected = shell.currentIndex == i;
      final Color color = selected ? c.accentText : c.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: Pressable(
            onTap: () => _go(i),
            semanticLabel: label,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? active : icon, color: color, size: 24),
                  const SizedBox(height: AppSpace.x2),
                  Text(label, style: context.text.label.copyWith(color: color, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: AppSpace.x4),
            child: Row(
              children: [
                tab(0),
                tab(1),
                Pressable(
                  onTap: () => context.push(Routes.catat),
                  semanticLabel: 'Catat transaksi',
                  child: Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpace.x8),
                    decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.mdAll),
                    child: Icon(Icons.add, color: c.onAccent, size: 28),
                  ),
                ),
                tab(2),
                tab(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
