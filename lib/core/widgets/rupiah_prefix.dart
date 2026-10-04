import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';

/// Awalan "Rp" untuk kolom nominal: selalu terlihat, jarak sama dengan
/// desain (kiri 16, ke angka 4). Pakai lewat [InputDecoration.prefixIcon]
/// bersama [constraints].
class RupiahPrefix extends StatelessWidget {
  const RupiahPrefix({super.key});

  static const BoxConstraints constraints = BoxConstraints(minWidth: 0, minHeight: 0);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpace.x16, right: AppSpace.x4),
        child: Text('Rp', style: context.text.number.copyWith(color: context.colors.muted)),
      );
}
