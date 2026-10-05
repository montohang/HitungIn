import 'package:flutter/material.dart';

import 'context_ext.dart';

/// Palet warna kategori & dompet (Claude Design › Kategori): indeks disimpan
/// di database (`color`). 0 = aksen tema, 7 = abu.
abstract final class AppPalette {
  static const List<(String name, Color? hex)> entries = [
    ('Aksen', null),
    ('Amber', Color(0xFFC98A1E)),
    ('Teal', Color(0xFF2E8F7F)),
    ('Biru', Color(0xFF3B78C4)),
    ('Mawar', Color(0xFFC2416C)),
    ('Hijau', Color(0xFF3F8F3A)),
    ('Lavender', Color(0xFF8B7CF0)),
    ('Abu', null),
  ];

  static int get length => entries.length;

  /// Warna penuh (ikon, batang). Di mode gelap sedikit dicerahkan supaya terbaca.
  static Color of(BuildContext context, int index) {
    final c = context.colors;
    final int i = index.clamp(0, entries.length - 1);
    final Color base = i == 0
        ? c.accent
        : i == entries.length - 1
            ? c.muted
            : entries[i].$2!;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return dark && i != 0 && i != entries.length - 1 ? Color.lerp(base, Colors.white, 0.18)! : base;
  }

  /// Warna ikon di atas latar lembut (aksen pakai accentText supaya kontras).
  static Color ink(BuildContext context, int index) => index <= 0 ? context.colors.accentText : of(context, index);

  /// Latar lembut wadah ikon (desain: warna + alpha 0x24; aksen pakai accentSoft).
  static Color soft(BuildContext context, int index) =>
      index <= 0 ? context.colors.accentSoft : of(context, index).withAlpha(0x2E);
}
