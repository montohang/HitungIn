import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/hi_icons.dart';

/// Tombol keypad nominal (desain Catat): 1–9, 000, 0, ⌫.
const List<String> keypadKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '⌫'];

/// Batas digit nominal (Rp99.999.999.999).
const int keypadMaxDigits = 11;

/// Nominal baru setelah satu tombol keypad ditekan. Nol di depan dibuang,
/// panjang dibatasi [keypadMaxDigits].
int applyKeypad(int amount, String key) {
  final String digits = amount == 0 ? '' : '$amount';
  if (key == '⌫') {
    return digits.length <= 1 ? 0 : int.parse(digits.substring(0, digits.length - 1));
  }
  final String next = digits + key;
  if (next.length > keypadMaxDigits) return amount;
  return int.tryParse(next) ?? 0;
}

/// Keypad 3×4 di bawah layar Catat. Tinggi tombol 52, jarak 8.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 4; row++) ...[
          if (row > 0) const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              for (int col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: AppSpace.x8),
                Expanded(child: _Key(label: keypadKeys[row * 3 + col], color: c.bg, onKey: onKey)),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.color, required this.onKey});

  final String label;
  final Color color;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final bool back = label == '⌫';
    return Pressable(
      key: Key('key-$label'),
      semanticLabel: back ? 'Hapus angka' : label,
      onTap: () {
        HapticFeedback.selectionClick();
        onKey(label);
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.mdAll),
        child: back
            ? Icon(HiIcons.backspace, size: 22, color: context.colors.ink)
            : Text(label, style: context.text.title.copyWith(fontSize: 22, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
