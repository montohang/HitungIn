import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/context_ext.dart';
import '../../../core/widgets/hi_icons.dart';
import '../../../core/widgets/pressable.dart';
import '../../security/app_gate.dart';
import '../receipt_ocr.dart';

/// Rute Catat yang langsung membuka Scan struk.
String get receiptScanRoute => Uri(path: Routes.catat, queryParameters: {'scan': '1'}).toString();

/// Buka Catat lalu langsung Scan struk (kamera di Beranda, kartu kenalan).
void openReceiptScan(BuildContext context) => context.push(receiptScanRoute);

/// Kartu kenalan "Baru: foto struk, langsung tercatat" di bawah Ketik cepat.
/// Muncul sekali: hilang permanen setelah ditutup, dicoba, atau scan pernah dipakai.
class ScanIntroCard extends ConsumerWidget {
  const ScanIntroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Belum terbaca → anggap sudah, supaya kartu tidak berkedip muncul.
    if (ref.watch(scanIntroDoneProvider).valueOrNull ?? true) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    void done() => markScanIntroDone(ref.read(appDatabaseProvider).settingsDao);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.x12),
      child: Container(
        key: const Key('scan-intro'),
        decoration: BoxDecoration(color: c.accentSoft, borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Stack(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(14)))
                      .copyWith(color: c.accent),
                  child: Icon(HiIcons.receipt, size: 22, color: c.onAccent),
                ),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: c.accent, borderRadius: AppRadius.pillAll),
                        child: Text('BARU',
                            style: t.label.copyWith(
                                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.onAccent)),
                      ),
                      Text('Foto struk, langsung tercatat', style: t.title.copyWith(fontSize: 14, color: c.ink)),
                    ]),
                    const SizedBox(height: 3),
                    Text('Total, toko, tanggal & item terbaca otomatis · offline, foto tidak disimpan',
                        style: t.label.copyWith(fontWeight: FontWeight.w500, height: 1.4, color: c.sub)),
                    const SizedBox(height: AppSpace.x8),
                    Pressable(
                      key: const Key('scan-intro-try'),
                      onTap: () {
                        done();
                        openReceiptScan(context);
                      },
                      semanticLabel: 'Coba scan struk',
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration:
                            BoxDecoration(color: c.accent, borderRadius: const BorderRadius.all(Radius.circular(10))),
                        child: Center(
                          widthFactor: 1,
                          child: Text('Coba scan',
                              style: t.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: c.onAccent)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ])),
          Positioned(
            top: 8,
            right: 8,
            child: Pressable(
              key: const Key('scan-intro-close'),
              onTap: done,
              semanticLabel: 'Tutup perkenalan scan struk',
              child: SizedBox(width: 32, height: 32, child: Icon(HiIcons.close, size: 16, color: c.muted)),
            ),
          ),
        ]),
      ),
    );
  }
}
