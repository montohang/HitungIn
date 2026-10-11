import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../security/app_gate.dart';
import '../../settings/widgets/settings_tile.dart' show showAppSheet;
import '../allowance_provider.dart';
import '../data/allowance.dart';

String _dayMonth(DateTime d) => '${d.day} ${DateFmt.monthsShort[d.month - 1]}';

/// Angka besar kartu/widget Jatah.
String allowanceAmount(Allowance a, {required bool hidden}) => hidden
    ? 'Rp ••••'
    : a.state == AllowanceState.kosong
        ? '—'
        : Rupiah.format(a.jatah);

/// Baris kecil di bawah angka Jatah (Beranda & widget).
String allowanceLine(Allowance a, DateTime now, {required bool hidden}) => switch (a.state) {
      _ when hidden => 'Ketuk mata untuk menampilkan',
      AllowanceState.kosong => 'Isi saldo dompet untuk melihat jatah harianmu',
      AllowanceState.habis => 'Tagihan sudah menutup saldo sampai gajian',
      AllowanceState.lewat => a.tomorrow == null
          ? 'Lewat ${Rupiah.compact(-a.remaining)} hari ini'
          : 'Lewat ${Rupiah.compact(-a.remaining)} — jatah besok jadi ${Rupiah.format(a.tomorrow!)}',
      _ => 'Sisa ${Rupiah.format(a.remaining)} · '
          '${a.useBudget ? 'budget s.d. ${_dayMonth(DateTime(now.year, now.month + 1, 0))}' : 'gajian ${a.daysToPayday} hari lagi'}',
    };

/// Kartu "Jatah hari ini" di Beranda (P1-1, Claude Design › Beranda).
class AllowanceCard extends ConsumerWidget {
  const AllowanceCard({super.key, required this.allowance, required this.hidden, required this.now});

