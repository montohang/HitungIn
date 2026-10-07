import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../backup/data/backup_age.dart';
import '../bills/bills_screen.dart';
import '../bills/data/bill_due.dart';
import '../budget/data/budget_insights.dart';
import '../budget/data/budgets_dao.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../transactions/data/transactions_dao.dart';
import '../transactions/widgets/tx_row.dart';
import '../transactions/riwayat_screen.dart' show riwayatLink;
import '../wallets/data/wallets_dao.dart';
import '../../core/widgets/hi_icons.dart';

/// Sapaan sesuai jam.
String greetingFor(DateTime now) => switch (now.hour) {
      >= 4 && < 11 => 'Selamat pagi',
      >= 11 && < 15 => 'Selamat siang',
      >= 15 && < 18 => 'Selamat sore',
      _ => 'Selamat malam',
    };

/// Beranda (Claude Design › Beranda & Beranda · hari pertama).
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
    final AsyncValue<List<TxDetail>> recentAsync = ref.watch(recentTxProvider);
    final List<TxDetail> recent = recentAsync.valueOrNull ?? const [];
    final List<BudgetProgress> budgets = ref.watch(budgetProgressProvider(month)).valueOrNull ?? const [];
    final bool hasPin = ref.watch(appGateProvider.select((g) => g.hasPin));
    final bool gradient = ref.watch(themeControllerProvider.select((s) => s.gradientBalanceCard));
    final bool hidden = ref.watch(hideBalanceProvider).valueOrNull ?? false;
    final ({String label, bool fresh}) backup = backupAge(ref.watch(lastBackupProvider).valueOrNull, now);
    final List<Bill> dueBills = [
      for (final b in ref.watch(activeBillsProvider).valueOrNull ?? const <Bill>[])
        if (billNeedsAttention(b, now)) b,
    ];
    final int total = wallets.fold(0, (sum, w) => sum + w.balance);
    final bool firstDay = recentAsync.hasValue && recent.isEmpty;

    void toggleHidden() => ref.read(appDatabaseProvider).settingsDao.write(SettingKeys.hideBalance, '${!hidden}');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            // Tanggal + sapaan, tombol mata & kunci.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFmt.longDate(now, now: now), style: t.caption.copyWith(color: c.muted)),
                      const SizedBox(height: AppSpace.x4),
                      Text.rich(
                        TextSpan(
                          text: firstDay ? 'Selamat datang' : greetingFor(now),
                          children: [
                            if (name != null) ...[
                              const TextSpan(text: ', '),
                              TextSpan(text: name, style: TextStyle(color: c.accentText)),
                            ],
                          ],
                        ),
                        style: t.greeting,
                      ),
                    ],
                  ),
                ),
                // Selalu ada: saldo awal sudah tampil sejak hari pertama.
                ...[
                  const SizedBox(width: AppSpace.x8),
                  _SquareButton(
                    icon: hidden ? HiIcons.eyeOff : HiIcons.eye,
                    label: hidden ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                    onTap: toggleHidden,
                  ),
                ],
                if (hasPin) ...[
                  const SizedBox(width: AppSpace.x8),
                  _SquareButton(
                    icon: HiIcons.lock,
                    label: 'Kunci sekarang',
                    onTap: () => ref.read(appGateProvider.notifier).lock(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.block),
            if (!firstDay) ...[
              Align(
                alignment: Alignment.centerLeft,
                child:
                    _BackupBadge(label: backup.label, fresh: backup.fresh, onTap: () => context.push(Routes.cadangan)),
              ),
              const SizedBox(height: AppSpace.block),
            ],
            _BalanceCard(
              total: total,
              walletCount: wallets.length,
              summary: summary,
              gradient: gradient && !firstDay,
              hidden: hidden,
              firstDay: firstDay,
              onWallets: () => context.push(Routes.dompet),
            ),
            const SizedBox(height: AppSpace.block),
            if (firstDay) ...[
              _FirstEntryCard(onExample: (text) => _openCatat(context, text)),
              const SizedBox(height: AppSpace.block),
              _SetupChecklist(
                hasPin: hasPin,
                hasWallet: wallets.isNotEmpty,
                hasTransaction: false,
                hasBudget: budgets.isNotEmpty,
              ),
            ] else ...[
              _QuickEntry(onSubmit: (text) => _openCatat(context, text)),
              if (budgetOverview(budgets) case final BudgetOverview o) ...[
                const SizedBox(height: AppSpace.block),
                _BudgetGlance(
                  overview: o,
                  hottest: (ref.watch(budgetWarnProvider).valueOrNull ?? true) ? hottestCategory(budgets, now) : null,
                  month: month,
                  now: now,
                  onTap: () => context.go(Routes.budget),
                ),
              ],
              if (dueBills.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x24),
                SectionHeader('Tagihan mendatang',
                    action: 'Semua tagihan', onAction: () => context.push(Routes.tagihan)),
                for (final b in dueBills.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.x8),
                    child: BillCard(bill: b, now: now),
                  ),
              ],
              const SizedBox(height: AppSpace.x24),
              SectionHeader('Transaksi terbaru', action: 'Lihat semua', onAction: () => context.push(Routes.riwayat)),
              for (final TxDetail d in recent)
                TxRow(
                  detail: d,
                  showDate: true,
                  masked: hidden,
                  now: now,
                  gap: AppSpace.x16,
                  onTap: () => context.push(Routes.tx(d.tx.id)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static void _openCatat(BuildContext context, String text) =>
      context.push(Uri(path: Routes.catat, queryParameters: {'text': text}).toString());
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // container: tombol tetap jadi node sendiri, tidak melebur ke teks sapaan.
    return Semantics(
      container: true,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: AppSpace.touch,
          height: AppSpace.touch,
          decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll, border: Border.all(color: c.line)),
          child: Icon(icon, size: 20, color: c.ink),
        ),
      ),
    );
  }
}

