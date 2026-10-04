import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../security/app_gate.dart';
import '../security/biometric_service.dart';
import '../security/pin_service.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _enable() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    ref.read(autoLockPausedProvider.notifier).state = true;
    final bool ok = await ref.read(biometricServiceProvider).authenticate('Konfirmasi sidik jari untuk HitungIn');
    ref.read(autoLockPausedProvider.notifier).state = false;
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Belum berhasil. Coba lagi, atau lewati dulu.';
      });
      return;
    }
    await ref.read(pinServiceProvider).setBiometricEnabled(true);
    if (mounted) context.go(Routes.setupWallet);
  }

  Future<void> _skip() async {
    await ref.read(pinServiceProvider).setBiometricEnabled(false);
    if (mounted) context.go(Routes.setupWallet);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpace.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.x32),
              const IconTile(icon: Icons.fingerprint, size: 96),
              const SizedBox(height: AppSpace.x32),
              Text('Buka lebih cepat\ndengan sidik jari?', style: t.pageTitle.copyWith(height: 1.15)),
              const SizedBox(height: AppSpace.x16),
              Text(
                'PIN tetap bisa dipakai kapan saja. Data sidik jari diurus sistem Android — HitungIn tidak pernah melihatnya.',
                style: t.body.copyWith(color: c.sub),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.x16),
                Text(_error!, style: t.caption.copyWith(color: c.danger)),
              ],
              const Spacer(),
              AppButton(label: 'Aktifkan sidik jari', icon: Icons.fingerprint, large: true, onPressed: _busy ? null : _enable),
              const SizedBox(height: AppSpace.x8),
              AppButton(label: 'Nanti saja', variant: AppButtonVariant.outline, onPressed: _busy ? null : _skip),
            ],
          ),
        ),
      ),
    );
  }
}