  final Allowance allowance;
  final bool hidden;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final Allowance a = allowance;
    // Dimuat sekarang supaya saran tanggal gajian siap saat sheet dibuka.
    ref.watch(suggestedPaydayProvider);
    final bool warn = a.state == AllowanceState.menipis || a.state == AllowanceState.lewat || a.state == AllowanceState.habis;
    final String chip = switch (a.state) {
      AllowanceState.habis => 'Habis',
      AllowanceState.lewat => 'Lewat',
      _ => 'Menipis',
    };
    final String line = allowanceLine(a, now, hidden: hidden);
    final String amount = allowanceAmount(a, hidden: hidden);
    return Pressable.card(
      onTap: () => a.state == AllowanceState.kosong ? context.push(Routes.dompet) : showAllowanceDetails(context, ref, a, now),
      semanticLabel: 'Jatah hari ini $amount. $line',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Jatah hari ini', style: t.caption.copyWith(color: c.muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpace.x4),
                Icon(HiIcons.info, size: 14, color: c.muted),
                const Spacer(),
                if (warn && !hidden)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8 + 2, vertical: AppSpace.x4),
                    decoration: BoxDecoration(color: c.warnSoft, borderRadius: AppRadius.pillAll),
                    child: Text(chip, style: t.label.copyWith(color: c.warnInk, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.x8),
            Text(amount,
                style: t.amountL.copyWith(fontSize: 30, color: a.state == AllowanceState.habis ? c.muted : c.ink)),
            if (a.state != AllowanceState.kosong) ...[
              const SizedBox(height: AppSpace.x8),
              AppProgressBar(
                value: hidden ? 0 : (a.state == AllowanceState.habis ? 1 : (a.jatah == 0 ? 0 : a.spentToday / a.jatah)),
                height: 8,
                autoLevel: false,
                color: warn ? c.warnInk : c.accent,
              ),
            ],
            const SizedBox(height: AppSpace.x8),
            Text(line, style: t.caption.copyWith(color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// Sheet "Dari mana angka ini?".
Future<void> showAllowanceDetails(BuildContext context, WidgetRef ref, Allowance a, DateTime today) async {
  final DateTime monthEnd = DateTime(today.year, today.month + 1, 0);
  final DateTime periodEnd = a.nextPayday.subtract(const Duration(days: 1));
  final int payday = ref.read(paydayProvider).valueOrNull ?? 1;
  String names(List<String> n) => n.isEmpty ? '' : ' (${n.take(2).join(', ')}${n.length > 2 ? ', …' : ''})';
  final List<(String, String)> rows = a.useBudget
      ? [
          ('Sisa budget ${DateFmt.months[today.month - 1]}', Rupiah.format(a.budgetLeft ?? 0)),
          ('Pengeluaran hari ini', '+${Rupiah.format(a.spentToday)}'),
          ('Dibagi sisa hari', '÷ ${a.daysLeftInMonth} hari (s.d. ${_dayMonth(monthEnd)})'),
          ('Jatah hari ini', Rupiah.format(a.jatah)),
        ]
      : [
          ('Saldo dompet yang dihitung', Rupiah.format(a.balance)),
          if (a.billsDue > 0) ('Tagihan sampai gajian${names(a.billNames)}', '${Rupiah.minus}${Rupiah.format(a.billsDue)}'),
          if (a.recurringDue > 0)
            ('Transaksi berulang${names(a.recurringNames)}', '${Rupiah.minus}${Rupiah.format(a.recurringDue)}'),
          ('Pengeluaran hari ini', '+${Rupiah.format(a.spentToday)}'),
          ('Dibagi sisa hari', '÷ ${a.daysToPayday} hari (s.d. ${_dayMonth(periodEnd)})'),
          ('Jatah hari ini', Rupiah.format(a.jatah)),
        ];
  final String? other = a.perBudget == null
      ? null
      : a.useBudget
          ? 'Hitungan saldo: ${Rupiah.format(a.perSaldo)}/hari — saldo ${Rupiah.format(a.balance)} dikurangi tagihan '
              '& transaksi berulang, dibagi ${a.daysToPayday} hari sampai gajian.'
          : 'Hitungan budget: ${Rupiah.format(a.perBudget!)}/hari — sisa budget dibagi ${a.daysLeftInMonth} hari. '
              'Dipakai bila lebih kecil.';
  final bool? openPayday = await showAppSheet<bool>(
    context,
    title: 'Dari mana angka ini?',
    aboveNav: true,
    builder: (context) {
      final c = context.colors;
      final t = context.text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            a.useBudget
                ? 'Mengikuti budget ${DateFmt.months[today.month - 1]}, karena lebih kecil dari hitungan saldo sampai gajian.'
                : 'Dari saldo dompet sampai gajian, dikurangi tagihan dan transaksi berulang yang akan jatuh tempo.',
            style: t.body.copyWith(color: c.sub, fontSize: 14),
          ),
          const SizedBox(height: AppSpace.x12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
            decoration: BoxDecoration(borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
            child: Column(
              children: [
                for (final (int i, (String, String) r) in rows.indexed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: c.line))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(r.$1,
                              style: (i == rows.length - 1 ? t.title : t.caption)
                                  .copyWith(color: i == rows.length - 1 ? c.ink : c.sub, fontSize: 14)),
                        ),
                        const SizedBox(width: AppSpace.x12),
                        Text(r.$2,
                            style: t.number.copyWith(
                                fontSize: 14, fontWeight: i == rows.length - 1 ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (other != null) ...[
            const SizedBox(height: AppSpace.x12),
            Container(
              padding: const EdgeInsets.all(AppSpace.x12),
              decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
              child: Text(other, style: t.caption.copyWith(color: c.muted)),
            ),
          ],
          const SizedBox(height: AppSpace.x16),
          AppButton(
            label: 'Ubah tanggal gajian · tgl $payday',
            variant: AppButtonVariant.soft,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Gaji yang belum masuk tidak ikut dihitung, supaya angkanya tetap aman. '
            'Dompet bisa dikecualikan di Dompet › Ubah dompet.',
            textAlign: TextAlign.center,
            style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500),
          ),
        ],
      );
    },
  );
  if (openPayday == true && context.mounted) await showPaydayPicker(context, ref);
}

/// Sheet pilih tanggal gajian (1–31).
Future<void> showPaydayPicker(BuildContext context, WidgetRef ref) async {
  final int current = ref.read(paydayProvider).valueOrNull ?? 1;
  final int? suggested = ref.read(suggestedPaydayProvider);
  final int? picked = await showAppSheet<int>(
    context,
    title: 'Tanggal gajian',
    aboveNav: true,
    builder: (context) {
      final c = context.colors;
      final t = context.text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jatah harian dihitung sampai sehari sebelum tanggal ini. Tanggal 29–31 di bulan pendek jadi hari terakhir bulan.',
            style: t.body.copyWith(color: c.sub, fontSize: 14),
          ),
          if (suggested != null && suggested != current) ...[
            const SizedBox(height: AppSpace.x12),
            Pressable(
              onTap: () => Navigator.pop(context, suggested),
              semanticLabel: 'Pakai tanggal $suggested dari transaksi berulang Gaji',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: 10),
                decoration: BoxDecoration(color: c.goodSoft, borderRadius: AppRadius.smAll),
                child: Row(
                  children: [
                    Icon(HiIcons.sparkle, size: 16, color: c.goodInk),
                    const SizedBox(width: AppSpace.x8),
                    Expanded(
                      child: Text('Disarankan tgl $suggested, dari transaksi berulang "Gaji"',
                          style: t.caption.copyWith(color: c.goodInk, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.x12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.1,
            children: [
              for (int d = 1; d <= 31; d++)
                Pressable(
                  onTap: () => Navigator.pop(context, d),
                  semanticLabel: 'Tanggal $d',
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: d == current ? c.accent : c.surface,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: d == current ? c.accent : c.line),
                    ),
                    child: Text('$d',
                        style: t.number.copyWith(fontSize: 14, color: d == current ? c.onAccent : c.ink)),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
  if (picked != null) await setPayday(ref.read(appDatabaseProvider).settingsDao, picked);
}
