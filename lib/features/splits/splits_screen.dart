import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../../core/platform/share_capture.dart';
import '../../core/platform/share_text.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/segmented_control.dart';
import '../debts/data/debts_dao.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/splits.dart';
import 'data/splits_dao.dart';
import 'splits_provider.dart';

/// Warna avatar tetap untuk satu nama (sama dengan Utang-piutang).
int _colorOf(String name) => 1 + name.toLowerCase().codeUnits.fold(0, (a, b) => a + b) % (AppPalette.length - 1);

String splitInitials(String name) {
  final List<String> words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.take(2).map((w) => w.characters.first).join().toUpperCase();
}

class SplitAvatar extends StatelessWidget {
  const SplitAvatar({super.key, required this.name, this.size = 40, this.me = false});

  final String name;
  final double size;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final int color = _colorOf(name);
    final Color bg = me ? context.colors.accentSoft : AppPalette.soft(context, color);
    final Color fg = me ? context.colors.accentText : AppPalette.ink(context, color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(me ? 'AK' : splitInitials(name),
          style: context.text.item.copyWith(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// Patungan (P3c, Claude Design › Patungan): daftar riwayat & yang belum kembali.
class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<SplitFull>> async = ref.watch(splitsProvider);
    final List<SplitFull> all = async.valueOrNull ?? const [];
    final Map<int, DebtWithPayments> debts = ref.watch(debtsByIdProvider);
    final List<SplitProgress> progress = [for (final s in all) splitProgress(s, debts)];
    final int owed = progress.fold(0, (a, p) => a + p.owedToMe);
    final int iOwe = progress.fold(0, (a, p) => a + p.iOwe);
    final int openCount = progress.where((p) => p.settled < p.count).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: 'Patungan',
              large: true,
              trailing: Pressable(
                onTap: () => context.push(Routes.patunganBaru),
                semanticLabel: 'Patungan baru',
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                  child: Text('+ Baru', style: t.title.copyWith(fontSize: 14, color: c.accentText)),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            if (all.isEmpty && !async.isLoading)
              _Empty(onCreate: () => context.push(Routes.patunganBaru))
            else ...[
              Container(
                padding: const EdgeInsets.all(AppSpace.card),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  gradient: LinearGradient(colors: [c.card, Color.lerp(c.card, c.accent, 0.6)!]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Belum kembali ke kamu', style: t.caption.copyWith(color: c.onCardMuted)),
                    const SizedBox(height: AppSpace.x4),
                    Text(Rupiah.format(owed), style: t.amountL.copyWith(color: c.onCard, fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpace.x4),
                    Text(
                      [
                        openCount == 0 ? 'Semua patungan sudah beres' : '$openCount patungan belum beres',
                        if (iOwe > 0) 'utangmu ${Rupiah.format(iOwe)}',
                      ].join(' · '),
                      style: t.caption.copyWith(color: c.onCardMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x16),
              for (final (int i, SplitFull s) in all.indexed) ...[
                _SplitCard(s: s, p: progress[i], now: now),
                const SizedBox(height: AppSpace.x12),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                child: Text(
                  'Laporan hanya mencatat bagianmu. Bagian teman jadi catatan di Utang-piutang — bayar sebagian, pengingat & tagih WhatsApp tetap jalan.',
                  textAlign: TextAlign.center,
                  style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x24),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(HiIcons.people, size: 30, color: c.accent),
          ),
          const SizedBox(height: AppSpace.x16),
          Text('Bayar bareng teman?', style: t.section),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Bagi rata, custom, atau per menu. Bagianmu masuk Laporan, bagian teman otomatis jadi piutang, dan ringkasannya tinggal dikirim ke grup.',
            textAlign: TextAlign.center,
            style: t.caption.copyWith(color: c.sub, height: 1.5),
          ),
          const SizedBox(height: AppSpace.x16),
          AppButton(label: 'Buat patungan', large: true, onPressed: onCreate),
        ],
      ),
    );
  }
}

String splitStatusLabel(SplitFull s, SplitProgress p) {
  if (!s.iPaid) return p.iOwe == 0 ? 'Utangmu lunas' : 'Utangmu ${Rupiah.format(p.iOwe)}';
  if (p.count == 0) return 'Selesai';
  return p.settled == p.count ? 'Semua lunas' : '${p.settled}/${p.count} sudah bayar';
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.s, required this.p, required this.now});

  final SplitFull s;
  final SplitProgress p;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool done = p.settled == p.count;
    final String payer = s.iPaid ? 'kamu yang bayar' : '${s.payer.name} yang bayar';
    return Pressable.card(
      onTap: () => context.push(Routes.patunganDetail(s.split.id)),
      semanticLabel: '${s.split.title}, ${splitStatusLabel(s, p)}',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.card),
        decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
              child: Icon(HiIcons.people, size: 22, color: c.accent),
            ),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.split.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title)),
                      Text(Rupiah.format(s.split.total), style: t.number),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x4),
                  Text('${DateFmt.date(s.split.occurredAt, now: now)} · $payer · ${s.split.mode.label.toLowerCase()}',
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
                  const SizedBox(height: AppSpace.x8),
                  Row(
                    children: [
                      Expanded(
                        child: AppProgressBar(
                            value: p.count == 0 ? 1 : p.settled / p.count, height: 6, autoLevel: false, color: c.good),
                      ),
                      const SizedBox(width: AppSpace.x8),
                      AppBadge(
                        splitStatusLabel(s, p),
                        background: done ? c.goodSoft : c.chip,
                        foreground: done ? c.goodInk : c.sub,
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

/// Detail satu patungan: rincian per orang, tandai lunas, bagikan ke grup.
class SplitDetailScreen extends ConsumerWidget {
  const SplitDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final DateTime now = ref.watch(clockProvider)();
    final AsyncValue<List<SplitFull>> async = ref.watch(splitsProvider);
    final SplitFull? s = (async.valueOrNull ?? const <SplitFull>[]).where((x) => x.split.id == id).firstOrNull;
    if (s == null) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: AppSpace.screen,
            children: [
              const ScreenHeader(title: 'Patungan', large: true),
              if (!async.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.x32),
                  child: Text('Patungan ini sudah dihapus.',
                      textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted)),
                ),
            ],
          ),
        ),
      );
    }
    final Map<int, DebtWithPayments> debts = ref.watch(debtsByIdProvider);
    final Map<int, MemberStatus> st = memberStatuses(s, debts);
    final SplitProgress p = splitProgress(s, debts);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpace.screen,
                children: [
                  ScreenHeader(
                    title: s.split.title,
                    large: true,
                    trailing: Pressable(
                      onTap: () => showAppSheet<void>(context, title: s.split.title, builder: (_) => _SplitMenu(s: s)),
                      semanticLabel: 'Ubah atau hapus patungan',
                      child: Container(
                        width: AppSpace.touch,
                        height: AppSpace.touch,
                        decoration: BoxDecoration(
                            color: c.surface, borderRadius: AppRadius.smAll, border: Border.all(color: c.line)),
                        child: Icon(HiIcons.dots, size: 20, color: c.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x16),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.card),
                    decoration:
                        BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${DateFmt.longDate(s.split.occurredAt, now: now)} · ${s.split.mode == SplitMode.menu ? 'bagi per menu' : 'bagi ${s.split.mode.label.toLowerCase()}'}',
                                style: t.caption.copyWith(color: c.muted),
                              ),
                            ),
                            AppBadge(s.iPaid ? 'Kamu yang bayar' : '${s.payer.name} yang bayar',
                                background: c.accentSoft, foreground: c.accentText),
                          ],
                        ),
                        const SizedBox(height: AppSpace.x8),
                        Text(Rupiah.format(s.split.total), style: t.amountL.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpace.x8),
                        Row(
                          children: [
                            Expanded(
                              child: AppProgressBar(
                                  value: p.count == 0 ? 1 : p.settled / p.count, height: 8, autoLevel: false, color: c.good),
                            ),
                            const SizedBox(width: AppSpace.x8),
                            Text(splitStatusLabel(s, p), style: t.label.copyWith(color: c.sub)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x4),
                    decoration:
                        BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
                    child: Column(
                      children: [
                        for (final (int i, SplitMember m) in s.members.indexed)
                          _MemberRow(s: s, m: m, status: st[m.id]!, last: i == s.members.length - 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(Routes.utang),
                      child: Text('Lihat di Utang-piutang ›', style: t.caption.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x16),
              child: AppButton(
                key: const Key('bagikan-patungan'),
                label: 'Bagikan ke grup',
                icon: HiIcons.upload,
                large: true,
                onPressed: () => showAppSheet<void>(context, title: 'Bagikan ke grup', builder: (_) => SplitShareSheet(s: s)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.s, required this.m, required this.status, required this.last});

  final SplitFull s;
  final SplitMember m;
  final MemberStatus status;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final List<String> items = s.itemsOf(m.position);
    final bool owes = m.debtId != null;
    final String sub = [
      if (m.isMe) 'Bagianmu',
      if (m.payer && !m.isMe) 'Bayar dulu',
      if (owes && status.paid > 0 && !status.settled) 'dibayar ${Rupiah.compact(status.paid)}',
      if (items.isNotEmpty) items.join(', '),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.x12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          SplitAvatar(name: m.name, me: m.isMe),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.isMe ? 'Kamu' : m.name, style: t.item),
                if (sub.isNotEmpty)
                  Text(sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(fontWeight: FontWeight.w500, color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Rupiah.format(m.share), style: t.number),
              const SizedBox(height: AppSpace.x4),
              if (owes && !status.settled)
                Pressable(
                  onTap: () => _settle(context, ref),
                  semanticLabel: s.iPaid ? 'Tandai ${m.name} lunas' : 'Bayar ke ${m.name}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8 + 2, vertical: AppSpace.x4 + 1),
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                    child: Text(s.iPaid ? 'Tandai lunas' : 'Bayar ${Rupiah.format(status.left)}',
                        style: t.label.copyWith(color: c.accentText, fontWeight: FontWeight.w700)),
                  ),
                )
              else if (owes)
                AppBadge('✓ Lunas', background: c.goodSoft, foreground: c.goodInk)
              else if (m.isMe && m.share > 0)
                AppBadge('Pengeluaran', background: c.chip, foreground: c.sub),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final bool ok = await confirmDialog(
      context,
      title: s.iPaid ? '${m.name} sudah bayar?' : 'Bayar ${Rupiah.format(status.left)} ke ${m.name}?',
      body: s.iPaid
          ? 'Sisa ${Rupiah.format(status.left)} dicatat masuk ke dompet patungan ini.'
          : 'Dicatat keluar dari dompet patungan ini. Utangmu ke ${m.name} lunas.',
      confirm: s.iPaid ? 'Tandai lunas' : 'Bayar',
    );
    if (!ok) return;
    await ref.read(appDatabaseProvider).debtsDao.pay(
          m.debtId!,
          amount: status.left,
          paidAt: ref.read(clockProvider)(),
          walletId: s.split.walletId,
        );
    if (!context.mounted) return;
    // Semua teman sudah bayar → rayakan sebentar.
    final int open = [
      for (final x in s.members)
        if (x.debtId != null && x.id != m.id && (ref.read(debtsByIdProvider)[x.debtId]?.left ?? 0) > 0) x,
    ].length;
    if (s.iPaid && open == 0) {
      await showCelebration(context, title: '${s.split.title} beres!', body: 'Semua teman sudah membayar bagiannya.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.iPaid ? '${m.name} lunas · tercatat di Utang-piutang' : 'Utangmu ke ${m.name} lunas')));
    }
  }
}

class _SplitMenu extends ConsumerWidget {
  const _SplitMenu({required this.s});

  final SplitFull s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SplitsDao dao = ref.read(appDatabaseProvider).splitsDao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Ubah patungan',
          variant: AppButtonVariant.outline,
          onPressed: () async {
            final NavigatorState nav = Navigator.of(context);
            final GoRouter router = GoRouter.of(context);
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
            if (await dao.hasPayments(s.split.id)) {
              nav.pop();
              messenger.showSnackBar(const SnackBar(
                  content: Text('Sudah ada pembayaran. Hapus pembayarannya dulu di Utang-piutang untuk mengubah.')));
              return;
            }
            nav.pop();
            router.push(Routes.patunganUbah(s.split.id));
          },
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(
          label: 'Hapus',
          variant: AppButtonVariant.danger,
          onPressed: () async {
            final bool ok = await confirmDialog(
              context,
              title: 'Hapus ${s.split.title}?',
              body: 'Pengeluaranmu, catatan utang-piutang, dan pembayarannya ikut terhapus. Saldo dompet dikembalikan.',
              confirm: 'Hapus',
              danger: true,
            );
            if (!ok || !context.mounted) return;
            final GoRouter router = GoRouter.of(context);
            Navigator.pop(context);
            await dao.remove(s.split.id);
            if (router.canPop()) router.pop();
          },
        ),
      ],
    );
  }
}

/// Isi yang dibagikan.
enum SplitShareKind {
  both('Gambar + teks'),
  image('Gambar'),
  text('Teks');

  const SplitShareKind(this.label);
  final String label;
}

/// Baris ringkasan untuk kartu & teks.
List<ShareLine> splitShareLines(SplitFull s, Map<int, MemberStatus> st) => [
      for (final m in s.members)
        (
          name: m.name,
          share: m.share,
          isMe: m.isMe,
          payer: m.payer,
          paid: m.debtId != null && st[m.id]!.settled,
          items: s.itemsOf(m.position),
        ),
    ];

String splitModeNote(SplitFull s) => switch (s.split.mode) {
      SplitMode.rata => 'dibagi rata ${s.members.length} orang',
      SplitMode.custom => 'dibagi sesuai pesanan',
      SplitMode.menu => (s.split.taxPermille > 0 || s.split.servicePermille > 0)
          ? 'dibagi per menu (sudah termasuk pajak & service)'
          : 'dibagi per menu',
    };

class SplitShareSheet extends ConsumerStatefulWidget {
  const SplitShareSheet({super.key, required this.s});

  final SplitFull s;

  @override
  ConsumerState<SplitShareSheet> createState() => _SplitShareSheetState();
}

class _SplitShareSheetState extends ConsumerState<SplitShareSheet> {
  final GlobalKey _card = GlobalKey();
  late final TextEditingController _transfer = TextEditingController();
  SplitShareKind _kind = SplitShareKind.both;
  bool _withTransfer = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final SettingsDao dao = ref.read(appDatabaseProvider).settingsDao;
    Future.wait([dao.read(SettingKeys.splitTransfer), dao.read(SettingKeys.splitTransferOn)]).then((v) {
      if (!mounted) return;
      setState(() {
        _transfer.text = v[0] ?? '';
        _withTransfer = (v[0] ?? '').isNotEmpty && v[1] != 'false';
      });
    });
  }

  @override
  void dispose() {
    _transfer.dispose();
    super.dispose();
  }

  String _text(List<ShareLine> lines) => splitShareText(
        title: widget.s.split.title,
        date: widget.s.split.occurredAt,
        total: widget.s.split.total,
        modeNote: splitModeNote(widget.s),
        people: lines,
        transfer: _withTransfer ? _transfer.text : null,
      );

  Future<void> _share(String text) async {
    setState(() => _busy = true);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final SettingsDao dao = ref.read(appDatabaseProvider).settingsDao;
    await dao.write(SettingKeys.splitTransfer, _transfer.text.trim());
    await dao.write(SettingKeys.splitTransferOn, '$_withTransfer');
    try {
      final bool ok = _kind == SplitShareKind.text
          ? await withAutoLockPaused(ref, () => ShareText.send(text, title: 'Bagikan patungan lewat'))
          : await shareBoundaryPng(
              _card,
              fileName: 'patungan-hitungin.png',
              title: 'Bagikan patungan lewat',
              text: _kind == SplitShareKind.both ? text : null,
              wrap: (share) => withAutoLockPaused(ref, share),
            );
      nav.pop();
      if (!ok) {
        messenger.showSnackBar(SnackBar(
            content: Text(_kind == SplitShareKind.text
                ? 'Teks disalin — tempel di grup WhatsApp'
                : 'Menu Bagikan tidak tersedia di perangkat ini.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final Map<int, MemberStatus> st = memberStatuses(widget.s, ref.watch(debtsByIdProvider));
    final List<ShareLine> lines = splitShareLines(widget.s, st);
    final String text = _text(lines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_kind != SplitShareKind.text) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 248,
                height: 310,
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _card,
                    child: SplitShareCard(
                      s: widget.s,
                      lines: lines,
                      transfer: _withTransfer ? _transfer.text.trim() : null,
                      accent: c.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.x12),
        ],
        AppSegmentedControl<SplitShareKind>(
          options: SplitShareKind.values,
          selected: _kind,
          labelOf: (k) => k.label,
          onSurface: true,
          onChanged: (k) => setState(() => _kind = k),
        ),
        if (_kind != SplitShareKind.image) ...[
          const SizedBox(height: AppSpace.x12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8 + 2),
            decoration: BoxDecoration(borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
            child: Text(text, style: t.caption.copyWith(color: c.sub, height: 1.5)),
          ),
        ],
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _withTransfer,
          activeTrackColor: c.accent,
          title: Text('Sertakan info transfer', style: t.item.copyWith(fontSize: 14)),
          subtitle: Text('Diingat untuk patungan berikutnya', style: t.caption.copyWith(color: c.muted)),
          onChanged: (v) => setState(() => _withTransfer = v),
        ),
        if (_withTransfer)
          TextField(
            controller: _transfer,
            maxLength: 60,
            style: t.body,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Info transfer', hintText: 'mis. BCA 1234567890 a.n. Rina', counterText: ''),
          ),
        const SizedBox(height: AppSpace.x12),
        AppButton(
          label: _busy ? 'Menyiapkan…' : 'Bagikan',
          large: true,
          onPressed: _busy ? null : () => _share(text),
        ),
      ],
    );
  }
}

/// Kartu 4:5 untuk grup (nominal tampil — itulah isi tagihannya).
class SplitShareCard extends StatelessWidget {
  const SplitShareCard({super.key, required this.s, required this.lines, required this.transfer, required this.accent});

  final SplitFull s;
  final List<ShareLine> lines;
  final String? transfer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final TextStyle white = TextStyle(color: Colors.white, fontFamily: t.body.fontFamily);
    final List<ShareLine> shown = lines.take(7).toList();
    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, const Color(0xFFF2C14E), 0.45)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogoMark(size: 30, background: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 10),
            Text('HitungIn · Patungan', style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          Text(s.split.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.screenTitle.copyWith(color: Colors.white, fontSize: 28, height: 1.15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '${DateFmt.longDate(s.split.occurredAt, now: s.split.occurredAt)} · total ${Rupiah.format(s.split.total)} · ${s.members.length} orang',
            style: white.copyWith(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          for (final ShareLine l in shown)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(
                  child: Text(l.payer ? '${l.isMe ? 'Aku' : l.name} (bayar dulu)' : (l.isMe ? 'Aku' : l.name),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Text(Rupiah.format(l.share), style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
                SizedBox(
                  width: 52,
                  child: Text(l.payer ? '' : (l.paid ? '✓ lunas' : 'belum'),
                      textAlign: TextAlign.right, style: white.copyWith(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          if (lines.length > shown.length)
            Text('+${lines.length - shown.length} orang lagi', style: white.copyWith(fontSize: 12)),
          const Spacer(),
          if (transfer != null && transfer!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Transfer ke $transfer', style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
          ],
          Text('Dihitung di HitungIn · offline, tanpa akun',
              style: white.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}
