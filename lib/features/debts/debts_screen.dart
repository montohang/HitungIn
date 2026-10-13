import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/platform/share_text.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import '../wallets/data/wallets_dao.dart' show WalletBalance;
import 'data/debts.dart';
import 'data/debts_dao.dart';
import 'debts_provider.dart';

/// Isian dari Catat cepat ("pinjam budi 200rb", "budi bayar 100rb").
typedef DebtDraft = ({DebtDirection direction, bool payment, String name, int? amount, int? walletId});

/// Tautan /utang untuk [DebtDraft] (dibaca lagi oleh [debtDraftFrom]).
String debtDraftLink(DebtDraft d) => Uri(path: Routes.utang, queryParameters: {
      'dir': d.direction.name,
      if (d.payment) 'bayar': '1',
      if (d.name.isNotEmpty) 'nama': d.name,
      if (d.amount != null) 'nominal': '${d.amount}',
      if (d.walletId != null) 'dompet': '${d.walletId}',
    }).toString();

DebtDraft? debtDraftFrom(Map<String, String> q) {
  final DebtDirection? dir = DebtDirection.values.where((d) => d.name == q['dir']).firstOrNull;
  if (dir == null) return null;
  return (
    direction: dir,
    payment: q['bayar'] == '1',
    name: q['nama'] ?? '',
    amount: int.tryParse(q['nominal'] ?? ''),
    walletId: int.tryParse(q['dompet'] ?? ''),
  );
}

/// Catatan belum lunas atas nama [name] (tanpa beda huruf besar/kecil), terbaru dulu.
DebtWithPayments? findOpenDebt(List<DebtWithPayments> all, DebtDirection dir, String name) {
  final String n = name.trim().toLowerCase();
  if (n.isEmpty) return null;
  return all.where((d) => d.debt.direction == dir && d.left > 0 && d.debt.name.trim().toLowerCase() == n).firstOrNull ??
      all.where((d) => d.debt.direction == dir && d.left > 0 && d.debt.name.toLowerCase().startsWith(n)).firstOrNull;
}

