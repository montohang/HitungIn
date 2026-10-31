import 'dart:ui' show ImageFilter;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/utils/rupiah_input.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rupiah_prefix.dart';
import '../../core/widgets/screen_header.dart';
import '../premium/data/pro_limits.dart';
import '../premium/pro_controller.dart';
import '../premium/widgets/pro_teaser.dart' show openPremium;
import '../settings/widgets/settings_tile.dart' show showAppSheet;
import 'data/net_worth.dart';
import 'networth_provider.dart';

/// Warna kelompok komposisi (identitas juga ditulis sebagai label).
Color netGroupColor(BuildContext context, NetGroup g) => switch (g) {
      NetGroup.dompet => context.colors.accent,
      NetGroup.emas => const Color(0xFFD99A06),
      NetGroup.investasi => context.colors.good,
      NetGroup.properti => const Color(0xFF0E7490),
      NetGroup.lainnya => const Color(0xFFBE185D),
    };

IconData netLineIcon(String key) => switch (key) {
      'wallet' => HiIcons.wallet,
      'debtSwap' => HiIcons.debtSwap,
      'installment' => HiIcons.installment,
      'emas' => HiIcons.coin,
      'investasi' => HiIcons.trendUp,
      'properti' => HiIcons.home,
      'pinjaman' => HiIcons.bank,
      _ => HiIcons.dots,
    };

