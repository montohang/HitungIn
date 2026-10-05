import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/security/app_gate.dart';
import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'pressable.dart';
import 'hi_icons.dart';

/// Tombol ikon persegi 44 dengan bingkai (kembali, filter — desain).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({super.key, required this.icon, required this.label, required this.onTap, this.filled});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Latar tanpa bingkai (mis. ✕ di Catat). Null = surface + garis.
  final Color? filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: AppSpace.touch,
          height: AppSpace.touch,
          decoration: BoxDecoration(
            color: filled ?? c.surface,
            borderRadius: AppRadius.smAll,
            border: filled == null ? Border.all(color: c.line) : null,
          ),
          child: Icon(icon, size: 20, color: c.ink),
        ),
      ),
    );
  }
}

/// Header layar turunan: ‹ kembali · judul di tengah · aksi opsional.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing, this.large = false});

  final String title;
  final Widget? trailing;

  /// Judul gaya display 22 (Riwayat) alih-alih 17/700.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return SizedBox(
      height: AppSpace.touch,
      child: Row(
        children: [
          SquareIconButton(
            icon: HiIcons.back,
            label: 'Kembali',
            onTap: () => context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: large ? t.screenTitle.copyWith(fontSize: 22) : t.title.copyWith(fontSize: 17),
            ),
          ),
          trailing ?? const SizedBox(width: AppSpace.touch),
        ],
      ),
    );
  }
}
