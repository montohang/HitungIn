import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/app_button.dart';
import '../security/app_gate.dart';
import '../security/auto_lock_setting.dart';
import 'data/settings_dao.dart';
import 'widgets/settings_tile.dart';

const String appVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String? current) async {
    final TextEditingController text = TextEditingController(text: current ?? '');
    await showAppSheet<void>(
      context,
      title: 'Nama panggilan',
      builder: (context) => Column(
        children: [
          TextField(
            controller: text,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            style: context.text.item,
            decoration: const InputDecoration(hintText: 'Boleh dikosongkan', counterText: ''),
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(
            label: 'Simpan',
            large: true,
            onPressed: () async {
              final dao = ref.read(appDatabaseProvider).settingsDao;
              final String v = text.text.trim();
              v.isEmpty ? await dao.remove(SettingKeys.userName) : await dao.write(SettingKeys.userName, v);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    text.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final String? name = ref.watch(userNameProvider).valueOrNull;
    final ThemeSettings theme = ref.watch(themeControllerProvider);
    final AutoLockDelay autoLock = ref.watch(autoLockProvider);
    final int wallets = ref.watch(walletBalancesProvider).valueOrNull?.length ?? 0;
    final bool hasPin = ref.watch(appGateProvider.select((g) => g.hasPin));

    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan', style: t.screenTitle)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8),
        children: [
          SettingsGroup(
            title: 'Profil',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Nama panggilan',
                subtitle: name ?? 'Belum diisi',
                onTap: () => _editName(context, ref, name),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Data',
            children: [
              SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Dompet',
                subtitle: '$wallets aktif',
                onTap: () => context.push(Routes.dompet),
              ),
              SettingsTile(icon: Icons.category_outlined, title: 'Kategori', onTap: () => context.push(Routes.kategori)),
              SettingsTile(icon: Icons.event_repeat_outlined, title: 'Tagihan', onTap: () => context.push(Routes.tagihan)),
            ],
          ),
          SettingsGroup(
            title: 'Tampilan',
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Tema & warna',
                subtitle: '${theme.mode.label} · ${theme.accent.label}',
                onTap: () => context.push(Routes.tampilan),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Keamanan & privasi',
            children: [
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'PIN & kunci',
                subtitle: hasPin ? 'Kunci otomatis: ${autoLock.label.toLowerCase()}' : 'PIN belum dibuat',
                onTap: () => context.push(Routes.keamanan),
              ),
              SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Cadangan & ekspor',
                subtitle: 'Berkas terenkripsi, CSV',
                onTap: () => context.push(Routes.cadangan),
              ),
            ],
          ),
          SettingsGroup(
            title: 'Tentang',
            children: [
              const SettingsTile(
                icon: Icons.info_outline,
                title: 'HitungIn $appVersion',
                subtitle: '100% offline · tanpa akun · data terenkripsi di HP ini',
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Lisensi sumber terbuka',
                onTap: () => showLicensePage(context: context, applicationName: 'HitungIn', applicationVersion: appVersion),
              ),
            ],
          ),
          Text(
            'HitungIn tidak mengirim data ke mana pun. Cadangan hanya dibuat saat kamu memintanya.',
            style: t.caption.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
