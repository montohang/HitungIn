import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart';
import 'data/bill_due.dart';
import 'data/bill_reminders.dart';
import 'reminder_scheduler.dart';

final activeBillsProvider = StreamProvider<List<Bill>>((ref) => ref.watch(appDatabaseProvider).billsDao.watchActive());

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<Bill>> async = ref.watch(activeBillsProvider);
    final List<Bill> bills = async.valueOrNull ?? const [];
    final int monthTotal =
        bills.where((b) => b.nextDue.year == now.year && b.nextDue.month == now.month).fold(0, (s, b) => s + b.amount);

    return Scaffold(
      appBar: AppBar(title: Text('Tagihan', style: t.screenTitle)),
      floatingActionButton: AppFab(label: 'Tambah tagihan', onPressed: () => addBill(context, ref, bills.length)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8, bottom: 96),
        children: [
          const _ReminderCard(),
          const SizedBox(height: AppSpace.x12),
          if (async.hasValue && bills.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.event_repeat_outlined,
                title: 'Belum ada tagihan',
                body: 'Catat kos, listrik, cicilan, atau langganan — HitungIn menandai yang sudah dekat jatuh tempo.',
                action: 'Tambah tagihan',
                onAction: () => addBill(context, ref, bills.length),
              ),
            )
          else ...[
            if (monthTotal > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x12),
                child: Text('Jatuh tempo bulan ini: ${Rupiah.format(monthTotal)}',
                    style: t.caption.copyWith(color: c.muted)),
              ),
            for (final b in bills)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.x8),
                child: BillCard(bill: b, now: now),
              ),
          ],
        ],
      ),
    );
  }
}

/// Kartu tagihan dengan status & tombol Bayar. Dipakai juga di beranda.
class BillCard extends ConsumerWidget {
  const BillCard({super.key, required this.bill, required this.now});

  final Bill bill;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final BillDue due = billDue(bill, now);
    final Category? category = (ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        .where((cat) => cat.id == bill.categoryId)
        .firstOrNull;
    final (Color bg, Color fg) = switch (due.state) {
      BillDueState.terlambat => (c.dangerSoft, c.danger),
      BillDueState.hariIni || BillDueState.segera => (c.warnSoft, c.warnInk),
      BillDueState.nanti => (c.chip, c.sub),
    };
    return AppCard(
      onTap: () => openBillForm(context, bill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.of(category?.icon ?? 'bills')),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name, style: t.item),
                    Text(
                      '${DateFmt.date(bill.nextDue, now: now)} · ${bill.repeat.label}',
                      style: t.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              Text(Rupiah.format(bill.amount), style: t.number),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              AppBadge(billDueLabel(due), background: bg, foreground: fg),
              const Spacer(),
              AppButton(
                label: 'Bayar',
                icon: Icons.check,
                variant: AppButtonVariant.soft,
                expand: false,
                onPressed: () => _pay(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) => showAppSheet<void>(
        context,
        title: 'Bayar ${bill.name}',
        builder: (_) => _PaySheet(bill: bill),
      );
}

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({required this.bill});

  final Bill bill;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late final TextEditingController _amount = TextEditingController(text: Rupiah.digits(widget.bill.amount));
  late int? _walletId = widget.bill.walletId;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (amount <= 0) return setState(() => _error = 'Isi nominalnya.');
    if (_walletId == null) return setState(() => _error = 'Pilih dompet.');
    await ref
        .read(appDatabaseProvider)
        .billsDao
        .pay(widget.bill, walletId: _walletId, amount: amount, paidAt: ref.read(clockProvider)());
    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(widget.bill.repeat == BillRepeat.sekali
          ? 'Lunas · tercatat sebagai pengeluaran'
          : 'Tercatat · jatuh tempo berikutnya sudah dimajukan'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dicatat sebagai pengeluaran hari ini.', style: t.caption.copyWith(color: c.muted)),
        const SizedBox(height: AppSpace.x12),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: const InputDecoration(
              labelText: 'Nominal', prefixIcon: RupiahPrefix(), prefixIconConstraints: RupiahPrefix.constraints),
        ),
        const FieldLabel('Bayar dari'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final w in wallets)
              AppChip(
                label: '${w.wallet.name} · ${Rupiah.compact(w.balance)}',
                icon: AppIcons.of(w.wallet.icon),
                selected: w.wallet.id == _walletId,
                onTap: () => setState(() => _walletId = w.wallet.id),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Tandai lunas', large: true, onPressed: _confirm),
      ],
    );
  }
}