/// Utang-piutang (P2-2, Claude Design › Utang-piutang): ringkasan dua arah,
/// daftar per orang, detail + bayar sebagian, dan tagih lewat WhatsApp.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key, this.openId, this.draft});

  /// Langsung buka detail catatan ini (dari Detail transaksi).
  final int? openId;

  /// Langsung buka form baru terisi.
  final DebtDraft? draft;

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  DebtDirection _tab = DebtDirection.piutang;

  @override
  void initState() {
    super.initState();
    final DebtDraft? draft = widget.draft;
    if (draft != null) _tab = draft.direction;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (draft != null && draft.payment) {
        final List<DebtWithPayments> all = await ref.read(appDatabaseProvider).debtsDao.watchAll().first;
        final DebtWithPayments? d = findOpenDebt(all, draft.direction, draft.name);
        if (!mounted) return;
        if (d == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(draft.name.isEmpty
                ? 'Sebutkan namanya, mis. "budi bayar 100rb"'
                : 'Belum ada catatan ${draft.direction == DebtDirection.piutang ? 'pinjaman' : 'utang ke'} ${draft.name} yang belum lunas'),
          ));
          return;
        }
        await showAppSheet<void>(context,
            title: draft.direction == DebtDirection.piutang
                ? 'Catat pembayaran ${d.debt.name}'
                : 'Bayar utang ke ${d.debt.name}',
            builder: (_) => _PaySheet(d: d, amount: draft.amount, walletId: draft.walletId));
      } else if (draft != null) {
        await openDebtForm(context, draft: draft);
      } else if (widget.openId != null) {
        final DebtWithPayments? d = await ref.read(appDatabaseProvider).debtsDao.byId(widget.openId!);
        if (d != null && mounted) {
          setState(() => _tab = d.debt.direction);
          await openDebtDetail(context, widget.openId!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<DebtWithPayments>> async = ref.watch(debtsProvider);
    final List<DebtWithPayments> all = async.valueOrNull ?? const [];
    final DebtTotals totals = debtTotals(all.map((d) => d.facts), now);
    // Belum lunas dulu (yang lewat jatuh tempo paling atas), lalu yang lunas.
    final List<DebtWithPayments> list = [
      for (final d in all)
        if (d.debt.direction == _tab) d,
    ]..sort((a, b) {
        int rank(DebtWithPayments d) => d.left == 0 ? 2 : (debtOverdue(d.facts, now) ? 0 : 1);
        return rank(a).compareTo(rank(b));
      });
    final int overdueOwed =
        all.where((d) => d.debt.direction == DebtDirection.piutang && debtOverdue(d.facts, now)).length;
    final DateTime? nextDue = (all
            .where((d) => d.debt.direction == DebtDirection.utang && d.left > 0 && d.debt.dueDate != null)
            .map((d) => d.debt.dueDate!)
            .toList()
          ..sort())
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: 'Utang-piutang',
              large: true,
              trailing: Pressable(
                onTap: () => openDebtForm(context, direction: _tab),
                semanticLabel: 'Catat utang-piutang',
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                  child: Text('+ Catat', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TotalCard(
                      label: 'Orang berutang ke kamu',
                      amount: totals.owedToMe,
                      color: c.good,
                      meta: totals.owedToMeCount == 0
                          ? 'Tidak ada'
                          : '${totals.owedToMeCount} orang${overdueOwed > 0 ? ' · $overdueOwed lewat jatuh tempo' : ''}',
                    ),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Expanded(
                    child: _TotalCard(
                      label: 'Kamu berutang',
                      amount: totals.iOwe,
                      color: c.ink,
                      meta: totals.iOweCount == 0
                          ? 'Tidak ada'
                          : '${totals.iOweCount} orang${nextDue != null ? ' · jatuh tempo ${DateFmt.date(nextDue, now: now)}' : ''}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            AppSegmentedControl<DebtDirection>(
              options: DebtDirection.values,
              selected: _tab,
              labelOf: (d) => d.label,
              onChanged: (d) => setState(() => _tab = d),
            ),
            const SizedBox(height: AppSpace.x16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
              decoration:
                  BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.x24),
                      child: Text(
                        async.isLoading
                            ? ''
                            : _tab == DebtDirection.piutang
                                ? 'Belum ada yang berutang ke kamu'
                                : 'Kamu tidak punya utang. Mantap!',
                        textAlign: TextAlign.center,
                        style: t.caption.copyWith(color: c.muted),
                      ),
                    )
                  : Column(
                      children: [
                        for (final (int i, DebtWithPayments d) in list.indexed)
                          _DebtRow(d: d, now: now, last: i == list.length - 1),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpace.x12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
              child: Text(
                'Bila dompet dipilih, saldonya ikut berubah — tapi tidak dihitung sebagai pemasukan atau pengeluaran di Laporan.',
                textAlign: TextAlign.center,
                style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.amount, required this.color, required this.meta});

  final String label;
  final int amount;
  final Color color;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
          const SizedBox(height: AppSpace.x4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Rupiah.format(amount),
                style: t.amountL.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: AppSpace.x4),
          Text(meta, maxLines: 2, style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
        ],
      ),
    );
  }
}

/// Warna avatar tetap untuk satu nama.
int _colorOf(String name) => 1 + name.toLowerCase().codeUnits.fold(0, (a, b) => a + b) % (AppPalette.length - 1);

String _initials(String name) {
  final List<String> words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.take(2).map((w) => w.characters.first).join().toUpperCase();
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int color = _colorOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppPalette.soft(context, color), shape: BoxShape.circle),
      child: Text(
        _initials(name),
        style: context.text.item
            .copyWith(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: AppPalette.ink(context, color)),
      ),
    );
  }
}