/// "Data di HP-mu · backup 2 hari lalu" (hijau) / perlu dicadangkan (oranye).
class _BackupBadge extends StatelessWidget {
  const _BackupBadge({required this.label, required this.fresh, required this.onTap});

  final String label;
  final bool fresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color bg = fresh ? c.goodSoft : c.warnSoft;
    final Color fg = fresh ? c.goodInk : c.warnInk;
    final String text =
        label == 'belum ada backup' ? 'Data di HP-mu · belum ada backup' : 'Data di HP-mu · backup $label';
    return Pressable(
      onTap: onTap,
      semanticLabel: text,
      child: Container(
        height: 28,
        padding: const EdgeInsets.only(left: AppSpace.x8, right: AppSpace.x12),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HiIcons.shield, size: 16, color: fg),
            const SizedBox(width: AppSpace.x8),
            Flexible(
              child: Text(text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.label.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

const String _coinStackSvg = '''
<svg width="96" height="80" viewBox="0 0 120 100" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="60" cy="88" rx="44" ry="6" fill="#000000" fill-opacity="0.25"/>
  <rect x="18" y="62" width="40" height="12" rx="6" fill="#F2C14E"/>
  <rect x="18" y="50" width="40" height="12" rx="6" fill="#F6D27A"/>
  <rect x="18" y="74" width="40" height="12" rx="6" fill="#D9A21F"/>
  <rect x="62" y="38" width="40" height="12" rx="6" fill="#F6D27A"/>
  <rect x="62" y="50" width="40" height="12" rx="6" fill="#F2C14E"/>
  <rect x="62" y="62" width="40" height="12" rx="6" fill="#F6D27A"/>
  <rect x="62" y="74" width="40" height="12" rx="6" fill="#D9A21F"/>
  <path d="M80 26 C80 18 80 14 80 8" stroke="#2FA37A" stroke-width="3" fill="none" stroke-linecap="round"/>
  <ellipse cx="73" cy="12" rx="7" ry="4" fill="#2FA37A" transform="rotate(-25 73 12)"/>
  <ellipse cx="87" cy="15" rx="7" ry="4" fill="#2FA37A" transform="rotate(25 87 15)"/>
</svg>''';

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.walletCount,
    required this.summary,
    required this.gradient,
    required this.hidden,
    required this.firstDay,
    required this.onWallets,
  });

  final int total;
  final int walletCount;
  final PeriodSummary summary;
  final bool gradient;
  final bool hidden;
  final bool firstDay;
  final VoidCallback onWallets;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: Container(
        decoration: BoxDecoration(
          color: gradient ? null : c.card,
          gradient: gradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.4, 1],
                  colors: [c.card, c.card, Color.lerp(c.card, c.accent, 0.5)!],
                )
              : null,
        ),
        child: Stack(
          children: [
            if (!firstDay) ...[
              Positioned(
                right: -40,
                top: -50,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent.withAlpha(gradient ? 0x38 : 0x59),
                  ),
                ),
              ),
              Positioned(right: 14, top: 14, child: SvgPicture.string(_coinStackSvg, width: 96, height: 80)),
            ],
            Padding(
              padding: const EdgeInsets.all(AppSpace.cardHero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pressable(
                    onTap: firstDay ? null : onWallets,
                    semanticLabel: 'Total saldo, $walletCount dompet',
                    child: Text(
                      firstDay ? 'Total saldo · $walletCount dompet' : 'Total saldo · $walletCount dompet ›',
                      style: t.caption.copyWith(color: c.onCardMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x8),
                  if (hidden)
                    Text('Rp ••••••', style: t.amountXL.copyWith(color: c.onCard))
                  else
                    CountUpRupiah(amount: total, style: t.amountXL.copyWith(color: c.onCard)),
                  const SizedBox(height: AppSpace.x16),
                  if (firstDay)
                    Text(
                      'Saldo awal sudah tercatat. Pemasukan & pengeluaran muncul di sini.',
                      style: t.caption.copyWith(color: c.onCardMuted),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _Mini(
                            onTap: () => context.push(riwayatLink(kind: TxKind.pemasukan)),
                            label: 'Masuk bulan ini',
                            value: hidden ? '••••' : '+${Rupiah.compact(summary.income)}',
                            color: c.goodInk,
                          ),
                        ),
                        const SizedBox(width: AppSpace.x12),
                        Expanded(
                          child: _Mini(
                            onTap: () => context.push(riwayatLink(kind: TxKind.pengeluaran)),
                            label: 'Keluar bulan ini',
                            value: hidden ? '••••' : '${Rupiah.minus}${Rupiah.compact(summary.expense)}',
                            color: c.onCard,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color, required this.onTap});

  final VoidCallback onTap;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label, buka riwayat',
      child: Container(
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
      ),
    );
  }
}

/// Kolom Catat cepat: ikon kilau + tombol panah (desain).
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
    final c = context.colors;
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: AppSpace.x16, right: AppSpace.x8),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
      child: Row(
        children: [
          Icon(HiIcons.sparkle, size: 20, color: c.accentText),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: TextField(
              key: const Key('home-catat-cepat'),
              controller: _text,
              style: context.text.item.copyWith(fontWeight: FontWeight.w500),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Ketik cepat: kopi 25rb gopay',
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Pressable(
            onTap: _submit,
            semanticLabel: 'Lanjut catat',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.smAll),
              child: Icon(HiIcons.arrowRight, size: 18, color: c.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Budget Oktober 74% · Sisa … · 12 hari lagi · Makan 82%".
class _BudgetGlance extends StatelessWidget {
  const _BudgetGlance(
      {required this.overview, required this.hottest, required this.month, required this.now, required this.onTap});

  final BudgetOverview overview;
  final BudgetProgress? hottest;
  final DateTime month;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final double ratio = overview.limit == 0 ? 0 : overview.spent / overview.limit;
    final int left = overview.limit - overview.spent;
    final BudgetProgress? hot = hottest;
    return Pressable.card(
      onTap: onTap,
      semanticLabel: 'Budget ${DateFmt.months[month.month - 1]}',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Budget ${DateFmt.months[month.month - 1]}', style: t.title)),
                Text('${(ratio * 100).round()}%', style: t.number),
              ],
            ),
            const SizedBox(height: AppSpace.x12),
            AppProgressBar(value: ratio),
            const SizedBox(height: AppSpace.x12),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: left >= 0 ? 'Sisa ' : 'Lewat ',
                      children: [
                        TextSpan(
                            text: Rupiah.format(left.abs()),
                            style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
                        TextSpan(text: ' · ${daysLeftInMonth(now)} hari lagi'),
                      ],
                    ),
                    style: t.caption.copyWith(color: c.muted),
                  ),
                ),
                if (hot != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x4),
                    decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.pillAll),
                    child: Text(
                      '${shortCategoryName(hot.category!.name)} ${(hot.spent / hot.budget.limitAmount * 100).round()}%',
                      style: t.label.copyWith(color: c.warnInk),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hari pertama: ajakan mencatat dengan contoh yang bisa diketuk.
class _FirstEntryCard extends StatelessWidget {
  const _FirstEntryCard({required this.onExample});

  final ValueChanged<String> onExample;

  static const List<String> examples = ['kopi 25rb gopay', 'gaji 9,2jt bca', 'bensin 50rb'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    String hex(Color x) => '#${(x.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final String art = '''
<svg width="132" height="104" viewBox="0 0 200 160" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="100" cy="148" rx="64" ry="7" fill="${hex(c.track)}"/>
  <rect x="46" y="34" width="108" height="104" rx="16" fill="#FFFFFF" stroke="${hex(c.line2)}" stroke-width="3"/>
  <rect x="62" y="56" width="52" height="8" rx="4" fill="#DCD9E8"/>
  <rect x="62" y="76" width="76" height="8" rx="4" fill="#EFEDF5"/>
  <rect x="62" y="96" width="64" height="8" rx="4" fill="#EFEDF5"/>
  <circle cx="150" cy="38" r="20" fill="${hex(c.accent)}"/>
  <path d="M150 29v18M141 38h18" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>
  <path d="M30 70l3 7 7 3-7 3-3 7-3-7-7-3 7-3z" fill="#F2C14E"/>
</svg>''';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x24),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          SvgPicture.string(art, width: 132, height: 104),
          const SizedBox(height: AppSpace.x12),
          Text('Catatan pertamamu dimulai di sini',
              textAlign: TextAlign.center, style: t.section.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpace.x8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'Coba ketik seperti kamu chat. Ketuk contoh di bawah untuk mencoba.',
              textAlign: TextAlign.center,
              style: t.body.copyWith(fontSize: 14, color: c.sub),
            ),
          ),
          const SizedBox(height: AppSpace.x12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final ex in examples)
                Pressable(
                  onTap: () => onExample(ex),
                  semanticLabel: 'Contoh: $ex',
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.pillAll),
                    // Row min: lebar mengikuti teks (alignment membuat chip melebar penuh di Wrap).
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ex, style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          AppButton(label: 'Catat transaksi pertama', onPressed: () => context.push(Routes.catat)),
        ],
      ),
    );
  }
}

/// "Siapkan HitungIn · 2 dari 4".
class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist(
      {required this.hasPin, required this.hasWallet, required this.hasTransaction, required this.hasBudget});

  final bool hasPin;
  final bool hasWallet;
  final bool hasTransaction;
  final bool hasBudget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<(String, bool, String)> steps = [
      ('Buat PIN & sidik jari', hasPin, Routes.keamanan),
      ('Tambah dompet', hasWallet, Routes.dompet),
      ('Catat transaksi pertama', hasTransaction, Routes.catat),
      ('Atur budget bulan ini', hasBudget, Routes.budget),
    ];
    final int done = steps.where((s) => s.$2).length;
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Siapkan HitungIn', style: t.title)),
              Text('$done dari ${steps.length}',
                  style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          AppProgressBar(value: done / steps.length, height: 8, autoLevel: false),
          for (final (String label, bool ok, String route) in steps)
            Pressable(
              onTap: ok ? null : () => route == Routes.budget ? context.go(route) : context.push(route),
              semanticLabel: '$label${ok ? ', selesai' : ''}',
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpace.x12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ok ? c.good : c.surface,
                        border: Border.all(color: ok ? c.good : c.line2, width: 2),
                      ),
                      child: ok ? const Icon(HiIcons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: AppSpace.x12),
                    Expanded(
                      child: Text(
                        label,
                        style: t.item.copyWith(
                          fontSize: 14,
                          color: ok ? c.muted : c.ink,
                          decoration: ok ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (!ok) Icon(HiIcons.forward, size: 18, color: c.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
