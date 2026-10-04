import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../wallets/data/wallets_dao.dart';

final walletBalancesProvider = StreamProvider<List<WalletBalance>>(
  (ref) => ref.watch(appDatabaseProvider).walletsDao.watchBalances(),
);

final userNameProvider = StreamProvider<String?>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.userName),
);

/// Sapaan sesuai jam.
String greetingFor(DateTime now) => switch (now.hour) {
      >= 4 && < 11 => 'Selamat pagi',
      >= 11 && < 15 => 'Selamat siang',
      >= 15 && < 18 => 'Selamat sore',
      _ => 'Selamat malam',
    };

/// Beranda sementara: sapaan, total saldo, dan daftar dompet.
/// Beranda lengkap (transaksi terbaru, budget, Catat) dibangun di Tahap 4.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final String? name = ref.watch(userNameProvider).valueOrNull;
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    final int total = wallets.fold(0, (sum, w) => sum + w.balance);
    final bool hasPin = ref.watch(appGateProvider.select((g) => g.hasPin));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            Row(
              children: [
                const LogoMark(size: 32),
                const SizedBox(width: AppSpace.x8),
                Text('HitungIn', style: t.screenTitle.copyWith(fontSize: 18)),
                const Spacer(),
                if (kDebugMode)
                  _HeaderButton(icon: Icons.palette_outlined, label: 'Galeri desain', onTap: () => context.push(Routes.gallery)),
                if (hasPin)
                  _HeaderButton(
                    icon: Icons.lock_outline,
                    label: 'Kunci sekarang',
                    onTap: () => ref.read(appGateProvider.notifier).lock(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.x24),
            Text.rich(
              TextSpan(
                text: name == null ? greetingFor(DateTime.now()) : '${greetingFor(DateTime.now())}, ',
                children: [if (name != null) TextSpan(text: name, style: TextStyle(color: c.accentText))],
              ),
              style: t.greeting,
            ),
            const SizedBox(height: AppSpace.block),
            Container(
              padding: const EdgeInsets.all(AppSpace.cardHero),
              decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.lgAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total saldo', style: t.caption.copyWith(color: c.onCardMuted)),
                  const SizedBox(height: AppSpace.x4),
                  Text(Rupiah.format(total), style: t.amountXL.copyWith(color: c.onCard)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x24),
            Text('Dompet', style: t.section),
            const SizedBox(height: AppSpace.x8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
              child: Column(
                children: [
                  for (final (int i, WalletBalance w) in wallets.indexed) ...[
                    if (i > 0) Divider(color: c.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.row),
                      child: Row(
                        children: [
                          IconTile(icon: AppIcons.of(w.wallet.icon)),
                          const SizedBox(width: AppSpace.x12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.wallet.name, style: t.item),
                                Text(w.wallet.type.label, style: t.caption.copyWith(color: c.muted)),
                              ],
                            ),
                          ),
                          Text(Rupiah.format(w.balance), style: t.number),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: SizedBox.square(
          dimension: AppSpace.touch,
          child: Icon(icon, size: 22, color: context.colors.sub),
        ),
      );
}
