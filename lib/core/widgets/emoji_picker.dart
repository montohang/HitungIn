import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// Emoji pertama dari teks bebas, atau null bila bukan emoji/simbol
/// (huruf & angka biasa ditolak supaya ikon tidak berisi teks).
String? firstEmoji(String text) {
  final String t = text.trim();
  if (t.isEmpty) return null;
  final String first = t.characters.first;
  if (RegExp(r'^[\p{L}\p{N}\s\p{P}]+$', unicode: true).hasMatch(first)) return null;
  return first;
}

/// Grid emoji pilihan + kolom "Emoji lain" (P1-4).
class EmojiPicker extends StatefulWidget {
  const EmojiPicker({super.key, required this.selected, required this.accent, required this.onPick});

  /// Emoji yang sedang dipilih (tanpa awalan `e:`), atau null.
  final String? selected;
  final Color accent;
  final ValueChanged<String> onPick;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  final TextEditingController _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final String e in AppIcons.emojiChoices)
              Semantics(
                selected: e == widget.selected,
                child: Pressable(
                  onTap: () => widget.onPick(e),
                  semanticLabel: 'Emoji $e',
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e == widget.selected ? widget.accent.withAlpha(0x1F) : c.bg,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: e == widget.selected ? widget.accent : Colors.transparent, width: 2),
                    ),
                    child: Text(e, textScaler: TextScaler.noScaling, style: const TextStyle(fontSize: 20, height: 1)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.x8),
        TextField(
          key: const Key('emoji-lain'),
          controller: _other,
          style: t.item,
          decoration: const InputDecoration(labelText: 'Emoji lain', hintText: 'Ketik dari keyboard'),
          onChanged: (v) {
            final String? e = firstEmoji(v);
            if (e != null) widget.onPick(e);
          },
        ),
      ],
    );
  }
}
