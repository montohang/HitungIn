import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/logo_mark.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';

/// Onboarding 3 halaman: kenalan, janji privasi, nama panggilan.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const int _pages = 3;
  final PageController _pager = PageController();
  final TextEditingController _name = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pages - 1) {
      await _pager.animateToPage(
        _page + 1,
        duration: context.reduceMotion ? const Duration(milliseconds: 1) : AppMotion.sheet,
        curve: AppMotion.easeOut,
      );
      return;
    }
    final String name = _name.text.trim();
    final settings = ref.read(appDatabaseProvider).settingsDao;
    if (name.isEmpty) {
      await settings.remove(SettingKeys.userName);
    } else {
      await settings.write(SettingKeys.userName, name);
    }
    if (mounted) context.go(Routes.setupPin);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _Slide(
                    hero: LogoMark(size: 96),
                    title: 'Catat uang,\ntanpa ribet.',
                    body: 'Ketik "kopi 25rb gopay" — HitungIn langsung tahu nominal, kategori, dan dompetnya.',
                  ),
                  _Slide(
                    hero: IconTile(icon: Icons.lock_outline, size: 96, color: c.goodInk, background: c.goodSoft),
                    title: '100% offline.\nDatamu milikmu.',
                    body: 'Tanpa akun, tanpa login, tanpa server. Catatan keuanganmu terenkripsi dan tidak pernah meninggalkan HP ini.',
                  ),
                  _NameSlide(controller: _name, onSubmit: _next),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x24),
              child: Column(
                children: [
                  _Dots(count: _pages, index: _page),
                  const SizedBox(height: AppSpace.x24),
                  AppButton(label: _page == _pages - 1 ? 'Mulai' : 'Lanjut', large: true, onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.hero, required this.title, required this.body});

  final Widget hero;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH, vertical: AppSpace.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpace.x32),
          hero,
          const SizedBox(height: AppSpace.x32),
          Text(title, style: t.pageTitle.copyWith(height: 1.15)),
          const SizedBox(height: AppSpace.x16),
          Text(body, style: t.body.copyWith(color: context.colors.sub)),
        ],
      ),
    );
  }
}

class _NameSlide extends StatelessWidget {
  const _NameSlide({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH, vertical: AppSpace.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpace.x32),
          IconTile(icon: Icons.waving_hand_outlined, size: 96, color: c.warnInk, background: c.warnSoft),
          const SizedBox(height: AppSpace.x32),
          Text('Mau dipanggil apa?', style: t.pageTitle.copyWith(height: 1.15)),
          const SizedBox(height: AppSpace.x16),
          Text('Untuk sapaan di beranda. Boleh dikosongkan.', style: t.body.copyWith(color: c.sub)),
          const SizedBox(height: AppSpace.x24),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            style: t.item,
            decoration: const InputDecoration(hintText: 'Nama panggilan', counterText: ''),
            onSubmitted: (_) => onSubmit(),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Halaman ${index + 1} dari $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: context.reduceMotion ? Duration.zero : AppMotion.press,
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(color: i == index ? c.accent : c.line2, borderRadius: AppRadius.pillAll),
            ),
        ],
      ),
    );
  }
}
