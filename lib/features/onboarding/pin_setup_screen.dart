import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/pressable.dart';
import '../security/app_gate.dart';
import '../security/biometric_service.dart';
import '../security/pin_service.dart';
import '../security/widgets/pin_pad.dart';

/// Ke mana setelah PIN dibuat: data hasil pulihkan sudah punya dompet →
/// onboarding selesai; selain itu → Dompet Awal.
String? routeAfterPinSetup({required bool hasWallets}) => hasWallets ? null : Routes.setupWallet;

/// Langkah 1 dari 2: buat PIN 6 digit, ulangi, lalu tawarkan sidik jari
/// (lembar bawah, seperti desain).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;
  int _errors = 0;
  bool _busy = false;

  bool get _confirming => _first != null;

  void _fail(String message) => setState(() {
        _error = message;
        _errors++;
      });

  Future<void> _onPin(String pin) async {
    if (!_confirming) {
      if (PinService.isTooSimple(pin)) return _fail('PIN terlalu mudah ditebak. Coba kombinasi lain.');
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() => _first = null);
      return _fail('PIN tidak sama. Ulangi dari awal.');
    }

    setState(() => _busy = true);
    await ref.read(pinServiceProvider).setPin(pin);
    final bool bio = await ref.read(biometricServiceProvider).isAvailable();
    final bool hasWallets = (await ref.read(appDatabaseProvider).walletsDao.active()).isNotEmpty;
    if (!mounted) return;
    ref.read(appGateProvider.notifier).pinCreated();
    if (bio) await _offerBiometric();
    if (!mounted) return;
    final String? next = routeAfterPinSetup(hasWallets: hasWallets);
    if (next != null) {
      context.go(next);
    } else {
      // Router otomatis pindah ke beranda setelah onboarding selesai.
      await ref.read(appGateProvider.notifier).completeOnboarding();
    }
  }

  Future<void> _offerBiometric() async {
    final bool? enable = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      // Lebih tinggi dari batas bawaan (9/16 layar) → atur sendiri & bisa digulir.
      isScrollControlled: true,
      builder: (_) => const _BiometricSheet(),
    );
    if (enable != true) {
      await ref.read(pinServiceProvider).setBiometricEnabled(false);
      return;
    }
    final bool ok = await withAutoLockPaused(
      ref,
      () => ref.read(biometricServiceProvider).authenticate('Konfirmasi sidik jari untuk HitungIn'),
    );
    await ref.read(pinServiceProvider).setBiometricEnabled(ok);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sidik jari belum aktif. Bisa dinyalakan nanti di Pengaturan.')),
      );
    }
  }

  void _back() {
    if (_confirming) {
      setState(() {
        _first = null;
        _error = null;
      });
    } else {
      context.go(Routes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x24),
            child: PinField(
              key: ValueKey(_confirming),
              style: PinPadStyle.light,
              error: _error,
              shakeKey: _errors,
              busy: _busy,
              onCompleted: _onPin,
              header: Column(
                children: [
                  StepHeader(label: 'Langkah 1 dari 2', onBack: _busy ? null : _back),
                  const SizedBox(height: AppSpace.x24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: AppRadius.lgAll),
                    child: Icon(Icons.lock_outline_rounded, size: 30, color: c.accentText),
                  ),
                  const SizedBox(height: AppSpace.x12),
                  Text(
                    _confirming ? 'Ulangi PIN-mu' : 'Buat PIN 6 digit',
                    style: t.screenTitle.copyWith(fontSize: 28, height: 1.15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.x12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      _confirming ? 'Masukkan sekali lagi untuk memastikan.' : 'PIN ini mengunci HitungIn setiap kali dibuka.',
                      textAlign: TextAlign.center,
                      style: t.body.copyWith(color: c.sub),
                    ),
                  ),
                ],
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: AppSpace.x16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
                  decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.mdAll),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: c.sub),
                      const SizedBox(width: AppSpace.x8),
                      Expanded(
                        child: Text(
                          'Karena tidak ada server, PIN tidak bisa direset lewat email. '
                          'Kalau lupa, data dipulihkan dari file backup-mu.',
                          style: t.label.copyWith(color: c.sub, fontWeight: FontWeight.w500, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris atas langkah onboarding: tombol kembali, "Langkah n dari 2".
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.label, this.onBack});

  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        if (onBack != null)
          Pressable(
            onTap: onBack,
            semanticLabel: 'Kembali',
            child: Container(
              width: AppSpace.touch,
              height: AppSpace.touch,
              decoration: BoxDecoration(color: c.bg, borderRadius: AppRadius.smAll),
              child: Icon(Icons.chevron_left, color: c.ink),
            ),
          )
        else
          const SizedBox(width: AppSpace.touch, height: AppSpace.touch),
        Expanded(
          child: Text(label, textAlign: TextAlign.center, style: context.text.label.copyWith(fontSize: 13, color: c.muted)),
        ),
        const SizedBox(width: AppSpace.touch),
      ],
    );
  }
}

class _BiometricSheet extends StatelessWidget {
  const _BiometricSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x24, AppSpace.screenH, AppSpace.x24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: c.line2, borderRadius: AppRadius.pillAll)),
            const SizedBox(height: AppSpace.x16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: c.good),
                const SizedBox(width: AppSpace.x4),
                Text('PIN tersimpan', style: t.label.copyWith(fontSize: 13, color: c.good)),
              ],
            ),
            const SizedBox(height: AppSpace.x16),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
              child: Icon(Icons.fingerprint, size: 48, color: c.accentText),
            ),
            const SizedBox(height: AppSpace.x16),
            Text('Buka lebih cepat dengan sidik jari?', textAlign: TextAlign.center, style: t.screenTitle.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpace.x12),
            Text(
              'Sidik jari diproses oleh sistem HP. HitungIn tidak pernah menyimpannya.',
              textAlign: TextAlign.center,
              style: t.body.copyWith(color: c.sub),
            ),
            const SizedBox(height: AppSpace.x24),
            AppButton(label: 'Aktifkan', large: true, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: AppSpace.x8),
            Pressable(
              onTap: () => Navigator.pop(context, false),
              semanticLabel: 'Nanti saja',
              child: SizedBox(
                height: 52,
                child: Center(child: Text('Nanti saja', style: t.title.copyWith(color: c.sub2, fontWeight: FontWeight.w600))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
