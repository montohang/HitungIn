import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';

/// Membungkus elemen yang bisa diketuk: mengecil halus saat ditekan
/// (140 ms, skala 0,96 — kartu 0,98). Mati bila "kurangi gerakan" aktif.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = AppMotion.pressScale,
    this.semanticLabel,
    this.isButton = true,
  });

  /// Varian untuk kartu besar.
  const Pressable.card({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  })  : scale = AppMotion.pressScaleCard,
        isButton = true;

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;
  final bool isButton;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = context.reduceMotion;
    // container: tiap tombol jadi node aksesibilitas sendiri, tidak melebur
    // dengan teks di sebelahnya.
    return Semantics(
      container: true,
      button: widget.isButton,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down && !reduce ? widget.scale : 1,
          duration: reduce ? Duration.zero : AppMotion.press,
          curve: AppMotion.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
