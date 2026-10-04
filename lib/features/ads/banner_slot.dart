import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/context_ext.dart';
import 'ad_ids.dart';

/// Banner adaptif selebar layar. Tidak memakan tempat sampai iklan termuat,
/// dan hilang lagi bila gagal (tidak ada kotak kosong).
class BannerSlot extends ConsumerStatefulWidget {
  const BannerSlot({super.key});

  @override
  ConsumerState<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends ConsumerState<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int width = MediaQuery.sizeOf(context).width.truncate();
    if (width != _width) {
      _width = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    await _ad?.dispose();
    setState(() {
      _ad = null;
      _loaded = false;
    });
    final AnchoredAdaptiveBannerAdSize? size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final BannerAd ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    setState(() => _ad = ad);
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BannerAd? ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return Semantics(
      label: 'Iklan',
      child: ColoredBox(
        color: context.colors.surface,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
