import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../settings/widgets/settings_tile.dart';
import '../data/backup_codec.dart';

/// Minta kata sandi cadangan lewat lembar bawah. Null bila dibatalkan.
Future<String?> askBackupPassword(BuildContext context, {required bool confirm}) => showAppSheet<String>(
      context,
      title: confirm ? 'Kata sandi cadangan' : 'Buka cadangan',
      builder: (_) => BackupPasswordForm(confirm: confirm),
    );

/// Isian kata sandi cadangan. [confirm] = buat baru (min. 8 karakter + ulangi);
/// selain itu hanya satu kolom untuk membuka cadangan.
class BackupPasswordForm extends StatefulWidget {
  const BackupPasswordForm({super.key, required this.confirm});

  final bool confirm;

  @override
  State<BackupPasswordForm> createState() => _BackupPasswordFormState();
}

class _BackupPasswordFormState extends State<BackupPasswordForm> {
  final TextEditingController _pw = TextEditingController();
  final TextEditingController _pw2 = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() {
    final String pw = _pw.text;
    if (widget.confirm) {
      if (pw.length < BackupCodec.minPasswordLength) {
        return setState(() => _error = 'Minimal ${BackupCodec.minPasswordLength} karakter.');
      }
      if (pw != _pw2.text) return setState(() => _error = 'Kata sandi tidak sama.');
    } else if (pw.isEmpty) {
      return setState(() => _error = 'Isi kata sandi.');
    }
    Navigator.pop(context, pw);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            tooltip: _show ? 'Sembunyikan' : 'Tampilkan',
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.confirm)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.x12),
            child: Text('Kata sandi ini dibutuhkan untuk memulihkan. Tidak bisa direset.', style: t.caption.copyWith(color: c.muted)),
          ),
        TextField(
          controller: _pw,
          autofocus: true,
          obscureText: !_show,
          enableSuggestions: false,
          autocorrect: false,
          style: t.item,
          decoration: deco('Kata sandi'),
          onSubmitted: widget.confirm ? null : (_) => _submit(),
        ),
        if (widget.confirm) ...[
          const SizedBox(height: AppSpace.x12),
          TextField(
            controller: _pw2,
            obscureText: !_show,
            enableSuggestions: false,
            autocorrect: false,
            style: t.item,
            decoration: deco('Ulangi kata sandi'),
            onSubmitted: (_) => _submit(),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: widget.confirm ? 'Buat cadangan' : 'Buka', large: true, onPressed: _submit),
      ],
    );
  }
}
