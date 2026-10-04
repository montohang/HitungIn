import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/data_providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/db/app_database.dart';
import '../bills/bills_screen.dart';
import '../bills/data/bill_due.dart';
import '../budget/data/budgets_dao.dart';
import '../security/app_gate.dart';
import '../transactions/data/transactions_dao.dart';
import '../transactions/widgets/tx_row.dart';
import '../wallets/data/wallets_dao.dart';

/// Sapaan sesuai jam.
String greetingFor(DateTime now) => switch (now.hour) {
      >= 4 && < 11 => 'Selamat pagi',
      >= 11 && < 15 => 'Selamat siang',
      >= 15 && < 18 => 'Selamat sore',
      _ => 'Selamat malam',
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final DateTime month = ref.watch(currentMonthProvider);
    final String? name = ref.watch(userNameProvider).valueOrNull;
    final List<WalletBalance> wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    final PeriodSummary summary = ref.watch(monthSummaryProvider(month)).valueOrNull ?? (income: 0, expense: 0);
    final List<TxDetail> recent = ref.watch(recentTxProvider).valueOrNull ?? const [];
    final List<BudgetProgress> budgets = ref.watch(budgetProgressProvider(month)).valueOrNull ?? const [];
    final BudgetProgress? totalBudget = budgets.where((b) => b.category == null).firstOrNull;
    final bool hasPin = ref.watch(appGateProvider.select((g) => g.hasPin));
    final List<Bill> dueBills = [
      for (final b in ref.watch(activeBillsProvider).valueOrNull ?? const <Bill>[])
        if (billNeedsAttention(b, now)) b,
    ];
    final bool gradient = ref.watch(themeControllerProvider.select((s) => s.gradientBalanceCard));

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
                _HeaderButton(icon: Icons.settings_outlined, label: 'Pengaturan', onTap: () => context.push(Routes.pengaturan)),
                if (hasPin)
                  _HeaderButton(
                    icon: Icons.lock_outline,
                    label: 'Kunci sekarang',
                    onTap: () => ref.read(appGateProvider.notifier).lock(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.x24),
            Text(DateFmt.longDate(now, now: now), style: t.caption.copyWith(color: c.muted)),
            const SizedBox(height: AppSpace.x4),
            Text.rich(
              TextSpan(
                text: name == null ? greetingFor(now) : '${greetingFor(now)}, ',
                children: [if (name != null) TextSpan(text: name, style: TextStyle(color: c.accentText))],
              ),
              style: t.greeting,
            ),
            const SizedBox(height: AppSpace.block),
            _BalanceCard(
              total: wallets.fold(0, (sum, w) => sum + w.balance),
              walletCount: wallets.length,
              summary: summary,
              gradient: gradient,
            ),
            const SizedBox(height: AppSpace.block),
            _QuickEntry(onSubmit: (text) => context.push(Uri(path: Routes.catat, queryParameters: {'text': text}).toString())),
            if (dueBills.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x24),
              SectionHeader('Tagihan mendatang', action: 'Semua tagihan', onAction: () => context.push(Routes.tagihan)),
              for (final b in dueBills.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.x8),
                  child: BillCard(bill: b, now: now),
                ),
            ],
            if (totalBudget != null) ...[
              const SizedBox(height: AppSpace.block),
              _BudgetGlance(progress: totalBudget, now: now, onTap: () => context.go(Routes.budget)),
            ],
            const SizedBox(height: AppSpace.x24),
            SectionHeader(
              'Transaksi terbaru',
              action: recent.isEmpty ? null : 'Lihat semua',
              onAction: () => context.go(Routes.riwayat),
            ),
            if (recent.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  body: 'Coba ketik "kopi 25rb" di kolom Catat cepat di atas.',
                  action: 'Catat sekarang',
                  onAction: () => context.push(Routes.catat),
                ),
              )
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.card, vertical: AppSpace.x4),
                child: Column(
                  children: [
                    for (final (int i, TxDetail d) in recent.indexed) ...[
                      if (i > 0) Divider(color: c.line),
                      TxRow(detail: d, showDate: true, onTap: () => context.push(Routes.tx(d.tx.id))),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.x24),
            const SectionHeader('Dompet'),
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
                          Text(Rupiah.format(w.balance), style: t.number.copyWith(color: w.balance < 0 ? c.danger : c.ink)),
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

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total, required this.walletCount, required this.summary, required this.gradient});

  final int total;
  final int walletCount;
  final PeriodSummary summary;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.cardHero),
      decoration: BoxDecoration(
        color: gradient ? null : c.card,
        borderRadius: AppRadius.lgAll,
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.4, 1],
                colors: [c.card, c.card, Color.lerp(c.card, c.accent, 0.5)!],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total saldo · $walletCount dompet', style: t.caption.copyWith(color: c.onCardMuted)),
          const SizedBox(height: AppSpace.x8),
          CountUpRupiah(amount: total, style: t.amountXL.copyWith(color: c.onCard)),
          const SizedBox(height: AppSpace.x16),
          Row(
            children: [
              Expanded(child: _Mini(label: 'Masuk bulan ini', value: '+${Rupiah.compact(summary.income)}', color: c.goodInk)),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: _Mini(label: 'Keluar bulan ini', value: '${Rupiah.minus}${Rupiah.compact(summary.expense)}', color: c.onCard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.onCard.withAlpha(0x12), borderRadius: AppRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.label.copyWith(color: c.onCardMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpace.x2),
          Text(value, style: context.text.number.copyWith(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

/// Kolom Catat cepat di beranda — Enter membuka layar Catat yang sudah terisi.
class _QuickEntry extends StatefulWidget {
  const _QuickEntry({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_QuickEntry> createState() => _QuickEntryState();
}

class _QuickEntryState extends State<_QuickEntry> {
  final TextEditingController _text = TextEditingController();

  void _submit() {
    final String value = _text.text.trim();
    if (value.isEmpty) return;
    _text.clear();
    FocusScope.of(context).unfocus();
    widget.onSubmit(value);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('home-catat-cepat'),
      controller: _text,
      style: context.text.item,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Catat cepat: kopi 25rb gopay',
        prefixIcon: const Icon(Icons.bolt_outlined),
        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), tooltip: 'Lanjut catat', onPressed: _submit),
      ),
    );
  }
}

class _BudgetGlance extends StatelessWidget {
  const _BudgetGlance({required this.progress, required this.now, required this.onTap});

  final BudgetProgress progress;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int limit = progress.budget.limitAmount;
    final int left = limit - progress.spent;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Budget bulan ini', style: t.title)),
              Text('${Rupiah.compact(progress.spent)} / ${Rupiah.compact(limit)}', style: t.number.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          AppProgressBar(value: progress.spent / limit),
          const SizedBox(height: AppSpace.x8),
          Text(
            left >= 0 ? 'Sisa ${Rupiah.format(left)}' : 'Lewat ${Rupiah.format(-left)} dari batas',
            style: t.caption.copyWith(color: left >= 0 ? c.muted : c.danger),
          ),
        ],
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
