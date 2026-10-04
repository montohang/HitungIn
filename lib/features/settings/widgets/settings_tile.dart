import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pressable.dart';

/// Satu baris di daftar pengaturan.
class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            size: 40,
            color: danger ? c.danger : null,
            background: danger ? c.dangerSoft : null,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.item.copyWith(color: danger ? c.danger : null)),
                if (subtitle != null) Text(subtitle!, style: t.caption.copyWith(color: c.muted)),
              ],
            ),
          ),
          if (trailing != null) trailing! else if (onTap != null) Icon(Icons.chevron_right, color: c.muted),
        ],
      ),
    );
    return onTap == null ? row : Pressable.card(onTap: onTap, semanticLabel: title, child: row);
  }
}

/// Kartu berisi beberapa [SettingsTile] dengan garis pemisah.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.x8),
              child: Text(title!, style: context.text.label.copyWith(color: c.muted)),
            ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
            child: Column(
              children: [
                for (final (int i, Widget w) in children.indexed) ...[
                  if (i > 0) Divider(color: c.line),
                  w,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lembar bawah standar dengan judul; menyesuaikan tinggi keyboard.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.screenTitle),
              const SizedBox(height: AppSpace.x16),
              builder(context),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Dialog konfirmasi standar. True bila pengguna menekan [confirm].
Future<bool> confirmDialog(BuildContext context, {required String title, required String body, required String confirm, bool danger = false}) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm, style: danger ? TextStyle(color: context.colors.danger) : null),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Label kecil di atas isian form.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.x8, top: AppSpace.x8),
        child: Text(text, style: context.text.label.copyWith(color: context.colors.muted)),
      );
}
