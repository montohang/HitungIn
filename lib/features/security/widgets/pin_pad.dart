import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/pressable.dart';
import '../pin_service.dart';

/// Dua gaya PIN di desain: [light] untuk Buat/Ganti PIN (kartu terang/gelap
/// mengikuti tema), [onDark] untuk Layar Kunci (selalu di atas latar gelap).
enum PinPadStyle { light, onDark }

/// Warna tetap Layar Kunci (tidak mengikuti tema).
abstract final class LockColors {
  static const Color base = Color(0xFF1A1733);
  static const Color hint = Color(0xFFC9C4E6);
  static const Color danger = Color(0xFFF08A80);
  static const Color key = Color(0x10FFFFFF);
  static const Color dotEmpty = Color(0x55FFFFFF);
}

/// Titik-titik PIN. Bergoyang setiap [shakeKey] berubah (mis. PIN salah).
class PinDots extends StatefulWidget {
  const PinDots({super.key, required this.filled, required this.style, this.shakeKey});

  final int filled;
  final PinPadStyle style;
  final Object? shakeKey;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(PinDots old) {
    super.didUpdateWidget(old);
    if (widget.shakeKey != null && widget.shakeKey != old.shakeKey) {
      HapticFeedback.heavyImpact();
      if (!context.reduceMotion) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool dark = widget.style == PinPadStyle.onDark;
    final double size = dark ? 14 : 16;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(math.sin(_shake.value * math.pi * 5) * 8 * (1 - _shake.value), 0),
        child: child,
      ),
      child: Semantics(
        label: '${widget.filled} dari ${PinService.pinLength} digit PIN terisi',
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < PinService.pinLength; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.x16),
              AnimatedScale(
                scale: i < widget.filled ? 1.15 : 1,
                duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < widget.filled ? (dark ? Colors.white : c.accent) : Colors.transparent,
                    border: Border.all(
                      width: 2,
                      color: i < widget.filled ? (dark ? Colors.white : c.accent) : (dark ? LockColors.dotEmpty : c.line2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keypad angka 3 kolom. Kiri bawah: sidik jari (bila [onBiometric]) atau kosong.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.style,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
  });

  final PinPadStyle style;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool dark = style == PinPadStyle.onDark;
    final Color fg = dark ? Colors.white : c.ink;
    final Color keyBg = dark ? LockColors.key : c.bg;

    Widget key({required String label, required Widget child, VoidCallback? onTap, bool filled = true}) => Pressable(
          onTap: enabled ? onTap : null,
          semanticLabel: label,
          scale: 0.94,
          child: Container(
            height: dark ? 68 : 64,
            decoration: BoxDecoration(
              color: filled ? keyBg : Colors.transparent,
              borderRadius: dark ? AppRadius.pillAll : AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(child: child),
          ),
        );
    Widget digit(String d) => key(
          label: d,
          onTap: () => onDigit(d),
          child: Text(d, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 26, fontWeight: FontWeight.w600, color: fg)),
        );

    final List<Widget> keys = [
      for (final d in const ['1', '2', '3', '4', '5', '6', '7', '8', '9']) digit(d),
      if (onBiometric != null)
        key(
          label: 'Buka dengan sidik jari',
          onTap: onBiometric,
          filled: false,
          child: Icon(Icons.fingerprint, size: 32, color: dark ? Color.lerp(c.accent, Colors.white, 0.45) : c.accentText),
        )
      else
        const SizedBox.shrink(),
      digit('0'),
      key(
        label: 'Hapus satu digit',
        onTap: onBackspace,
        filled: false,
        child: Icon(Icons.backspace_outlined, size: 24, color: dark ? Colors.white : c.sub),
      ),
    ];

    final double hGap = dark ? AppSpace.x24 : AppSpace.x8;
    final double vGap = dark ? AppSpace.x12 : AppSpace.x8;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dark ? AppSpace.x16 : 0),
      child: Column(
        children: [
          for (int row = 0; row < 4; row++) ...[
            if (row > 0) SizedBox(height: vGap),
            Row(
              children: [
                for (int col = 0; col < 3; col++) ...[
                  if (col > 0) SizedBox(width: hGap),
                  Expanded(child: keys[row * 3 + col]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Isian PIN: menampung digit, menampilkan [PinDots] + keypad, dan memanggil
/// [onCompleted] saat 6 digit terisi (lalu dikosongkan lagi).
/// [header] tampil di atas titik, [footer] di bawah keypad; keypad menempel
/// ke bawah layar seperti di desain.
class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.style,
    required this.onCompleted,
    this.header,
    this.footer,
    this.error,
    this.enabled = true,
    this.busy = false,
    this.onBiometric,
    this.shakeKey,
  });

  final PinPadStyle style;
  final Future<void> Function(String pin) onCompleted;

  /// Titik bergoyang setiap nilai ini berubah (default: setiap [error] berubah).
  final Object? shakeKey;
  final Widget? header;
  final Widget? footer;
  final String? error;
  final bool enabled;
  final bool busy;
  final VoidCallback? onBiometric;

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  String _pin = '';

  bool get _active => widget.enabled && !widget.busy;

  Future<void> _digit(String d) async {
    if (!_active || _pin.length >= PinService.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (_pin.length == PinService.pinLength) {
      final String pin = _pin;
      await widget.onCompleted(pin);
      if (mounted) setState(() => _pin = '');
    }
  }

  void _backspace() {
    if (!_active || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.style == PinPadStyle.onDark;
    final Color errorColor = dark ? LockColors.danger : context.colors.danger;
    // Keypad menempel di bawah layar; di layar pendek seluruhnya bisa digulir.
    // (Column min-size + spaceBetween: tanpa IntrinsicHeight yang bisa salah ukur.)
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  if (widget.header != null) widget.header!,
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.x24, bottom: AppSpace.x8),
                    child: PinDots(
                      filled: widget.busy ? PinService.pinLength : _pin.length,
                      style: widget.style,
                      shakeKey: widget.shakeKey ?? widget.error,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        widget.error ?? '',
                        textAlign: TextAlign.center,
                        style: context.text.caption.copyWith(color: errorColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  PinKeypad(
                    style: widget.style,
                    enabled: _active,
                    onDigit: _digit,
                    onBackspace: _backspace,
                    onBiometric: widget.onBiometric,
                  ),
                  if (widget.footer != null) widget.footer!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isian PIN sederhana gaya terang (dipakai Ganti PIN): judul, keterangan,
/// titik, keypad.
class PinEntry extends StatelessWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.error,
    this.enabled = true,
    this.busy = false,
  });

  final String title;
  final String? subtitle;
  final String? error;
  final bool enabled;
  final bool busy;
  final Future<void> Function(String pin) onCompleted;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return PinField(
      style: PinPadStyle.light,
      error: error,
      enabled: enabled,
      busy: busy,
      onCompleted: onCompleted,
      header: Column(
        children: [
          const SizedBox(height: AppSpace.x24),
          Text(title, style: t.screenTitle.copyWith(fontSize: 28), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.x8),
            Text(subtitle!, textAlign: TextAlign.center, style: t.body.copyWith(color: context.colors.sub)),
          ],
        ],
      ),
    );
  }
}
