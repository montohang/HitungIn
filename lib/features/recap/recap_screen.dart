import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/platform/share_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/rupiah.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/hi_icons.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/screen_header.dart';
import '../bills/reminder_scheduler.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import '../settings/widgets/settings_tile.dart';
import 'data/weekly_recap.dart';
import 'recap_provider.dart';

const List<String> _dayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// "13–19 Okt" / "28 Sep – 4 Okt".
String recapRangeLabel(WeeklyRecap r) {
  final DateTime s = r.start, e = r.end;
  return s.month == e.month
      ? '${s.day}–${e.day} ${DateFmt.monthsShort[e.month - 1]}'
      : '${s.day} ${DateFmt.monthsShort[s.month - 1]} – ${e.day} ${DateFmt.monthsShort[e.month - 1]}';
}

/// "▼ Rp180rb lebih hemat dari minggu sebelumnya".
String recapDeltaLabel(WeeklyRecap r, {bool hidden = false}) {
  if (r.prevOut == 0) return 'Minggu pertama yang tercatat';
  final int pct = (r.saved.abs() * 100 / r.prevOut).round();
  final String amount = hidden ? '$pct%' : Rupiah.compact(r.saved.abs());
  return r.saved >= 0 ? '▼ $amount lebih hemat dari minggu sebelumnya' : '▲ $amount lebih banyak dari minggu sebelumnya';
}

/// Gradien kartu rekap: aksen → emas.
LinearGradient recapGradient(Color accent) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent, Color.lerp(accent, const Color(0xFFF2C14E), 0.45)!],
    );

