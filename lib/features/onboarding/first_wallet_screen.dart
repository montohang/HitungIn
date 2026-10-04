import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../security/app_gate.dart';
import 'pin_setup_screen.dart' show StepHeader;

/// Langkah terakhir onboarding: dompet awal beserta saldonya.
class FirstWalletScreen extends ConsumerStatefulWidget {
  const FirstWalletScreen({super.key});

  @override
  ConsumerState<FirstWalletScreen> createState() => _FirstWalletScreenState();
}

/// Saran cepat — nama dompet populer di Indonesia.
const List<(String, WalletType)> _suggestions = [
  ('Tunai', WalletType.tunai),
  ('BCA', WalletType.bank),
  ('BRI', WalletType.bank),
  ('Mandiri', WalletType.bank),
  ('BNI', WalletType.bank),
  ('GoPay', WalletType.ewallet),
  ('OVO', WalletType.ewallet),
  ('DANA', WalletType.ewallet),
  ('ShopeePay', WalletType.ewallet),
];

class _Draft {
  _Draft(String name, this.type) : name = TextEditingController(text: name);

  final TextEditingController name;
  final TextEditingController balance = TextEditingController();
  WalletType type;

  void dispose() {
    name.dispose();
    balance.dispose();
  }
}

class _FirstWalletScreenState extends ConsumerState<FirstWalletScreen> {
  final List<_Draft> _drafts = [_Draft('Tunai', WalletType.tunai)];
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  bool _has(String name) => _drafts.any((d) => d.name.text.trim().toLowerCase() == name.toLowerCase());

  void _add(String name, WalletType type) => setState(() {
        _drafts.add(_Draft(name, type));
        _error = null;
      });

  void _remove(_Draft d) => setState(() {
        _drafts.remove(d);
        d.dispose();
      });

  Future<void> _finish() async {
    final List<String> names = [for (final d in _drafts) d.name.text.trim()];
    if (names.isEmpty) {
      setState(() => _error = 'Tambahkan minimal satu dompet.');
      return;
    }
    if (names.any((n) => n.isEmpty)) {
      setState(() => _error = 'Setiap dompet perlu nama.');
      return;
    }
    if (names.map((n) => n.toLowerCase()).toSet().length != names.length) {
      setState(() => _error = 'Nama dompet tidak boleh sama.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final AppDatabase db = ref.read(appDatabaseProvider);
    await db.transaction(() async {
      for (final d in _drafts) {
        await db.walletsDao.add(
          name: d.name.text.trim(),
          type: d.type,
          initialBalance: RupiahInputFormatter.parse(d.balance.text),
        );
      }
    });
    // Router otomatis pindah ke beranda setelah onboarding selesai.
    await ref.read(appGateProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final remaining = [for (final s in _suggestions) if (!_has(s.$1)) s];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpace.screen.copyWith(top: AppSpace.x8),
                children: [
                  // PIN sudah tersimpan → tidak ada tombol kembali ke langkah 1.
                  const StepHeader(label: 'Langkah 2 dari 2'),
                  const SizedBox(height: AppSpace.x16),
                  Text('Uangmu ada di mana saja?', style: t.pageTitle.copyWith(height: 1.15)),
                  const SizedBox(height: AppSpace.x12),
                  Text(
                    'Isi saldo sekarang supaya totalnya pas. Bisa diubah atau ditambah kapan saja nanti.',
                    style: t.body.copyWith(color: c.sub),
                  ),
                  const SizedBox(height: AppSpace.x24),
                  for (final d in _drafts) ...[
                    _DraftCard(
                      key: ObjectKey(d),
                      draft: d,
                      onRemove: _drafts.length > 1 ? () => _remove(d) : null,
                      onTypeChanged: (type) => setState(() => d.type = type),
                    ),
                    const SizedBox(height: AppSpace.x12),
                  ],
                  const SizedBox(height: AppSpace.x8),
                  Text('Tambah dompet', style: t.label.copyWith(color: c.muted)),
                  const SizedBox(height: AppSpace.x8),
                  Wrap(
                    spacing: AppSpace.x8,
                    runSpacing: AppSpace.x8,
                    children: [
                      for (final (String name, WalletType type) in remaining)
                        AppChip(label: name, icon: AppIcons.of(_iconFor(type)), onTap: () => _add(name, type)),
                      AppChip(label: 'Lainnya', icon: Icons.add, onTap: () => _add('', WalletType.lainnya)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x24),
              child: Column(
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: t.caption.copyWith(color: c.danger)),
                    const SizedBox(height: AppSpace.x8),
                  ],
                  AppButton(label: 'Selesai', large: true, onPressed: _busy ? null : _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _iconFor(WalletType type) => switch (type) {
      WalletType.tunai => 'cash',
      WalletType.bank => 'bank',
      WalletType.ewallet => 'ewallet',
      WalletType.lainnya => 'wallet',
    };

class _DraftCard extends StatelessWidget {
  const _DraftCard({super.key, required this.draft, required this.onTypeChanged, this.onRemove});

  final _Draft draft;
  final ValueChanged<WalletType> onTypeChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.of(_iconFor(draft.type))),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: TextField(
                  controller: draft.name,
                  style: t.item,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Nama dompet', counterText: ''),
                ),
              ),
              if (onRemove != null)
                Pressable(
                  onTap: onRemove,
                  semanticLabel: 'Hapus dompet ${draft.name.text}',
                  child: SizedBox.square(
                    dimension: AppSpace.touch,
                    child: Icon(Icons.close, size: 20, color: c.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final type in WalletType.values)
                AppChip(label: type.label, selected: draft.type == type, onTap: () => onTypeChanged(type)),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          TextField(
            controller: draft.balance,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            style: t.number,
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints,
              labelText: 'Saldo sekarang',
            ),
          ),
        ],
      ),
    );
  }
}