/// Tambah tagihan, atau tawarkan Pro bila kuota versi gratis habis.
void addBill(BuildContext context, WidgetRef ref, int activeCount) {
  if (!FreeLimits.canAddBill(active: activeCount, isPro: ref.read(isProProvider))) {
    openPremium(context, ProReason.tagihan);
    return;
  }
  openBillForm(context, null);
}

Future<void> openBillForm(BuildContext context, Bill? existing) => showAppSheet<void>(
      context,
      title: existing == null ? 'Tagihan baru' : 'Ubah tagihan',
      builder: (_) => _BillForm(existing: existing),
    );

class _BillForm extends ConsumerStatefulWidget {
  const _BillForm({this.existing});

  final Bill? existing;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  late final Bill? _b = widget.existing;
  late final TextEditingController _name = TextEditingController(text: _b?.name ?? '');
  late final TextEditingController _amount = TextEditingController(text: _b == null ? '' : Rupiah.digits(_b.amount));
  late DateTime _due = _b?.nextDue ?? ref.read(clockProvider)();
  late BillRepeat _repeat = _b?.repeat ?? BillRepeat.bulanan;
  late int _remind = _b?.remindDaysBefore ?? 3;
  late int? _categoryId = _b?.categoryId;
  late int? _walletId = _b?.walletId;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Jatuh tempo',
    );
    if (d != null) setState(() => _due = d);
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int amount = RupiahInputFormatter.parse(_amount.text);
    if (name.isEmpty) return setState(() => _error = 'Isi nama tagihan.');
    if (amount <= 0) return setState(() => _error = 'Isi nominalnya.');
    final dao = ref.read(appDatabaseProvider).billsDao;
    if (_b == null) {
      await dao.add(
        name: name,
        amount: amount,
        dueDate: _due,
        repeat: _repeat,
        categoryId: _categoryId,
        walletId: _walletId,
        remindDaysBefore: _remind,
      );
    } else {
      await dao.edit(_b.copyWith(
        name: name,
        amount: amount,
        nextDue: _due,
        anchorDay: _due.day,
        repeat: _repeat,
        remindDaysBefore: _remind,
        categoryId: Value(_categoryId),
        walletId: Value(_walletId),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus ${_b!.name}?',
      body: 'Transaksi pembayaran yang sudah tercatat tidak ikut terhapus.',
      confirm: 'Hapus',
      danger: true,
    );
    if (!ok) return;
    await ref.read(appDatabaseProvider).billsDao.remove(_b.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<Category> cats = [
      for (final cat in ref.watch(activeCategoriesProvider).valueOrNull ?? const <Category>[])
        if (cat.kind == TxKind.pengeluaran) cat,
    ];
    final wallets = ref.watch(walletBalancesProvider).valueOrNull ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          autofocus: _b == null,
          maxLength: 60,
          style: t.item,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Nama tagihan', hintText: 'Kos, listrik, cicilan motor', counterText: ''),
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
        const FieldLabel('Jatuh tempo'),
        AppChip(label: DateFmt.longDate(_due), icon: Icons.calendar_today_outlined, selected: true, onTap: _pickDate),
        const FieldLabel('Ulangi'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final r in BillRepeat.values)
              AppChip(label: r.label, selected: r == _repeat, onTap: () => setState(() => _repeat = r)),
          ],
        ),
        const FieldLabel('Tandai sejak'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final d in const [0, 1, 3, 7])
              AppChip(
                label: d == 0 ? 'Hari H' : '$d hari sebelum',
                selected: d == _remind,
                onTap: () => setState(() => _remind = d),
              ),
          ],
        ),
        const FieldLabel('Kategori'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final cat in cats)
              AppChip(
                label: cat.name,
                icon: AppIcons.of(cat.icon),
                selected: cat.id == _categoryId,
                onTap: () => setState(() => _categoryId = cat.id == _categoryId ? null : cat.id),
              ),
          ],
        ),
        const FieldLabel('Biasa dibayar dari (opsional)'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final w in wallets)
              AppChip(
                label: w.wallet.name,
                icon: AppIcons.of(w.wallet.icon),
                selected: w.wallet.id == _walletId,
                onTap: () => setState(() => _walletId = w.wallet.id == _walletId ? null : w.wallet.id),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
        if (_b != null) ...[
          const SizedBox(height: AppSpace.x8),
          AppButton(label: 'Hapus tagihan', variant: AppButtonVariant.danger, onPressed: _delete),
        ],
      ],
    );
  }
}