/// Kekayaan bersih (P3h, Claude Design › Kekayaan bersih).
class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final NetWorth? w = ref.watch(netWorthProvider);
    final bool isPro = ref.watch(isProProvider);
    final DateTime now = ref.watch(clockProvider)();
    final List<NetSnapshot> snaps = ref.watch(netSnapshotsProvider).valueOrNull ?? const [];

    Future<void> add({bool liability = false}) async {
      if (!isPro) {
        openPremium(context, ProReason.kekayaan);
        return;
      }
      await openNetItemSheet(context, ref, liability: liability);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            const ScreenHeader(title: 'Kekayaan bersih'),
            const SizedBox(height: AppSpace.x16),
            if (w == null)
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            else ...[
              _Hero(w: w, delta: netWorthDelta(snaps, w, now), now: now),
              const SizedBox(height: AppSpace.x12),
              _Trend(snaps: snaps, now: now, locked: !isPro),
              const SizedBox(height: AppSpace.x16),
              _SectionTitle('Aset', Rupiah.format(w.totalAssets)),
              const SizedBox(height: AppSpace.x8),
              _Composition(w: w),
              const SizedBox(height: AppSpace.x8),
              _LineList(lines: w.assets, now: now, liability: false),
              const SizedBox(height: AppSpace.x8),
              _AddButton(label: 'Tambah aset', pro: !isPro, onTap: add),
              const SizedBox(height: AppSpace.x24),
              _SectionTitle('Kewajiban', w.totalLiabilities == 0 ? Rupiah.format(0) : '−${Rupiah.format(w.totalLiabilities)}'),
              const SizedBox(height: AppSpace.x8),
              if (w.liabilities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpace.x16),
                  decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                  child: Text('Tidak ada utang, cicilan, atau pinjaman yang tercatat.', style: t.caption.copyWith(color: c.muted)),
                )
              else
                _LineList(lines: w.liabilities, now: now, liability: true),
              const SizedBox(height: AppSpace.x8),
              _AddButton(label: 'Tambah pinjaman lain', pro: !isPro, onTap: () => add(liability: true)),
              const SizedBox(height: AppSpace.x12),
              Text(
                'Nilai dihitung di HP-mu. Harga emas & investasi diisi sendiri — HitungIn tidak mengambil harga dari internet.',
                style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.w, required this.delta, required this.now});

  final NetWorth w;
  final int? delta;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Color start = Color.lerp(c.accent, Colors.black, 0.15)!;
    final Color end = Color.lerp(c.accent, Colors.white, 0.15)!;
    TextStyle white(double size, FontWeight wt) => t.title.copyWith(fontSize: size, fontWeight: wt, color: Colors.white);
    return Container(
      key: const Key('kekayaan-hero'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(borderRadius: AppRadius.lgAll, gradient: LinearGradient(colors: [start, end])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kekayaan bersih · ${now.day} ${DateFmt.monthsShort[now.month - 1]} ${now.year}',
              style: t.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: AppSpace.x4),
          Text(Rupiah.format(w.net), style: t.amountXL.copyWith(color: Colors.white, fontSize: 32)),
          if (delta != null) ...[
            const SizedBox(height: AppSpace.x8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: AppRadius.pillAll),
              child: Text(
                delta == 0 ? 'Sama dengan bulan lalu' : '${delta! > 0 ? '▲' : '▼'} ${Rupiah.compact(delta!.abs())} dari bulan lalu',
                style: white(12, FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.x12),
          Row(children: [
            for (final (String label, int v) in [('Aset', w.totalAssets), ('Kewajiban', -w.totalLiabilities)]) ...[
              if (label == 'Kewajiban') const SizedBox(width: AppSpace.x8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: AppRadius.mdAll),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: t.label.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                    Text(v < 0 ? '−${Rupiah.format(-v)}' : Rupiah.format(v), style: white(16, FontWeight.w800)),
                  ]),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.snaps, required this.now, required this.locked});

  final List<NetSnapshot> snaps;
  final DateTime now;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final List<DateTime> months = [for (int k = 11; k >= 0; k--) DateTime(now.year, now.month - k)];
    final Map<DateTime, int> net = {for (final s in snaps) s.month: s.assets - s.liabilities};
    final int max = net.values.fold(1, (m, v) => v > m ? v : m);
    final Widget bars = SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (int i, DateTime m) in months.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: ((net[m] ?? 0).clamp(0, max) / max * 96).clamp(net.containsKey(m) ? 4 : 0, 96).toDouble(),
                decoration: BoxDecoration(
                  color: i == months.length - 1 ? c.accent : c.accent.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.x16, 14, AppSpace.x16, 14),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('Tren 12 bulan', style: t.title.copyWith(fontSize: 14))),
            Text('${DateFmt.monthsShort[months.first.month - 1]} ${months.first.year} – ${DateFmt.monthsShort[now.month - 1]} ${now.year}',
                style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
          ]),
          const SizedBox(height: AppSpace.x12),
          if (locked)
            Pressable(
              onTap: () => openPremium(context, ProReason.kekayaan),
              semanticLabel: 'Lihat tren kekayaan dengan Pro',
              child: Stack(alignment: Alignment.center, children: [
                ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: bars),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const AppBadge.pro(),
                  const SizedBox(width: AppSpace.x8),
                  Text('Lihat tren kekayaan tiap bulan', style: t.title.copyWith(fontSize: 13)),
                ]),
              ]),
            )
          else if (net.length < 2)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bars,
              const SizedBox(height: AppSpace.x8),
              Text('Tren terisi otomatis setiap bulan.', style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
            ])
          else
            bars,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
        child: Row(children: [
          Expanded(child: Text(title, style: context.text.section.copyWith(fontSize: 17))),
          Text(value, style: context.text.title.copyWith(fontSize: 13, color: context.colors.sub)),
        ]),
      );
}

class _Composition extends StatelessWidget {
  const _Composition({required this.w});

  final NetWorth w;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Map<NetGroup, int> comp = w.composition;
    final int total = comp.values.fold(0, (s, v) => s + v);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: SizedBox(
            height: 10,
            child: Row(children: [
              for (final (int i, MapEntry<NetGroup, int> e) in comp.entries.indexed)
                Expanded(
                  flex: (e.value * 1000 ~/ total).clamp(1, 1000),
                  child: Container(margin: EdgeInsets.only(left: i == 0 ? 0 : 2), color: netGroupColor(context, e.key)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: AppSpace.x8),
        Wrap(spacing: AppSpace.x12, runSpacing: 4, children: [
          for (final MapEntry<NetGroup, int> e in comp.entries)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: netGroupColor(context, e.key), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${e.key.label} ${(e.value * 100 / total).round()}%',
                  style: context.text.label.copyWith(fontWeight: FontWeight.w500, color: c.sub)),
            ]),
        ]),
      ],
    );
  }
}

class _LineList extends ConsumerWidget {
  const _LineList({required this.lines, required this.now, required this.liability});

