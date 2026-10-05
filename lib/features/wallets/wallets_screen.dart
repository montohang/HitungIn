import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/color_swatches.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../security/app_gate.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/wallets_dao.dart';

final _allWalletsProvider = StreamProvider.autoDispose<List<WalletBalance>>(
  (ref) => ref.watch(appDatabaseProvider).walletsDao.watchBalances(includeArchived: true),
);

/// Jumlah transaksi tiap dompet bulan ini (keterangan baris).
final _txCountProvider = FutureProvider.autoDispose<Map<int, int>>((ref) {
  ref.watch(_allWalletsProvider); // ikut diperbarui saat saldo berubah
  final DateTime now = ref.watch(clockProvider)();
  final (DateTime from, DateTime to) = Dates.monthRange(DateTime(now.year, now.month));
  return ref.watch(appDatabaseProvider).walletsDao.txCounts(from, to);
});

String walletIconFor(WalletType type) => switch (type) {
      WalletType.tunai => 'cash',
      WalletType.bank => 'bank',
      WalletType.ewallet => 'ewallet',
      WalletType.lainnya => 'wallet',
    };

/// Inisial di lingkaran dompet: "Tunai" → "Rp", "Bank Jago" → "BJ", "GoPay" → "GP".
String walletInitials(Wallet w) {
  if (w.type == WalletType.tunai) return 'Rp';
  final List<String> words = w.name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
  if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
  final String n = words.isEmpty ? '?' : words.first;
  final List<String> caps = [for (final ch in n.split('')) if (ch != ch.toLowerCase()) ch];
  if (caps.length >= 2) return caps.take(2).join();
  return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
}

/// Kelompok desain: Tunai & bank (termasuk "Lainnya") lalu E-wallet.
bool _isEwallet(Wallet w) => w.type == WalletType.ewallet;

