import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'hi_icons.dart';

/// Tombol tambah mengambang: datar (tanpa bayangan berat di mode gelap),
/// radius 16 seperti tombol lain.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.label, required this.onPressed, this.icon = HiIcons.plus});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloatingActionButton.extended(
      backgroundColor: c.accent,
      foregroundColor: c.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: context.text.title.copyWith(color: c.onAccent)),
    );
  }
}
