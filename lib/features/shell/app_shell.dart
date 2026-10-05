import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/pressable.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/db/app_database.dart';
import '../ads/ad_policy.dart';
import '../bills/bills_screen.dart';
import '../bills/data/bill_reminders.dart';
import '../bills/reminder_scheduler.dart';
import '../ads/ads_service.dart';
import '../ads/banner_slot.dart';
import '../premium/pro_controller.dart';
import '../security/app_gate.dart';
import '../../core/widgets/hi_icons.dart';

/// Kerangka 4 tab + tombol Catat di tengah. Banner iklan (versi gratis)
/// tampil di atas navigasi pada tab yang diizinkan [AdPolicy].
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StatefulNavigationShell get shell => widget.shell;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(onResume: _runRecurring);

  /// Catat transaksi berulang yang jatuh tempo (berjalan untuk semua
  /// pengguna: jadwal yang sudah ada tidak dihentikan bila Pro hilang).
  Future<void> _runRecurring() async {
    final int n = await ref.read(appDatabaseProvider).recurringDao.runDue(ref.read(clockProvider)());
    if (n > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$n transaksi berulang dicatat otomatis')));
    }
  }

  Timer? _reminderDebounce;

  /// Jadwalkan ulang notifikasi tagihan (ditunda sebentar supaya beberapa
  /// perubahan beruntun cukup sekali disinkronkan).
  void _scheduleReminderSync() {
    _reminderDebounce?.cancel();
    _reminderDebounce = Timer(const Duration(milliseconds: 600), () async {
      final List<Bill>? bills = ref.read(activeBillsProvider).valueOrNull;
      final ReminderSettings? settings = ref.read(reminderSettingsProvider).valueOrNull;
      if (bills == null || settings == null || !mounted) return;
      await syncBillReminders(
        scheduler: ref.read(reminderSchedulerProvider),
        bills: bills,
        settings: settings,
        isPro: ref.read(isProProvider),
        now: ref.read(clockProvider)(),
      );
    });
  }

  void _onNotificationTap(String payload) {
    if (payload.startsWith(billPayloadPrefix) && mounted) context.push(Routes.tagihan);
  }

  @override
  void dispose() {
    _reminderDebounce?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    Future.microtask(_runRecurring);
    Future.microtask(() async {
      await ref.read(reminderSchedulerProvider).init(onTap: _onNotificationTap);
      _scheduleReminderSync();
    });
    // Shell hanya tampil setelah onboarding & buka kunci, jadi dialog
    // persetujuan iklan tidak mengganggu alur pertama kali buka.
    Future.microtask(() async {
      final pro = ref.read(proControllerProvider.notifier);
      await pro.restore(silent: true);
      if (ref.read(isProProvider)) return;
      final bool ready = await withAutoLockPaused(ref, () => ref.read(adsServiceProvider).init());
      if (mounted) ref.read(adsReadyProvider.notifier).state = ready;
    });
  }

  static const List<(IconData, IconData, String)> _tabs = [
    (HiIcons.home, HiIcons.home, 'Beranda'),
    (HiIcons.report, HiIcons.report, 'Laporan'),
    (HiIcons.target, HiIcons.target, 'Budget'),
    (HiIcons.grid, HiIcons.grid, 'Lainnya'),
  ];

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    ref.listen(activeBillsProvider, (_, __) => _scheduleReminderSync());
    ref.listen(reminderSettingsProvider, (_, __) => _scheduleReminderSync());
    ref.listen(isProProvider, (_, __) => _scheduleReminderSync());
    final c = context.colors;
    final bool banner = AdPolicy.showBanner(
      tab: shell.currentIndex,
      isPro: ref.watch(isProProvider),
      adsReady: ref.watch(adsReadyProvider),
    );
    Widget tab(int i) {
      final (IconData icon, IconData active, String label) = _tabs[i];
      final bool selected = shell.currentIndex == i;
      final Color color = selected ? c.accentText : c.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: Pressable(
            onTap: () => _go(i),
            semanticLabel: label,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? active : icon, color: color, size: 24),
                  const SizedBox(height: AppSpace.x2),
                  Text(
                    label,
                    style: context.text.label.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tombol kembali HP: dari Laporan/Budget/Lainnya → Beranda; di Beranda → keluar app.
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (banner) const BannerSlot(),
            DecoratedBox(
              decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x8, vertical: AppSpace.x4),
                  child: Row(
                    children: [
                      tab(0),
                      tab(1),
                      // Tombol Catat menonjol ke atas (desain: 58 px, naik 28 px, bayangan aksen).
                      Expanded(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -14),
                            child: Pressable(
                              onTap: () => context.push(Routes.catat),
                              semanticLabel: 'Catat transaksi',
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  borderRadius: AppRadius.mdAll,
                                  boxShadow: [
                                    BoxShadow(
                                        color: c.accent.withAlpha(0x55), blurRadius: 24, offset: const Offset(0, 10)),
                                  ],
                                ),
                                child: Icon(HiIcons.plus, color: c.onAccent, size: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                      tab(2),
                      tab(3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
