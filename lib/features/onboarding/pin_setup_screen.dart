import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../security/app_gate.dart';
import '../security/biometric_service.dart';
import '../security/pin_service.dart';
import '../security/widgets/pin_pad.dart';

/// Buat PIN 6 digit lalu ulangi untuk konfirmasi.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      if (PinService.isTooSimple(pin)) {
        setState(() => _error = 'PIN terlalu mudah ditebak. Coba kombinasi lain.');
        return;
      }
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = 'PIN tidak sama. Ulangi dari awal.';
      });
      return;
    }

    setState(() => _busy = true);
    await ref.read(pinServiceProvider).setPin(pin);
    final bool bio = await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;
    ref.read(appGateProvider.notifier).pinCreated();
    context.go(bio ? Routes.setupBiometric : Routes.setupWallet);
  }

  @override
  Widget build(BuildContext context) {
    final bool confirming = _first != null;
    return Scaffold(
      appBar: confirming
          ? AppBar(
              leading: BackButton(onPressed: () => setState(() => _first = null)),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpace.screen,
            child: PinEntry(
              key: ValueKey(confirming),
              title: confirming ? 'Ulangi PIN' : 'Buat PIN',
              subtitle: confirming
                  ? 'Masukkan PIN yang sama sekali lagi.'
                  : '6 angka untuk membuka HitungIn. PIN tidak bisa dipulihkan, jadi ingat baik-baik.',
              error: _error,
              busy: _busy,
              onCompleted: _onPin,
            ),
          ),
        ),
      ),
    );
  }
}