/// Dompet (Claude Design › Dompet): total + Pindah saldo + porsi saldo,
/// grup Tunai & bank / E-wallet. Ketuk → ubah; tahan & geser → urutkan.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final List<WalletBalance> all = ref.watch(_allWalletsProvider).valueOrNull ?? const [];
    final Map<int, int> counts = ref.watch(_txCountProvider).valueOrNull ?? const {};
    final List<WalletBalance> active = [for (final w in all) if (!w.wallet.archived) w];
    final List<WalletBalance> archived = [for (final w in all) if (w.wallet.archived) w];
    final int total = active.fold(0, (s, w) => s + w.balance);
    final List<(String, List<WalletBalance>)> groups = [
      ('Tunai & bank', [for (final w in active) if (!_isEwallet(w.wallet)) w]),
      ('E-wallet', [for (final w in active) if (_isEwallet(w.wallet)) w]),
    ];

    void reorder(int group, int from, int to) {
      final List<int> ids = [for (final w in groups[group].$2) w.wallet.id];
      final int id = ids.removeAt(from);
      ids.insert(to > from ? to - 1 : to, id);
      final List<int> order = [
        for (final (int g, (String, List<WalletBalance>) grp) in groups.indexed)
          ...(g == group ? ids : [for (final w in grp.$2) w.wallet.id]),
      ];
      ref.read(appDatabaseProvider).walletsDao.reorder(order);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: 'Dompet',
              large: true,
              trailing: _HeaderAction(label: '+ Tambah', onTap: () => _openForm(context, null)),
            ),
            const SizedBox(height: AppSpace.x16),
            _Summary(wallets: active, total: total),
            for (final (int g, (String title, List<WalletBalance> items)) in groups.indexed)
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.x4, 0, AppSpace.x4, AppSpace.x8),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub))),
                      Text(
                        Rupiah.format(items.fold(0, (s, w) => s + w.balance)),
                        style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub),
                      ),
                    ],
                  ),
                ),
                _GroupCard(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
                    onReorder: (from, to) => reorder(g, from, to),
                    children: [
                      for (final (int i, WalletBalance w) in items.indexed)
                        ReorderableDelayedDragStartListener(
                          key: ValueKey(w.wallet.id),
                          index: i,
                          child: _WalletRow(
                            item: w,
                            count: counts[w.wallet.id] ?? 0,
                            last: i == items.length - 1,
                            onTap: () => _openForm(context, w),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            if (archived.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x16),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.x4, 0, AppSpace.x4, AppSpace.x8),
                child: Text('Diarsipkan', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.sub)),
              ),
              Opacity(
                opacity: 0.6,
                child: _GroupCard(
                  child: Column(
                    children: [
                      for (final (int i, WalletBalance w) in archived.indexed)
                        _WalletRow(
                          item: w,
                          count: counts[w.wallet.id] ?? 0,
                          last: i == archived.length - 1,
                          onTap: () => _openForm(context, w),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.x16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
              decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(HiIcons.info, size: 18, color: c.sub),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: Text(
                      'Saldo di sini dihitung dari catatanmu, bukan tersambung ke bank. Kalau berbeda, ketuk dompet '
                      'lalu isi "Saldo sekarang". Tahan & geser untuk mengubah urutan.',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, height: 1.5, color: c.sub),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openForm(BuildContext context, WalletBalance? existing) => showAppSheet<void>(
        context,
        title: existing == null ? 'Dompet baru' : 'Ubah dompet',
        builder: (_) => _WalletForm(existing: existing),
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label.replaceAll('+ ', ''),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
        child: Text(label, style: context.text.title.copyWith(fontSize: 14, color: c.accentText)),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: context.colors.line),
        ),
        child: child,
      );
}

/// Total saldo + Pindah saldo + bar porsi saldo per dompet.
class _Summary extends StatelessWidget {
  const _Summary({required this.wallets, required this.total});

  final List<WalletBalance> wallets;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<WalletBalance> positive = [for (final w in wallets) if (w.balance > 0) w];
    final int sum = positive.fold(0, (s, w) => s + w.balance);
    return Container(
      padding: const EdgeInsets.all(AppSpace.card),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total saldo · ${wallets.length} dompet', style: t.caption.copyWith(color: c.muted)),
                    const SizedBox(height: AppSpace.x2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Rupiah.format(total), style: t.amountL.copyWith(fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              if (wallets.length > 1)
                Pressable(
                  onTap: () => context.push(Uri(path: Routes.catat, queryParameters: {'kind': 'transfer'}).toString()),
                  semanticLabel: 'Pindah saldo',
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                    decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.smAll),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(HiIcons.swap, size: 16, color: c.onAccent),
                        const SizedBox(width: AppSpace.x8),
                        Text('Pindah saldo', style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.onAccent)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (sum > 0) ...[
            const SizedBox(height: AppSpace.x12),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: AppRadius.pillAll,
                child: SizedBox(
                  height: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (int i, WalletBalance w) in positive.indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: (w.balance * 1000 ~/ sum).clamp(1, 1000),
                          child: ColoredBox(color: AppPalette.of(context, w.wallet.color)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x12),
            Wrap(
              spacing: AppSpace.x12,
              runSpacing: AppSpace.x4,
              children: [
                for (final w in positive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppPalette.of(context, w.wallet.color),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpace.x4),
                      Text(
                        '${w.wallet.name} ${(w.balance * 100 / sum).round()}%',
                        style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.sub),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.item, required this.count, required this.last, required this.onTap});

  final WalletBalance item;
  final int count;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Wallet w = item.wallet;
    return Pressable.card(
      onTap: onTap,
      semanticLabel: '${w.name}, ${Rupiah.format(item.balance)}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
        decoration: BoxDecoration(
          color: c.surface,
          border: last ? null : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppPalette.soft(context, w.color), borderRadius: AppRadius.smAll),
              child: Text(
                walletInitials(w),
                style: t.caption.copyWith(fontWeight: FontWeight.w800, color: AppPalette.ink(context, w.color)),
              ),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name, style: t.item),
                  const SizedBox(height: AppSpace.x2),
                  Text(
                    '${w.type.label} · ${count == 0 ? 'belum ada transaksi' : '$count transaksi'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Text(
              Rupiah.format(item.balance),
              style: t.number.copyWith(color: item.balance < 0 ? c.danger : c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletForm extends ConsumerStatefulWidget {
  const _WalletForm({this.existing});

  final WalletBalance? existing;

  @override
  ConsumerState<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends ConsumerState<_WalletForm> {
  late final Wallet? _w = widget.existing?.wallet;
  late final TextEditingController _name = TextEditingController(text: _w?.name ?? '');

  /// Dompet baru: saldo awal. Ubah: saldo sekarang (menyesuaikan saldo awal).
  late final TextEditingController _balance = TextEditingController(
    text: _w == null ? '' : Rupiah.digits(widget.existing!.balance.abs()),
  );
  late WalletType _type = _w?.type ?? WalletType.bank;
  late int _color = _w?.color ?? -1;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Isi nama dompet.');
    final dao = ref.read(appDatabaseProvider).walletsDao;
    final bool taken = (await dao.all()).any((w) => w.id != _w?.id && w.name.toLowerCase() == name.toLowerCase());
    if (taken) return setState(() => _error = 'Nama dompet sudah dipakai.');
    final int amount = RupiahInputFormatter.parse(_balance.text);
    if (_w == null) {
      await dao.add(
        name: name,
        type: _type,
        initialBalance: amount,
        icon: walletIconFor(_type),
        color: _color < 0 ? null : _color,
      );
    } else {
      // Saldo sekarang negatif tidak bisa diketik; pertahankan tandanya bila tidak diubah.
      final int current = widget.existing!.balance;
      final int target = current < 0 && amount == current.abs() ? current : amount;
      await dao.edit(_w.copyWith(
        name: name,
        type: _type,
        initialBalance: _w.initialBalance + (target - current),
        icon: walletIconFor(_type),
        color: _color < 0 ? _w.color : _color,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _archive(bool archived) async {
    final dao = ref.read(appDatabaseProvider).walletsDao;
    if (archived && (await dao.active()).length <= 1) {
      return setState(() => _error = 'Minimal harus ada satu dompet aktif.');
    }
    await dao.setArchived(_w!.id, archived);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final dao = ref.read(appDatabaseProvider).walletsDao;
    if (!_w!.archived && (await dao.active()).length <= 1) {
      return setState(() => _error = 'Minimal harus ada satu dompet aktif.');
    }
    if (!mounted) return;
    final bool ok = await confirmDialog(
      context,
      title: 'Hapus ${_w.name}?',
      body: 'Dompet yang belum punya transaksi akan dihapus permanen.',
      confirm: 'Hapus',
      danger: true,
    );
    if (!ok) return;
    final bool deleted = await dao.deleteIfUnused(_w.id);
    if (!mounted) return;
    if (!deleted) {
      return setState(() => _error = 'Dompet ini sudah punya transaksi. Arsipkan saja supaya riwayat tetap utuh.');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          autofocus: _w == null,
          maxLength: 40,
          style: t.item,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama dompet', counterText: ''),
        ),
        const FieldLabel('Jenis'),
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final type in WalletType.values)
              AppChip(
                label: type.label,
                icon: AppIcons.of(walletIconFor(type)),
                selected: type == _type,
                onTap: () => setState(() => _type = type),
              ),
          ],
        ),
        const FieldLabel('Warna'),
        ColorSwatches(selected: _color, onChanged: (i) => setState(() => _color = i)),
        const SizedBox(height: AppSpace.x16),
        TextField(
          key: const Key('saldo-dompet'),
          controller: _balance,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          style: t.number,
          decoration: InputDecoration(
            labelText: _w == null ? 'Saldo awal' : 'Saldo sekarang',
            helperText: _w == null
                ? 'Saldo saat ini, sebelum transaksi pertama dicatat.'
                : 'Ubah bila berbeda dengan saldo aslinya (sesuaikan saldo).',
            prefixIcon: const RupiahPrefix(),
            prefixIconConstraints: RupiahPrefix.constraints,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x12),
          Text(_error!, style: t.caption.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(label: 'Simpan', large: true, onPressed: _save),
        if (_w != null) ...[
          const SizedBox(height: AppSpace.x8),
          AppButton(
            label: 'Lihat riwayat',
            icon: HiIcons.history,
            variant: AppButtonVariant.soft,
            onPressed: () {
              final GoRouter router = GoRouter.of(context);
              Navigator.pop(context);
              router.push(Uri(path: Routes.riwayat, queryParameters: {'wallet': '${_w.id}'}).toString());
            },
          ),
          const SizedBox(height: AppSpace.x8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _w.archived ? 'Aktifkan lagi' : 'Arsipkan',
                  variant: AppButtonVariant.outline,
                  onPressed: () => _archive(!_w.archived),
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(child: AppButton(label: 'Hapus', variant: AppButtonVariant.danger, onPressed: _delete)),
            ],
          ),
        ],
      ],
    );
  }
}