  final List<NetLine> lines;
  final DateTime now;
  final bool liability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(children: [
        for (final (int i, NetLine l) in lines.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: i == lines.length - 1 ? null : Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: liability ? c.dangerSoft : c.accentSoft, borderRadius: AppRadius.smAll),
                child: Icon(netLineIcon(l.icon), size: 18, color: liability ? c.danger : c.accentText),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
                    Text(l.name, style: t.item.copyWith(fontSize: 14)),
                    if (l.item == null) AppBadge('OTOMATIS', background: c.chip, foreground: c.sub),
                  ]),
                  Text(
                    l.hint,
                    style: t.label.copyWith(
                      fontWeight: FontWeight.w500,
                      color: l.item != null && netItemStale(l.item!, now) ? c.warnInk : c.muted,
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: AppSpace.x8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(liability ? '−${Rupiah.format(l.value)}' : Rupiah.format(l.value), style: t.number.copyWith(fontSize: 14)),
                if (l.item != null) ...[
                  const SizedBox(height: 4),
                  Pressable(
                    key: Key('perbarui-${l.item!.id}'),
                    onTap: () => openNetItemSheet(context, ref, item: l.item),
                    semanticLabel: 'Perbarui ${l.name}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: 3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: c.line)),
                      child: Text('Perbarui', style: t.label.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: c.accentText)),
                    ),
                  ),
                ],
              ]),
            ]),
          ),
      ]),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.pro, required this.onTap});

  final String label;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 44,
        decoration: BoxDecoration(borderRadius: AppRadius.mdAll, border: Border.all(color: c.line2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(HiIcons.plus, size: 16, color: c.accentText),
          const SizedBox(width: 6),
          Text(label, style: context.text.title.copyWith(fontSize: 14, color: c.accentText)),
          if (pro) ...[const SizedBox(width: 6), const AppBadge.pro()],
        ]),
      ),
    );
  }
}

/// Lembar tambah / perbarui aset atau pinjaman manual.
Future<void> openNetItemSheet(BuildContext context, WidgetRef ref, {NetItem? item, bool liability = false}) async {
  final DateTime now = ref.read(clockProvider)();
  final _ItemResult? r = await showAppSheet<_ItemResult>(
    context,
    title: item != null ? 'Perbarui ${item.name}' : (liability ? 'Tambah pinjaman' : 'Tambah aset'),
    builder: (_) => _NetItemForm(item: item, liability: liability),
  );
  if (r == null) return;
  final dao = ref.read(appDatabaseProvider).netWorthDao;
  if (r.delete && item != null) {
    await dao.remove(item.id);
    return;
  }
  if (item == null) {
    await dao.add(kind: r.kind, name: r.name, value: r.value, milligrams: r.mg, pricePerGram: r.price, now: now);
  } else {
    await dao.edit(item.copyWith(name: r.name, value: r.value, milligrams: Value(r.mg), pricePerGram: Value(r.price)), now: now);
  }
}

typedef _ItemResult = ({NetItemKind kind, String name, int value, int? mg, int? price, bool delete});

class _NetItemForm extends StatefulWidget {
  const _NetItemForm({this.item, this.liability = false});

  final NetItem? item;
  final bool liability;

  @override
  State<_NetItemForm> createState() => _NetItemFormState();
}

