import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/pressable.dart';
import '../pin_service.dart';

/// Isian PIN lengkap: judul, titik-titik, pesan, dan keypad angka.
/// Memanggil [onCompleted] saat 6 digit terisi; isian dikosongkan lagi
/// setelahnya. Bila [error] berubah menjadi tidak kosong, titik bergoyang.
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.error,
    this.enabled = true,
    this.busy = false,
    this.onBiometric,
  });

  final String title;
  final String? subtitle;
  final String? error;
  final bool enabled;

  /// Sedang memeriksa PIN (titik penuh, keypad nonaktif).
  final bool busy;
  final Future<void> Function(String pin) onCompleted;

  /// Tombol sidik jari di kiri bawah (null = tidak tampil).
  final VoidCallback? onBiometric;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> with SingleTickerProviderStateMixin {
  String _pin = '';
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(PinEntry old) {
    super.didUpdateWidget(old);
    if (widget.error != null && widget.error != old.error) {
      HapticFeedback.heavyImpact();
      if (!context.reduceMotion) _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  bool get _active => widget.enabled && !widget.busy;

  Future<void> _tap(String digit) async {
    if (!_active || _pin.length >= PinService.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
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
    final c = context.colors;
    final t = context.text;
    final int filled = widget.busy ? PinService.pinLength : _pin.length;
    return Column(
      children: [
        Text(widget.title, style: t.screenTitle, textAlign: TextAlign.center),
        const SizedBox(height: AppSpace.x8),
        SizedBox(
          height: 44,
          child: Text(
            widget.error ?? widget.subtitle ?? '',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: widget.error != null ? c.danger : c.muted),
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value), 0),
            child: child,
          ),
          child: Semantics(
            label: '$filled dari ${PinService.pinLength} digit PIN terisi',
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < PinService.pinLength; i++)
                  AnimatedContainer(
                    duration: context.reduceMotion ? Duration.zero : AppMotion.press,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpace.x8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled ? (widget.error != null ? c.danger : c.accent) : Colors.transparent,
                      border: Border.all(color: i < filled ? Colors.transparent : c.line2, width: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x32),
        _Keypad(
          enabled: _active,
          onDigit: _tap,
          onBackspace: _backspace,
          onBiometric: widget.onBiometric,
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.enabled, required this.onDigit, required this.onBackspace, this.onBiometric});

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget digit(String d) => _Key(
          label: d,
          onTap: enabled ? () => onDigit(d) : null,
          child: Text(d, style: context.text.amountL.copyWith(fontWeight: FontWeight.w600)),
        );
    Widget row(List<Widget> keys) =>
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: keys.map((k) => Expanded(child: k)).toList());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          row([digit('1'), digit('2'), digit('3')]),
          row([digit('4'), digit('5'), digit('6')]),
          row([digit('7'), digit('8'), digit('9')]),
          row([
            if (onBiometric != null)
              _Key(
                label: 'Buka dengan sidik jari',
                onTap: enabled ? onBiometric : null,
                filled: false,
                child: Icon(Icons.fingerprint, size: 30, color: c.accentText),
              )
            else
              const SizedBox.shrink(),
            digit('0'),
            _Key(
              label: 'Hapus satu digit',
              onTap: enabled ? onBackspace : null,
              filled: false,
              child: Icon(Icons.backspace_outlined, size: 24, color: c.sub),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.child, this.onTap, this.filled = true});

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpace.x8),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AspectRatio(
          aspectRatio: 1.35,
          child: Container(
            decoration: BoxDecoration(
              color: filled ? c.surface : Colors.transparent,
              borderRadius: AppRadius.mdAll,
              border: filled ? Border.all(color: c.line) : null,
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(child: child),
          ),
        ),
      ),
    );
  }
}
