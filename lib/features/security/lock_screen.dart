import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _LockScreenState extends ConsumerState<LockScreen> {
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
    final notifier = ref.read(biometricPromptActiveProvider.notifier);
    notifier.state = true;
    final bool ok = await ref.read(biometricServiceProvider).authenticate('Buka HitungIn');
    notifier.state = false;
    if (!ok || !mounted) return;
    await ref.read(pinServiceProvider).resetAttempts();
    ref.read(appGateProvider.notifier).unlock();
  }

  Future<void> _onPin(String pin) async {
    setState(() => _busy = true);
    final PinResult result = await ref.read(pinServiceProvider).verify(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case PinOk():
        ref.read(appGateProvider.notifier).unlock();
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
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpace.screen,
            child: Column(
              children: [
                const LogoMark(size: 56),
                const SizedBox(height: AppSpace.x24),
                PinEntry(
                  title: 'Masukkan PIN',
                  subtitle: 'HitungIn terkunci untuk menjaga datamu.',
                  error: _error,
                  busy: _busy,
                  enabled: _lockedUntil == null,
                  onCompleted: _onPin,
                  onBiometric: _biometric ? _useBiometric : null,
                ),
                const SizedBox(height: AppSpace.x16),
                Pressable(
                  onTap: _forgot,
                  semanticLabel: 'Lupa PIN',
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.x12),
                    child: Text('Lupa PIN?', style: context.text.label.copyWith(color: c.accentText, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