/// (label, latar, teks) chip status.
(String, Color, Color) _statusChip(BuildContext context, DebtWithPayments d, DateTime now) {
  final c = context.colors;
  return switch (d.status) {
    DebtStatus.lunas => ('Lunas', c.goodSoft, c.goodInk),
    _ when debtOverdue(d.facts, now) => ('Lewat jatuh tempo', c.warnSoft, c.warnInk),
    DebtStatus.dicicil => ('Dicicil', c.accentSoft, c.accentText),
    DebtStatus.belumLunas => ('Belum lunas', c.chip, c.sub),
  };
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.d, required this.now, required this.last});

  final DebtWithPayments d;
  final DateTime now;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Debt debt = d.debt;
    final (String status, Color bg, Color fg) = _statusChip(context, d, now);
    final bool owed = debt.direction == DebtDirection.piutang;
    final String meta = [
      '${owed ? 'Pinjam' : 'Dari'} ${DateFmt.date(debt.occurredAt, now: now)}',
      if (debt.dueDate != null && d.left > 0) 'jatuh tempo ${DateFmt.date(debt.dueDate!, now: now)}',
      if (d.paid > 0 && d.left > 0) 'dari ${Rupiah.format(debt.amount)}',
    ].join(' · ');
    return Pressable.card(
      onTap: () => openDebtDetail(context, debt.id),
      semanticLabel: '${debt.name}, sisa ${Rupiah.format(d.left)}, $status',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        decoration: BoxDecoration(color: c.surface, border: last ? null : Border(bottom: BorderSide(color: c.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(name: debt.name),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(debt.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.item)),
                      const SizedBox(width: AppSpace.x8),
                      Text(
                        d.left == 0 ? 'Lunas' : Rupiah.format(d.left),
                        style: t.number.copyWith(color: d.left == 0 ? c.muted : (owed ? c.good : c.ink)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      AppBadge(status, background: bg, foreground: fg),
                    ],
                  ),
                  if (d.paid > 0 && d.left > 0) ...[
                    const SizedBox(height: AppSpace.x8),
                    AppProgressBar(value: d.paid / debt.amount, height: 6, autoLevel: false, color: c.accent),
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

/// Sheet detail satu catatan.
Future<void> openDebtDetail(BuildContext context, int id) =>
    showAppSheet<void>(context, title: 'Utang-piutang', builder: (_) => _DebtDetail(id: id));

class _DebtDetail extends ConsumerWidget {
  const _DebtDetail({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final DebtWithPayments? d =
        (ref.watch(debtsProvider).valueOrNull ?? const <DebtWithPayments>[]).where((x) => x.debt.id == id).firstOrNull;
    if (d == null) return const SizedBox(height: 120);
    final Debt debt = d.debt;
    final bool owed = debt.direction == DebtDirection.piutang;
    final Map<int, String> walletNames = {
      for (final WalletBalance w in ref.watch(walletBalancesProvider).valueOrNull ?? const <WalletBalance>[])
        w.wallet.id: w.wallet.name,
    };
    final String? walletName = debt.walletId == null ? null : walletNames[debt.walletId];
    final (String status, Color bg, Color fg) = _statusChip(context, d, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Avatar(name: debt.name, size: 48),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.name, style: t.screenTitle.copyWith(fontSize: 22)),
                  Text(
                    [owed ? 'Berutang ke kamu' : 'Kamu berutang', if (walletName != null) walletName].join(' · '),
                    style: t.caption.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            AppBadge(status, background: bg, foreground: fg),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
          decoration: BoxDecoration(borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
          child: Column(
            children: [
              for (final (int i, (String k, String v)) in [
                ('Pinjaman', Rupiah.format(debt.amount)),
                ('Sudah dibayar', Rupiah.format(d.paid)),
                ('Sisa', Rupiah.format(d.left)),
                if (debt.dueDate != null) ('Jatuh tempo', DateFmt.longDate(debt.dueDate!, now: now)),
              ].indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.x8 + 2),
                  decoration: BoxDecoration(
                    border: i == (debt.dueDate == null ? 2 : 3) ? null : Border(bottom: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(k, style: t.caption.copyWith(fontSize: 14, color: c.sub))),
                      Text(v,
                          style: t.caption.copyWith(
                              fontSize: 14, fontWeight: k == 'Sisa' ? FontWeight.w700 : FontWeight.w600, color: c.ink)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (debt.note.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x12),
          Text(debt.note, style: t.caption.copyWith(color: c.sub)),
        ],
        const FieldLabel('Riwayat'),
        _HistoryLine(
          when: DateFmt.date(debt.occurredAt, now: now),
          what: '${owed ? 'Dipinjamkan' : 'Dipinjam'} ${Rupiah.format(debt.amount)}',
        ),
        for (final DebtPayment p in d.payments)
          _HistoryLine(
            when: DateFmt.date(p.paidAt, now: now),
            what:
                'Dibayar ${Rupiah.format(p.amount)}${p.walletId != null ? ' · ${walletNames[p.walletId] ?? ''}' : ''}',
            onDelete: () => _deletePayment(context, ref, p),
          ),
        const SizedBox(height: AppSpace.x16),
        if (d.left > 0) ...[
          AppButton(
            label: owed ? 'Catat pembayaran dari ${debt.name}' : 'Bayar ke ${debt.name}',
            large: true,
            onPressed: () => showAppSheet<void>(context,
                title: owed ? 'Catat pembayaran' : 'Bayar utang', builder: (_) => _PaySheet(d: d)),
          ),
          if (owed) ...[
            const SizedBox(height: AppSpace.x8),
            AppButton(
              key: const Key('tagih-wa'),
              label: 'Tagih lewat WhatsApp',
              icon: HiIcons.phone,
              variant: AppButtonVariant.soft,
              onPressed: () =>
                  showAppSheet<void>(context, title: 'Pesan pengingat', builder: (_) => _RemindSheet(d: d)),
            ),
          ],
          const SizedBox(height: AppSpace.x8),
        ],
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ubah',
                variant: AppButtonVariant.outline,
                onPressed: () => openDebtForm(context, existing: debt),
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: AppButton(
                  label: 'Hapus', variant: AppButtonVariant.danger, onPressed: () => _delete(context, ref, d)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deletePayment(BuildContext context, WidgetRef ref, DebtPayment p) async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus pembayaran ${Rupiah.format(p.amount)}?',
      body: p.walletId == null
          ? 'Sisa utangnya bertambah lagi.'
          : 'Sisa utangnya bertambah lagi dan saldo dompet dikembalikan.',
      confirm: 'Hapus',
      danger: true,
    );
    if (ok) await ref.read(appDatabaseProvider).debtsDao.removePayment(p.id);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, DebtWithPayments d) async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus catatan ${d.debt.name}?',
      body: 'Pembayarannya ikut terhapus. Saldo dompet yang tadinya berubah karena catatan ini dikembalikan.',
      confirm: 'Hapus',
      danger: true,
    );
    if (!ok) return;
    await ref.read(appDatabaseProvider).debtsDao.remove(d.debt.id);
    if (context.mounted) Navigator.pop(context);
  }
}

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({required this.when, required this.what, this.onDelete});

  final String when;
  final String what;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Pressable(
      onLongPress: onDelete,
      semanticLabel: '$when, $what',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x4),
        child: Row(
          children: [
            Text(when, style: t.caption.copyWith(color: c.sub)),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Text(what,
                  textAlign: TextAlign.right, style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan dompet + "Tidak dari dompet".
class _WalletChips extends ConsumerWidget {
  const _WalletChips({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    return Wrap(
      spacing: AppSpace.x8,
      runSpacing: AppSpace.x8,
      children: [
        AppChip(label: 'Tidak dari dompet', selected: selected == null, onTap: () => onChanged(null)),
        for (final w in wallets)
          AppChip(
            label: w.wallet.name,
            icon: AppIcons.of(w.wallet.icon),
            emoji: AppIcons.emojiOf(w.wallet.icon),
            selected: w.wallet.id == selected,
            onTap: () => onChanged(w.wallet.id),
          ),
      ],
    );
  }
}

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({required this.d, this.amount, this.walletId});

  final DebtWithPayments d;

  /// Isian dari Catat cepat; bawaan = lunasi sisa & dompet catatan.
  final int? amount;
  final int? walletId;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late final TextEditingController _amount = TextEditingController(
      text: Rupiah.digits(widget.amount != null && widget.amount! <= widget.d.left ? widget.amount! : widget.d.left));
  late int? _walletId = widget.walletId ?? widget.d.debt.walletId;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final DebtWithPayments d = widget.d;
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (amount <= 0) return setState(() => _error = 'Isi nominalnya.');
    if (amount > d.left) return setState(() => _error = 'Melebihi sisa ${Rupiah.format(d.left)}.');
    await ref
        .read(appDatabaseProvider)
        .debtsDao
        .pay(d.debt.id, amount: amount, paidAt: ref.read(clockProvider)(), walletId: _walletId);
    if (!mounted) return;
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    nav.pop();
    if (amount == d.left) {
      final bool owed = d.debt.direction == DebtDirection.piutang;
      await showCelebration(
        nav.context,
        title: owed ? '${d.debt.name} lunas!' : 'Utangmu lunas!',
        body: owed
            ? 'Pinjaman ${Rupiah.format(d.debt.amount)} sudah kembali semua.'
            : 'Utang ${Rupiah.format(d.debt.amount)} ke ${d.debt.name} sudah selesai. Lega!',
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('Tercatat · sisa ${Rupiah.format(d.left - amount)}')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DebtWithPayments d = widget.d;
    final bool owed = d.debt.direction == DebtDirection.piutang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: const InputDecoration(
              labelText: 'Nominal dibayar',
              prefixIcon: RupiahPrefix(),
              prefixIconConstraints: RupiahPrefix.constraints),
        ),
        const SizedBox(height: AppSpace.x12),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            AppChip(
              label: 'Lunasi ${Rupiah.format(d.left)}',
              selected: RupiahInputFormatter.parse(_amount.text) == d.left,
              onTap: () => setState(() => _amount.text = Rupiah.digits(d.left)),
            ),
            if (d.left >= 2000)
              AppChip(
                label: 'Separuh',
                selected: RupiahInputFormatter.parse(_amount.text) == d.left ~/ 2,
                onTap: () => setState(() => _amount.text = Rupiah.digits(d.left ~/ 2)),
              ),
          ],
        ),
        FieldLabel(owed ? 'Masuk ke dompet' : 'Dibayar dari dompet'),
        _WalletChips(selected: _walletId, onChanged: (v) => setState(() => _walletId = v)),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan pembayaran', large: true, onPressed: _save),
      ],
    );
  }
}

class _RemindSheet extends ConsumerStatefulWidget {
  const _RemindSheet({required this.d});

  final DebtWithPayments d;

  @override
  ConsumerState<_RemindSheet> createState() => _RemindSheetState();
}

class _RemindSheetState extends ConsumerState<_RemindSheet> {
  late final TextEditingController _text = TextEditingController(
    text: debtReminderText(
      name: widget.d.debt.name,
      left: widget.d.left,
      paid: widget.d.paid,
      date: widget.d.debt.occurredAt,
      rupiah: Rupiah.format,
      day: (d) => DateFmt.date(d, now: ref.read(clockProvider)()),
    ),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _text.text.trim();
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Menu Bagikan membuat HitungIn ke latar: jangan dikunci selama memilih aplikasi.
    final bool shared = await withAutoLockPaused(ref, () => ShareText.send(text, title: 'Kirim pengingat lewat'));
    nav.pop();
    if (!shared) messenger.showSnackBar(const SnackBar(content: Text('Pesan disalin — tempel di WhatsApp')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _text,
          minLines: 3,
          maxLines: 6,
          style: t.body,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Pesan'),
        ),
        const SizedBox(height: AppSpace.x8),
        Text('Bisa diubah dulu. Dikirim lewat menu Bagikan — HitungIn tidak membaca kontakmu.',
            style: t.caption.copyWith(color: c.muted, height: 1.5)),
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Kirim lewat WhatsApp', large: true, icon: HiIcons.phone, onPressed: _send),
      ],
    );
  }
}

/// Form catat baru / ubah.
Future<void> openDebtForm(BuildContext context, {Debt? existing, DebtDirection? direction, DebtDraft? draft}) =>
    showAppSheet<void>(
      context,
      title: existing == null ? 'Catat utang-piutang' : 'Ubah catatan',
      builder: (_) => _DebtForm(existing: existing, direction: draft?.direction ?? direction, draft: draft),
    );

class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({this.existing, this.direction, this.draft});

  final Debt? existing;
  final DebtDirection? direction;
  final DebtDraft? draft;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  late final Debt? _e = widget.existing;
  late DebtDirection _dir = _e?.direction ?? widget.direction ?? DebtDirection.piutang;
  late final TextEditingController _name = TextEditingController(text: _e?.name ?? widget.draft?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: _e != null
          ? Rupiah.digits(_e.amount)
          : (widget.draft?.amount == null ? '' : Rupiah.digits(widget.draft!.amount!)));
  late final TextEditingController _note = TextEditingController(text: _e?.note ?? '');
  late int? _walletId = _e?.walletId ?? widget.draft?.walletId;
  late DateTime _date = _e?.occurredAt ?? ref.read(clockProvider)();
  late DateTime? _due = _e?.dueDate;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, String help) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: help,
      );

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (name.isEmpty) return setState(() => _error = 'Isi nama orangnya.');
    if (amount <= 0) return setState(() => _error = 'Isi nominalnya.');
    final DebtsDao dao = ref.read(appDatabaseProvider).debtsDao;
    if (_e == null) {
      await dao.add(
        direction: _dir,
        name: name,
        amount: amount,
        occurredAt: _date,
        walletId: _walletId,
        dueDate: _due,
        note: _note.text,
      );
    } else {
      await dao.edit(_e.copyWith(
        direction: _dir,
        name: name,
        amount: amount,
        occurredAt: _date,
        walletId: Value(_walletId),
        dueDate: Value(_due),
        note: _note.text,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final bool lend = _dir == DebtDirection.piutang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSegmentedControl<DebtDirection>(
          options: DebtDirection.values,
          selected: _dir,
          labelOf: (d) => d == DebtDirection.piutang ? 'Aku meminjamkan' : 'Aku meminjam',
          onSurface: true,
          onChanged: (d) => setState(() => _dir = d),
        ),
        const SizedBox(height: AppSpace.x16),
        TextField(
          controller: _name,
          autofocus: _e == null && widget.draft == null,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
              labelText: 'Nama', hintText: lend ? 'Siapa yang pinjam?' : 'Pinjam dari siapa?', counterText: ''),
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: const InputDecoration(
              labelText: 'Nominal', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        FieldLabel(lend ? 'Diambil dari dompet' : 'Masuk ke dompet'),
        _WalletChips(selected: _walletId, onChanged: (v) => setState(() => _walletId = v)),
        const FieldLabel('Tanggal'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            AppChip(
              label: DateFmt.longDate(_date, now: now),
              icon: HiIcons.calendar,
              selected: true,
              onTap: () async {
                final DateTime? d = await _pick(_date, 'Tanggal');
                if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
              },
            ),
          ],
        ),
        const FieldLabel('Jatuh tempo (opsional)'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            AppChip(
              label: _due == null ? 'Tidak ada' : DateFmt.longDate(_due!, now: now),
              icon: HiIcons.calendar,
              selected: _due != null,
              onTap: () async {
                final DateTime? d = await _pick(_due ?? now.add(const Duration(days: 14)), 'Jatuh tempo');
                if (d != null) setState(() => _due = d);
              },
            ),
            if (_due != null) AppChip(label: 'Hapus jatuh tempo', onTap: () => setState(() => _due = null)),
          ],
        ),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _note,
          maxLength: 120,
          style: t.body,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)', counterText: ''),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
      ],
    );
  }
}
