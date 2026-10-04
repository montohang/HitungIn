import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_chip.dart';
import '../settings/widgets/settings_tile.dart';
import 'app_gate.dart';
import 'auto_lock_setting.dart';
import 'biometric_service.dart';
import 'pin_service.dart';
import 'widgets/pin_pad.dart';

final _biometricStateProvider = FutureProvider.autoDispose<({bool available, bool enabled})>((ref) async => (
      available: await ref.watch(biometricServiceProvider).isAvailable(),
      enabled: await ref.watch(pinServiceProvider).biometricEnabled(),
    ));

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  Future<void> _toggleBiometric(BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      final bool ok = await withAutoLockPaused(
        ref,
        () => ref.read(biometricServiceProvider).authenticate('Konfirmasi sidik jari untuk HitungIn'),
      );
      if (!ok) return;
    }
    await ref.read(pinServiceProvider).setBiometricEnabled(enable);
    ref.invalidate(_biometricStateProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final AutoLockDelay delay = ref.watch(autoLockProvider);
    final bio = ref.watch(_biometricStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('PIN & kunci', style: t.screenTitle)),
      body: ListView(
        padding: AppSpace.screen.copyWith(top: AppSpace.x8),
        children: [
          SettingsGroup(
            children: [
              SettingsTile(icon: Icons.pin_outlined, title: 'Ganti PIN', onTap: () => context.push(Routes.gantiPin)),
              SettingsTile(
                icon: Icons.fingerprint,
                title: 'Buka dengan sidik jari',
                subtitle: bio == null || bio.available ? null : 'Tidak tersedia di HP ini',
                trailing: Switch.adaptive(
                  value: bio?.enabled ?? false,
                  activeTrackColor: c.accent,
                  onChanged: bio?.available ?? false ? (v) => _toggleBiometric(context, ref, v) : null,
                ),
              ),
            ],
          ),
          Text('Kunci otomatis', style: t.label.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.x8),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final d in AutoLockDelay.values)
                AppChip(label: d.label, selected: d == delay, onTap: () => ref.read(autoLockProvider.notifier).set(d)),
            ],
          ),
          const SizedBox(height: AppSpace.x8),
          Text(
            'HitungIn terkunci lagi bila ditinggal di latar belakang lebih lama dari ini.',
            style: t.caption.copyWith(color: c.muted),
          ),
        ],
      ),
    );
  }
}

/// Ganti PIN: PIN lama → PIN baru → ulangi.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _Step { old, fresh, confirm }

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  _Step _step = _Step.old;
  String? _old;
  String? _fresh;
  String? _error;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    switch (_step) {
      case _Step.old:
        setState(() => _busy = true);
        // Cek dulu tanpa mengganti; PIN baru disimpan di langkah terakhir.
        final PinResult r = await ref.read(pinServiceProvider).verify(pin);
        if (!mounted) return;
        setState(() {
          _busy = false;
          switch (r) {
            case PinOk():
              _old = pin;
              _step = _Step.fresh;
              _error = null;
            case PinWrong(:final int attemptsLeft):
              _error = 'PIN salah. Sisa $attemptsLeft percobaan.';
            case PinLockedOut():
              _error = 'Terlalu banyak percobaan. Coba lagi nanti.';
          }
        });
      case _Step.fresh:
        if (PinService.isTooSimple(pin) || pin == _old) {
          setState(() => _error = pin == _old ? 'PIN baru harus berbeda.' : 'PIN terlalu mudah ditebak.');
          return;
        }
        setState(() {
          _fresh = pin;
          _step = _Step.confirm;
          _error = null;
        });
      case _Step.confirm:
        if (pin != _fresh) {
          setState(() {
            _step = _Step.fresh;
            _error = 'PIN tidak sama. Ulangi PIN baru.';
          });
          return;
        }
        setState(() => _busy = true);
        final PinResult r = await ref.read(pinServiceProvider).changePin(_old!, pin);
        if (!mounted) return;
        if (r is PinOk) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN diganti')));
          context.pop();
        } else {
          setState(() {
            _busy = false;
            _step = _Step.old;
            _error = 'PIN lama tidak cocok. Ulangi dari awal.';
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle) = switch (_step) {
      _Step.old => ('PIN lama', 'Masukkan PIN yang dipakai sekarang.'),
      _Step.fresh => ('PIN baru', '6 angka, jangan yang mudah ditebak.'),
      _Step.confirm => ('Ulangi PIN baru', 'Masukkan PIN baru sekali lagi.'),
    };
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpace.screen,
            child: PinEntry(
              key: ValueKey(_step),
              title: title,
              subtitle: subtitle,
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
