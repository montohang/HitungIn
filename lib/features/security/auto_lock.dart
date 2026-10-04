import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/secure_store.dart';
import 'app_gate.dart';
import 'auto_lock_setting.dart';

/// Mengunci aplikasi bila ditinggal di latar belakang lebih lama dari
/// jeda pilihan pengguna. Dipasang sekali di atas router (lihat app.dart).
/// Lama jeda diatur di Pengaturan ([autoLockProvider]).
class AutoLock extends ConsumerStatefulWidget {
  const AutoLock({super.key, required this.child});

  final Widget child;

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
    if (ref.read(autoLockPausedProvider)) return;
    _hiddenAt = ref.read(clockProvider)();
  }

  void _onShow() {
    final DateTime? hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null) return;
    if (ref.read(clockProvider)().difference(hiddenAt) >= ref.read(autoLockProvider).duration) {
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