/// Pengaturan notifikasi pengingat (Pro). Pengingat di dalam aplikasi
/// (status jatuh tempo, kartu di beranda) tetap untuk semua pengguna.
class _ReminderCard extends ConsumerWidget {
  const _ReminderCard();

  Future<void> _toggle(WidgetRef ref, ReminderSettings s, bool on) async {
    if (on && !await ref.read(reminderSchedulerProvider).permissionGranted()) {
      await withAutoLockPaused(ref, () => ref.read(reminderSchedulerProvider).requestPermission());
      ref.invalidate(notificationPermissionProvider);
    }
    await ref.read(reminderSettingsProvider.notifier).set((enabled: on, hour: s.hour));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool isPro = ref.watch(isProProvider);
    if (!FreeLimits.canUseBillNotifications(isPro: isPro)) {
      return AppCard(
        onTap: () => openPremium(context, ProReason.notifikasi),
        child: Row(
          children: [
            const IconTile(icon: Icons.notifications_outlined, size: 40),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifikasi pengingat', style: t.item),
                  Text('Diingatkan sebelum jatuh tempo, walau aplikasi tertutup',
                      style: t.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
            const AppBadge.pro(),
          ],
        ),
      );
    }

    final ReminderSettings? s = ref.watch(reminderSettingsProvider).valueOrNull;
    if (s == null) return const SizedBox.shrink();
    final bool granted = ref.watch(notificationPermissionProvider).valueOrNull ?? true;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: Icons.notifications_outlined, size: 40),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifikasi pengingat', style: t.item),
                    Text(
                      s.enabled ? 'H-n sesuai "Tandai sejak" dan di hari H' : 'Mati',
                      style: t.caption.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: s.enabled, activeTrackColor: c.accent, onChanged: (v) => _toggle(ref, s, v)),
            ],
          ),
          if (s.enabled) ...[
            const SizedBox(height: AppSpace.x12),
            Wrap(
              spacing: AppSpace.x8,
              runSpacing: AppSpace.x8,
              children: [
                for (final h in reminderHours)
                  AppChip(
                    label: '${h.toString().padLeft(2, '0')}.00',
                    selected: h == s.hour,
                    onTap: () => ref.read(reminderSettingsProvider.notifier).set((enabled: true, hour: h)),
                  ),
              ],
            ),
            if (!granted) ...[
              const SizedBox(height: AppSpace.x12),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: c.warnInk),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: Text('Notifikasi HitungIn sedang dimatikan di pengaturan HP.',
                        style: t.caption.copyWith(color: c.warnInk)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await withAutoLockPaused(ref, () => ref.read(reminderSchedulerProvider).requestPermission());
                      ref.invalidate(notificationPermissionProvider);
                    },
                    child: const Text('Izinkan'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
