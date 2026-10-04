import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/secure_store.dart';
import 'app_gate.dart';

/// Mengunci aplikasi bila ditinggal di latar belakang lebih lama dari
/// [grace]. Dipasang sekali di atas router (lihat app.dart).
class AutoLock extends ConsumerStatefulWidget {
  const AutoLock({super.key, required this.child, this.grace = const Duration(seconds: 30)});

  final Widget child;
  final Duration grace;

  @override
  ConsumerState<AutoLock> createState() => _AutoLockState();
}

class _AutoLockState extends ConsumerState<AutoLock> {
  late final AppLifecycleListener _listener;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
  }

  void _onHide() {
    if (ref.read(biometricPromptActiveProvider)) return;
    _hiddenAt = ref.read(clockProvider)();
  }

  void _onShow() {
    final DateTime? hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null) return;
    if (ref.read(clockProvider)().difference(hiddenAt) >= widget.grace) {
      ref.read(appGateProvider.notifier).lock();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