class _NetItemFormState extends State<_NetItemForm> {
  late NetItemKind _kind = widget.item?.kind ?? (widget.liability ? NetItemKind.pinjaman : NetItemKind.emas);
  late final TextEditingController _name = TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _value =
      TextEditingController(text: (widget.item?.value ?? 0) == 0 ? '' : Rupiah.digits(widget.item!.value));
  late final TextEditingController _grams =
      TextEditingController(text: widget.item?.milligrams == null ? '' : formatGrams(widget.item!.milligrams!));
  late final TextEditingController _price =
      TextEditingController(text: widget.item?.pricePerGram == null ? '' : Rupiah.digits(widget.item!.pricePerGram!));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _grams.dispose();
    _price.dispose();
    super.dispose();
  }

  bool get _gold => _kind == NetItemKind.emas;

  int get _goldValue {
    final int mg = parseGrams(_grams.text) ?? 0;
    final int price = RupiahInputFormatter.parse(_price.text);
    return (mg * price / 1000).round();
  }

  void _save() {
    final String name = _name.text.trim().isEmpty && _gold ? 'Emas' : _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama wajib diisi.');
      return;
    }
    if (_gold) {
      final int? mg = parseGrams(_grams.text);
      final int price = RupiahInputFormatter.parse(_price.text);
      if (mg == null || mg <= 0 || price <= 0) {
        setState(() => _error = 'Isi berat (gram) dan harga per gram.');
        return;
      }
      Navigator.pop(context, (kind: _kind, name: name, value: 0, mg: mg, price: price, delete: false));
      return;
    }
    Navigator.pop(context, (kind: _kind, name: name, value: RupiahInputFormatter.parse(_value.text), mg: null, price: null, delete: false));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final NetItem? item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item == null && !widget.liability) ...[
          Wrap(spacing: AppSpace.x8, runSpacing: AppSpace.x8, children: [
            for (final NetItemKind k in NetItemKind.values)
              if (!k.isLiability)
                AppChip(
                  label: k.label,
                  icon: netLineIcon(k.name),
                  selected: k == _kind,
                  onTap: () => setState(() {
                    _kind = k;
                    _error = null;
                  }),
                ),
          ]),
          const SizedBox(height: AppSpace.x16),
        ],
        if (!_gold || item != null)
          TextField(
            key: const Key('aset-nama'),
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nama',
              hintText: switch (_kind) {
                NetItemKind.emas => 'Emas',
                NetItemKind.investasi => 'Reksadana pasar uang',
                NetItemKind.properti => 'Motor',
                NetItemKind.pinjaman => 'KTA Bank',
                NetItemKind.lainnya => 'Jam tangan',
              },
              counterText: '',
            ),
          ),
        if (_gold) ...[
          if (item != null) const SizedBox(height: AppSpace.x12),
          Row(children: [
            Expanded(
              flex: 10,
              child: TextField(
                key: const Key('aset-gram'),
                controller: _grams,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(labelText: 'Berat (gram)'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              flex: 14,
              child: TextField(
                key: const Key('aset-harga'),
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Harga per gram',
                  prefixIcon: RupiahPrefix(),
                  prefixIconConstraints: RupiahPrefix.constraints,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ]),
          const SizedBox(height: AppSpace.x12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: 10),
            decoration: BoxDecoration(color: c.chip, borderRadius: AppRadius.smAll),
            child: Row(children: [
              Expanded(child: Text('Nilai sekarang', style: t.caption.copyWith(color: c.sub))),
              Text(Rupiah.format(_goldValue), style: t.number.copyWith(fontWeight: FontWeight.w800)),
            ]),
          ),
          if (item?.pricePerGram != null) ...[
            const SizedBox(height: AppSpace.x8),
            Text(
              'Harga sebelumnya ${Rupiah.format(item!.pricePerGram!)}/gram · ${DateFmt.dayLabel(item.updatedAt)}. '
              'Cek harga di toko/aplikasi emasmu, lalu isi di sini.',
              style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
            ),
          ],
        ] else ...[
          const SizedBox(height: AppSpace.x12),
          TextField(
            key: const Key('aset-nilai'),
            controller: _value,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: InputDecoration(
              labelText: switch (_kind) {
                NetItemKind.properti => 'Nilai taksiran',
                NetItemKind.pinjaman => 'Sisa pokok',
                _ => 'Nilai saat ini',
              },
              prefixIcon: const RupiahPrefix(),
              prefixIconConstraints: RupiahPrefix.constraints,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.x8),
          Text(_error!, style: t.label.copyWith(color: c.danger)),
        ],
        const SizedBox(height: AppSpace.x16),
        AppButton(key: const Key('aset-simpan'), label: 'Simpan', onPressed: _save),
        if (item != null) ...[
          const SizedBox(height: AppSpace.x8),
          AppButton(
            label: 'Hapus',
            variant: AppButtonVariant.danger,
            onPressed: () => Navigator.pop(context, (kind: item.kind, name: item.name, value: 0, mg: null, price: null, delete: true)),
          ),
        ],
      ],
    );
  }
}