/// Rekap mingguan (P3a, Claude Design › Rekap mingguan).
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, this.initialOffset = 0});

  /// 0 = minggu ini, 1 = minggu lalu.
  final int initialOffset;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  late int _offset = widget.initialOffset;
  static const int _maxOffset = 26;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final WeeklyRecap? r = ref.watch(weeklyRecapProvider(_offset)).valueOrNull;
    final Streak? streak = ref.watch(streakProvider);
    final Set<DateTime> logged = ref.watch(loggedDaysProvider).valueOrNull ?? const {};
    final bool hidden = ref.watch(hideBalanceProvider).valueOrNull ?? false;
    String money(int v) => hidden ? 'Rp••••' : Rupiah.compact(v);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpace.screen,
          children: [
            ScreenHeader(
              title: 'Rekap mingguan',
              large: true,
              trailing: r == null || r.isEmpty
                  ? null
                  : Pressable(
                      onTap: () => _share(r, streak),
                      semanticLabel: 'Bagikan rekap',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.smAll),
                        child: Icon(HiIcons.upload, size: 20, color: c.accentText),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpace.x12),
            Center(
              child: _WeekSwitcher(
                label: r == null ? '' : '${recapRangeLabel(r)}${_offset == 0 ? ' · berjalan' : ''}',
                onPrev: _offset < _maxOffset ? () => setState(() => _offset++) : null,
                onNext: _offset > 0 ? () => setState(() => _offset--) : null,
              ),
            ),
            const SizedBox(height: AppSpace.x16),
            if (r == null)
              const SizedBox(height: 200)
            else if (r.isEmpty)
              _EmptyWeek(onCatat: () => Navigator.of(context).maybePop())
            else ...[
              _Hero(recap: r, hidden: hidden, current: _offset == 0),
              const SizedBox(height: AppSpace.x12),
              Row(
                children: [
                  for (final (int i, (String k, String v)) in [
                    ('Masuk', money(r.income)),
                    ('Rata-rata/hari', money(r.averagePerDay)),
                    ('Hari mencatat', '${r.daysLogged}/7'),
                  ].indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.x8),
                    Expanded(child: _Stat(label: k, value: v)),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.x12),
              _PerDay(recap: r),
              const SizedBox(height: AppSpace.x12),
              _TopCategories(recap: r, hidden: hidden),
            ],
            const SizedBox(height: AppSpace.x12),
            // Streak berlaku hari ini, jadi lingkarannya selalu minggu berjalan.
            if (streak != null) _StreakCard(streak: streak, weekStart: weekStart(DateTime.now()), logged: logged),
            const SizedBox(height: AppSpace.x12),
            const _NotifySettings(),
            if (r != null && !r.isEmpty) ...[
              const SizedBox(height: AppSpace.x16),
              AppButton(label: 'Bagikan kartu rekap', large: true, onPressed: () => _share(r, streak)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _share(WeeklyRecap r, Streak? streak) => showAppSheet<void>(
        context,
        title: 'Bagikan kartu rekap',
        builder: (_) => _ShareSheet(recap: r, streak: streak?.current ?? 0),
      );
}

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({required this.label, required this.onPrev, required this.onNext});

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    Widget btn(IconData i, VoidCallback? f, String sem) => Pressable(
          onTap: f,
          semanticLabel: sem,
          child: SizedBox(width: 36, height: 36, child: Icon(i, size: 18, color: f == null ? c.line2 : c.ink)),
        );
    return Container(
      padding: const EdgeInsets.all(AppSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.smAll, border: Border.all(color: c.line)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(HiIcons.back, onPrev, 'Minggu sebelumnya'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8), child: Text(label, style: t.title.copyWith(fontSize: 14))),
          btn(HiIcons.forward, onNext, 'Minggu berikutnya'),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.recap, required this.hidden, required this.current});

  final WeeklyRecap recap;
  final bool hidden;

  /// Minggu berjalan (bukan minggu yang sudah lewat).
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpace.x16 + 2),
      decoration: BoxDecoration(borderRadius: AppRadius.lgAll, gradient: recapGradient(c.accent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(current ? 'Pengeluaran minggu ini' : 'Pengeluaran minggu itu', style: t.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: AppSpace.x4),
          Text(hidden ? 'Rp••••' : Rupiah.format(recap.out),
              style: t.amountXL.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: AppSpace.x8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8 + 2, vertical: AppSpace.x4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: AppRadius.pillAll),
            child: Text(recapDeltaLabel(recap, hidden: hidden),
                style: t.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          if (recap.insight != null) ...[
            const SizedBox(height: AppSpace.x12),
            Text('💡 ${recap.insight}', style: t.body.copyWith(color: Colors.white, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.x12, vertical: AppSpace.x8 + 2),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.mdAll, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpace.x2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: t.number.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.x16, AppSpace.x12 + 2, AppSpace.x16, AppSpace.x16),
      decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.lgAll, border: Border.all(color: c.line)),
      child: child,
    );
  }
}

class _PerDay extends StatelessWidget {
  const _PerDay({required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final int max = recap.perDay.fold(1, (m, v) => v > m ? v : m);
    final int? top = recap.topDay;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text('Per hari', style: t.title.copyWith(fontSize: 15))),
            if (top != null) Text('Paling boros: ${recapDayNames[top]}', style: t.caption.copyWith(color: c.muted)),
          ]),
          const SizedBox(height: AppSpace.x12),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: recap.perDay[i] == 0 ? 4 : 8 + 68 * recap.perDay[i] / max,
                          decoration: BoxDecoration(
                            color: i == top ? c.accent : c.accent.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: AppSpace.x4),
                        Text(_dayShort[i],
                            style: t.label.copyWith(color: i == top ? c.accentText : c.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.recap, required this.hidden});

  final WeeklyRecap recap;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    if (recap.topCategories.isEmpty) return const SizedBox.shrink();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kategori terbesar', style: t.title.copyWith(fontSize: 15)),
          for (final ({String name, int total}) k in recap.topCategories) ...[
            const SizedBox(height: AppSpace.x12),
            Row(children: [
              Expanded(child: Text(k.name, style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.ink))),
              Text(
                '${hidden ? 'Rp••••' : Rupiah.compact(k.total)} · ${(k.total * 100 / recap.out).round()}%',
                style: t.caption.copyWith(color: c.muted),
              ),
            ]),
            const SizedBox(height: AppSpace.x4 + 2),
            ClipRRect(
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: k.total / recap.out,
                minHeight: 8,
                color: c.accent,
                backgroundColor: c.track,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.weekStart, required this.logged});

  final Streak streak;
  final DateTime weekStart;
  final Set<DateTime> logged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final DateTime today = DateTime.now();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(streak.current > 0 ? '🔥 Streak ${streak.current} hari' : 'Mulai streak hari ini',
                      style: t.title.copyWith(fontSize: 15)),
                  Text('Rekor terpanjang ${streak.best} hari', style: t.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Builder(builder: (context) {
                    final DateTime d = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
                    final bool done = logged.contains(d);
                    final bool rest = streak.restDays.contains(d);
                    final bool future = d.isAfter(DateTime(today.year, today.month, today.day));
                    return Column(children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: done ? c.accent : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: done ? c.accent : c.line2, width: 2),
                        ),
                        child: Text(
                          done
                              ? '✓'
                              : rest
                                  ? '☕'
                                  : '',
                          style: t.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: AppSpace.x4),
                      Text(_dayShort[i], style: t.label.copyWith(color: future ? c.line2 : c.muted)),
                    ]);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Text('☕ Hari santai: satu hari kosong per minggu tidak memutus streak.',
              style: t.label.copyWith(color: c.muted, fontWeight: FontWeight.w500, height: 1.5)),
        ],
      ),
    );
  }
}

class _NotifySettings extends ConsumerWidget {
  const _NotifySettings();

