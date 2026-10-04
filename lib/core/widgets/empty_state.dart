import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/context_ext.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Tampilan saat daftar masih kosong.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x32, horizontal: AppSpace.x16),
      child: Column(
        children: [
          IconTile(icon: icon, size: 64),
          const SizedBox(height: AppSpace.x16),
          Text(title, style: t.section, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: AppSpace.x8),
            Text(body!, style: t.body.copyWith(color: context.colors.sub), textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpace.x16),
            AppButton(label: action!, variant: AppButtonVariant.soft, expand: false, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Judul seksi dengan aksi di kanan ("Lihat semua").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: t.section)),
          if (action != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSpace.touch),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(action!, style: t.label.copyWith(color: context.colors.accentText, fontSize: 14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
