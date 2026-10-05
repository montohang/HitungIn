import 'package:flutter/foundation.dart';
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
import '../../core/security/secure_store.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../core/db/app_database.dart';
import '../backup/data/backup_age.dart';
import '../bills/bills_screen.dart' show activeBillsProvider;
import '../bills/data/bill_due.dart';
import '../security/pin_service.dart';
import '../../core/widgets/app_chip.dart';
import '../ads/ads_service.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import 'data/settings_dao.dart';
import 'widgets/settings_tile.dart';
import '../../core/widgets/hi_icons.dart';

const String appVersion = '0.1.0';

final _adPrivacyRequiredProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!ref.watch(adsReadyProvider)) return false;
  return ref.watch(adsServiceProvider).privacyOptionsRequired();
});

final _biometricOnProvider =
    FutureProvider.autoDispose<bool>((ref) => ref.watch(pinServiceProvider).biometricEnabled());

/// Tab "Lainnya" (Claude Design › Lainnya): Premium, kelola data, privasi,
/// tampilan, tentang.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(BuildContext context, String? current) =>
      showAppSheet<void>(context, title: 'Nama panggilan', builder: (_) => _NameForm(current: current));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final String? name = ref.watch(userNameProvider).valueOrNull;
    final ThemeSettings theme = ref.watch(themeControllerProvider);
    final int wallets = ref.watch(walletBalancesProvider).valueOrNull?.length ?? 0;
    final int categories = ref.watch(activeCategoriesProvider).valueOrNull?.length ?? 0;
    final int dueSoon = [
      for (final b in ref.watch(activeBillsProvider).valueOrNull ?? const <Bill>[])
        if (billNeedsAttention(b, now)) b,
    ].length;
    final bool hasPin = ref.watch(appGateProvider.select((g) => g.hasPin));
    final bool bio = ref.watch(_biometricOnProvider).valueOrNull ?? false;
    final bool isPro = ref.watch(isProProvider);
    final bool adPrivacy = ref.watch(_adPrivacyRequiredProvider).valueOrNull ?? false;
    final ({String label, bool fresh}) backup = backupAge(ref.watch(lastBackupProvider).valueOrNull, now);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Text('Lainnya', style: t.pageTitle),
            const SizedBox(height: AppSpace.block),
            _PremiumCard(isPro: isPro, onTap: () => openPremium(context, isPro ? ProReason.umum : ProReason.iklan)),
            const SizedBox(height: AppSpace.x24),
            SettingsGroup(
              title: 'Kelola',
              children: [
                SettingsTile(
                  icon: HiIcons.history,
                  title: 'Riwayat transaksi',
                  onTap: () => context.push(Routes.riwayat),
                ),
                SettingsTile(
                  icon: HiIcons.user,
                  title: 'Nama panggilan',
                  value: name ?? 'Belum diisi',
                  onTap: () => _editName(context, name),
                ),
                SettingsTile(
                  icon: HiIcons.wallet,
                  title: 'Dompet',
                  value: '$wallets',
                  onTap: () => context.push(Routes.dompet),
                ),
                SettingsTile(
                  icon: HiIcons.grid,
                  title: 'Kategori',
                  value: '$categories',
                  onTap: () => context.push(Routes.kategori),
                ),
                SettingsTile(
                  icon: HiIcons.calendar,
                  title: 'Tagihan',
                  badge: dueSoon > 0 ? '$dueSoon segera' : null,
                  onTap: () => context.push(Routes.tagihan),
                ),
                SettingsTile(
                  icon: HiIcons.repeat,
                  title: 'Transaksi berulang',
                  badge: isPro ? null : 'PRO',
                  badgeTone: TileBadgeTone.pro,
                  onTap: () => context.push(Routes.berulang),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Data & privasi',
              children: [
                SettingsTile(
                  icon: HiIcons.shield,
                  title: 'Keamanan',
                  value: !hasPin ? 'Belum ada PIN' : (bio ? 'PIN + sidik jari' : 'PIN'),
                  onTap: () => context.push(Routes.keamanan),
                ),
                SettingsTile(
                  icon: HiIcons.download,
                  title: 'Backup & pulihkan',
                  badge: backup.label,
                  badgeTone: backup.fresh ? TileBadgeTone.good : TileBadgeTone.warn,
                  onTap: () => context.push(Routes.cadangan),
                ),
                SettingsTile(
                  icon: HiIcons.upload,
                  title: 'Export data',
                  value: 'CSV',
                  onTap: () => context.push(Routes.cadangan),
                ),
                if (!isPro && adPrivacy)
                  SettingsTile(
                    icon: HiIcons.shield,
                    title: 'Privasi iklan',
                    onTap: () => withAutoLockPaused(ref, () => ref.read(adsServiceProvider).showPrivacyOptions()),
                  ),
              ],
            ),
            SettingsGroup(
              title: 'Tampilan',
              children: [
                SettingsTile(
                  icon: HiIcons.palette,
                  title: 'Tema & warna',
                  value: theme.accent.label,
                  onTap: () => context.push(Routes.tampilan),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Tentang',
              children: [
                SettingsTile(
                  icon: HiIcons.document,
                  title: 'Lisensi sumber terbuka',
                  onTap: () =>
                      showLicensePage(context: context, applicationName: 'HitungIn', applicationVersion: appVersion),
                ),
                if (kDebugMode)
                  SettingsTile(
                    icon: HiIcons.palette,
                    title: 'Galeri desain',
                    value: 'debug',
                    onTap: () => context.push(Routes.gallery),
                  ),
              ],
            ),
            Text('HitungIn v$appVersion · dibuat di Indonesia',
                textAlign: TextAlign.center, style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpace.x4),
            Text('Tanpa akun. Tanpa server. Datamu milikmu.',
                textAlign: TextAlign.center, style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500)),
            if (!isPro) ...[
              const SizedBox(height: AppSpace.x4),
              Text(
                'Versi gratis menampilkan iklan Google AdMob (memakai ID iklan, bukan data keuanganmu).',
                textAlign: TextAlign.center,
                style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: AppSpace.x16),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPro, required this.onTap});

  final bool isPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable.card(
      onTap: onTap,
      semanticLabel: isPro ? 'HitungIn Pro aktif' : 'Upgrade ke Premium',
      child: Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A1733), Color.lerp(const Color(0xFF24203F), c.accent, 0.6)!],
          ),
        ),
        child: Row(
          children: [
            LogoMark(size: 48, background: Colors.white.withAlpha(0x22)),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPro ? 'HitungIn Pro aktif' : 'Upgrade ke Premium',
                      style: t.title.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpace.x2),
                  Text(isPro ? 'Terima kasih sudah mendukung HitungIn!' : 'Sekali bayar, tanpa iklan selamanya',
                      style: t.caption.copyWith(color: const Color(0xFFD8D5EE))),
                ],
              ),
            ),
            const AppBadge.pro(),
          ],
        ),
      ),
    );
  }
}

/// Form nama panggilan. Memegang controller sendiri supaya tidak dibuang
/// saat lembar bawah masih beranimasi menutup.
class _NameForm extends ConsumerStatefulWidget {
  const _NameForm({this.current});

  final String? current;

  @override
  ConsumerState<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends ConsumerState<_NameForm> {
  late final TextEditingController _text = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final dao = ref.read(appDatabaseProvider).settingsDao;
    final String v = _text.text.trim();
    v.isEmpty ? await dao.remove(SettingKeys.userName) : await dao.write(SettingKeys.userName, v);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            style: context.text.item,
            decoration: const InputDecoration(hintText: 'Boleh dikosongkan', counterText: ''),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Simpan', large: true, onPressed: _save),
        ],
      );
}