  Future<void> _set(WidgetRef ref, String key, bool on) async {
    if (on) {
      final ReminderScheduler s = ref.read(reminderSchedulerProvider);
      if (!await s.permissionGranted()) await withAutoLockPaused(ref, s.requestPermission);
    }
    await ref.read(appDatabaseProvider).settingsDao.write(key, '$on');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final bool weekly = ref.watch(recapWeeklyProvider).valueOrNull ?? true;
    final bool evening = ref.watch(recapEveningProvider).valueOrNull ?? false;
    Widget tile(String title, String sub, bool v, String key) => SwitchListTile.adaptive(
          value: v,
          activeTrackColor: c.accent,
          title: Text(title, style: t.item.copyWith(fontSize: 14)),
          subtitle: Text(sub, style: t.caption.copyWith(color: c.muted)),
          onChanged: (on) => _set(ref, key, on),
        );
    return SettingsGroup(children: [
      tile('Notifikasi rekap', 'Senin 08.00 · "Rekap minggumu sudah siap"', weekly, SettingKeys.recapWeekly),
      tile('Pengingat malam', '20.00 bila hari ini belum mencatat (streak ≥ 3)', evening, SettingKeys.recapEvening),
    ]);
  }
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek({required this.onCatat});

  final VoidCallback onCatat;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return _Card(
      child: Column(children: [
        const SizedBox(height: AppSpace.x8),
        const Text('🗓️', style: TextStyle(fontSize: 36)),
        const SizedBox(height: AppSpace.x8),
        Text('Belum ada catatan di minggu ini', style: t.title.copyWith(fontSize: 15)),
        const SizedBox(height: AppSpace.x4),
        Text('Catat pengeluaran harianmu — rekapnya muncul di sini setiap Senin.',
            textAlign: TextAlign.center, style: t.caption.copyWith(color: c.muted, height: 1.5)),
      ]),
    );
  }
}

/// Kartu yang dibagikan (4:5). Tanpa nominal: hanya persen, kategori,
/// hari mencatat & streak.
class RecapShareCard extends StatelessWidget {
  const RecapShareCard({super.key, required this.recap, required this.streak, required this.showAmounts, required this.accent});

  final WeeklyRecap recap;
  final int streak;
  final bool showAmounts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final int pct = recap.prevOut == 0 ? 0 : (recap.saved.abs() * 100 / recap.prevOut).round();
    final String headline = recap.prevOut == 0
        ? 'Minggu pertama mencatat! ✍️'
        : recap.saved >= 0
            ? '${showAmounts ? Rupiah.compact(recap.saved) : '$pct%'} lebih hemat minggu ini 🎉'
            : 'Minggu yang sibuk! Tetap tercatat ✍️';
    final List<(String, String)> rows = [
      if (recap.topCategories.isNotEmpty) ('Terbesar', recap.topCategories.first.name),
      showAmounts ? ('Total keluar', Rupiah.compact(recap.out)) : ('Hari mencatat', '${recap.daysLogged}/7'),
      if (streak > 0) ('Streak', '🔥 $streak hari'),
    ];
    final TextStyle white = TextStyle(color: Colors.white, fontFamily: t.body.fontFamily);
    return Container(
      width: 360,
      height: 450,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(gradient: recapGradient(accent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            LogoMark(size: 32, background: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 10),
            Text('HitungIn · ${recapRangeLabel(recap)}', style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 28),
          Text(headline,
              style: t.screenTitle.copyWith(color: Colors.white, fontSize: 30, height: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          for (final (String k, String v) in rows)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Text(k, style: white.copyWith(fontSize: 14))),
                Text(v, style: white.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
          const Spacer(),
          Text('Dicatat offline, tanpa akun · HitungIn',
              style: white.copyWith(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.recap, required this.streak});

  final WeeklyRecap recap;
  final int streak;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final GlobalKey _card = GlobalKey();
  bool _amounts = false;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final RenderRepaintBoundary boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3); // 1080×1350
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final Directory dir = Directory('${(await getTemporaryDirectory()).path}/share');
      await dir.create(recursive: true);
      final File f = File('${dir.path}/rekap-hitungin.png');
      await f.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final NavigatorState nav = Navigator.of(context);
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final bool ok = await withAutoLockPaused(ref, () => ShareText.image(f.path, title: 'Bagikan rekap lewat'));
      if (await f.exists()) await f.delete();
      nav.pop();
      if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Menu Bagikan tidak tersedia di perangkat ini.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: 248,
              height: 310,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _card,
                  child: RecapShareCard(
                      recap: widget.recap, streak: widget.streak, showAmounts: _amounts, accent: c.accent),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.x12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _amounts,
          activeTrackColor: c.accent,
          title: Text('Tampilkan nominal', style: t.item.copyWith(fontSize: 14)),
          subtitle: Text('Mati: kartu hanya berisi persen, kategori & streak', style: t.caption.copyWith(color: c.muted)),
          onChanged: (v) => setState(() => _amounts = v),
        ),
        const SizedBox(height: AppSpace.x8),
        AppButton(label: _busy ? 'Menyiapkan…' : 'Bagikan', large: true, onPressed: _busy ? null : _share),
      ],
    );
  }
}
