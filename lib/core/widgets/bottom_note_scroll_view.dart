import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Daftar bergulir dengan catatan kecil yang menempel di bawah layar
/// (desain: keterangan di dasar layar Dompet/Kategori). Bila isi lebih
/// panjang dari layar, catatan ikut tergulir di akhir daftar.
class BottomNoteScrollView extends StatelessWidget {
  const BottomNoteScrollView({super.key, required this.items, required this.footer});

  final List<Widget> items;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets p = AppSpace.screen;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(p.left, p.top, p.right, 0),
          sliver: SliverList.list(children: items),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(p.left, AppSpace.x16, p.right, p.bottom),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [footer]),
          ),
        ),
      ],
    );
  }
}
