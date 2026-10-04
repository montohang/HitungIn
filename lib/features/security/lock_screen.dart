import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/data_providers.dart';
import '../../core/security/secure_store.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import 'app_gate.dart';
import 'biometric_service.dart';
import 'pin_service.dart';
import 'widgets/pin_pad.dart';

/// Layar kunci: PIN atau sidik jari. Setelah berhasil, router kembali ke
/// halaman sebelum terkunci (lihat `gateRedirect`).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with SingleTickerProviderStateMixin {
  /// "✓ Terbuka" tampil sebentar (desain), lalu isi layar kunci memudar
  /// sebelum Beranda muncul — supaya perpindahannya halus, bukan loncat.
  late final AnimationController _success =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _fadeOut =
      CurvedAnimation(parent: _success, curve: const Interval(0.55, 1, curve: Curves.easeIn));
  bool _unlocked = false;

  Future<void> _finishUnlock() async {
    if (_unlocked) return;
    setState(() {
      _unlocked = true;
      _error = null;
    });
    if (!context.reduceMotion) await _success.forward();
    if (mounted) ref.read(appGateProvider.notifier).unlock();
  }

  bool _biometric = false;
  bool _busy = false;
  String? _error;
  DateTime? _lockedUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final PinService pin = ref.read(pinServiceProvider);
    final DateTime? until = await pin.lockedUntil();
    final bool bio = await pin.biometricEnabled() && await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _biometric = bio);
    if (until != null) _startLockout(until);
    if (bio) await _useBiometric();
  }

  Future<void> _useBiometric() async {
    final notifier = ref.read(autoLockPausedProvider.notifier);
    notifier.state = true;
    final bool ok = await ref.read(biometricServiceProvider).authenticate('Buka HitungIn');
    notifier.state = false;
    if (!ok || !mounted) return;
    await ref.read(pinServiceProvider).resetAttempts();
    await _finishUnlock();
  }

  Future<void> _onPin(String pin) async {
    setState(() => _busy = true);
    final PinResult result = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case PinOk():
        await _finishUnlock();
      case PinWrong(:final int attemptsLeft):
        setState(() => _error = 'PIN salah. Sisa $attemptsLeft percobaan.');
      case PinLockedOut(:final DateTime until):
        _startLockout(until);
    }
  }

  void _startLockout(DateTime until) {
    _ticker?.cancel();
    setState(() {
      _lockedUntil = until;
      _error = _lockoutMessage();
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!ref.read(clockProvider)().isBefore(until)) {
        _ticker?.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() => _error = _lockoutMessage());
      }
    });
  }

  String _lockoutMessage() {
    final Duration left = _lockedUntil!.difference(ref.read(clockProvider)());
    final int s = (left.inMilliseconds / 1000).ceil().clamp(0, 99999);
    final String time = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return 'Terlalu banyak percobaan. Coba lagi dalam $time.';
  }

  void _forgot() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final t = context.text;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenH, 0, AppSpace.screenH, AppSpace.x24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lupa PIN?', style: t.screenTitle),
                const SizedBox(height: AppSpace.x12),
                Text(
                  'HitungIn tidak punya server, jadi PIN tidak bisa direset dari jauh. '
                  'Bila sidik jari aktif, pakai itu untuk masuk lalu ganti PIN di Pengaturan. '
                  'Bila tidak, satu-satunya jalan adalah menghapus data aplikasi lewat Pengaturan Android '
                  'lalu memulihkan dari file cadangan.',
                  style: t.body.copyWith(color: context.colors.sub),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _success.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final String? name = ref.watch(userNameProvider).valueOrNull;
    final Color accentLight = Color.lerp(c.accent, Colors.white, 0.45)!;
    // Layar kunci selalu gelap (desain), apa pun tema aplikasi.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LockColors.base,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.55, 1],
              colors: [LockColors.base, LockColors.base, Color.lerp(LockColors.base, c.accent, 0.35)!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -80,
                top: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withAlpha(0x38)),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: ReverseAnimation(_fadeOut),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x24, AppSpace.screenH, AppSpace.x8),
                    child: PinField(
                      style: PinPadStyle.onDark,
                      error: _error,
                      busy: _busy || _unlocked,
                      status: _unlocked
                          ? const PinUnlockedBadge()
                          : _busy
                              ? const PinBusyStatus('Memeriksa PIN…', style: PinPadStyle.onDark)
                              : null,
                      enabled: _lockedUntil == null,
                      onCompleted: _onPin,
                      onBiometric: _biometric ? _useBiometric : null,
                      header: Column(
                        children: [
                          const SizedBox(height: AppSpace.x32),
                          const LogoMark(size: 64),
                          const SizedBox(height: AppSpace.x12),
                          Text(
                            name == null ? 'Hai lagi' : 'Hai lagi, $name',
                            textAlign: TextAlign.center,
                            style: t.screenTitle.copyWith(fontSize: 26, color: Colors.white),
                          ),
                          const SizedBox(height: AppSpace.x8),
                          Text(
                            _biometric ? 'Masukkan PIN atau pakai sidik jari' : 'Masukkan PIN untuk membuka',
                            style: t.body.copyWith(fontSize: 14, color: LockColors.hint),
                          ),
                        ],
                      ),
                      footer: Padding(
                        padding: const EdgeInsets.only(top: AppSpace.x8),
                        child: Pressable(
                          onTap: _forgot,
                          semanticLabel: 'Lupa PIN',
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpace.x12),
                            child: Text('Lupa PIN?', style: t.label.copyWith(fontSize: 14, color: accentLight)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
