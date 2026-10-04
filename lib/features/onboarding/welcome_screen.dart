import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/providers.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/context_ext.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/logo_mark.dart';
import '../../core/widgets/pressable.dart';
import '../backup/restore_flow.dart';
import '../security/app_gate.dart';
import '../settings/data/settings_dao.dart';
import 'widgets/welcome_illustrations.dart';

/// Isi halaman sapaan 1–3 (teks dari Claude Design; halaman 3 disesuaikan
/// karena Target Tabungan belum ada). Halaman 4 = nama panggilan.
const List<(WelcomeArt, String, String)> welcomeSlides = [
  (
    WelcomeArt.privasi,
    'Data keuanganmu tetap di HP-mu',
    'Tanpa login, tanpa server. Semua catatan terenkripsi dan hanya bisa dibuka olehmu.',
  ),
  (
    WelcomeArt.catatCepat,
    'Catat cukup dengan satu kalimat',
    'Ketik "kopi 25rb gopay" dan HitungIn langsung mengisi nominal, kategori, dan dompetnya.',
  ),
  (
    WelcomeArt.rencana,
    'Bukan cuma mencatat, tapi merencanakan',
    'Atur budget, pantau tagihan, dan dapat peringatan sebelum uangmu kebablasan.',
  ),
];

/// Sapaan 4 halaman: 3 pengenalan + nama panggilan. "Lewati" (seperti desain)
/// langsung ke Buat PIN tanpa menyimpan nama.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const int _pages = 4;
  final TextEditingController _name = TextEditingController();
  int _step = 0;
  bool _restoring = false;

  bool get _isNamePage => _step == _pages - 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _go(int step) {
    if (step < 0 || step >= _pages) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  Future<void> _finish({bool saveName = true}) async {
    final settings = ref.read(appDatabaseProvider).settingsDao;
    final String name = _name.text.trim();
    if (saveName && name.isNotEmpty) {
      await settings.write(SettingKeys.userName, name);
    } else if (saveName) {
      await settings.remove(SettingKeys.userName);
    }
    if (mounted) context.go(Routes.setupPin);
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final bool ok = await runRestoreFlow(context, ref, onboarding: true);
      if (ok && mounted) context.go(Routes.setupPin);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bool reduce = context.reduceMotion;
    final (WelcomeArt art, String title, String body) = _isNamePage
        ? (WelcomeArt.nama, 'Mau dipanggil apa?', 'Untuk sapaan di beranda dan layar kunci. Boleh dikosongkan, bisa diubah nanti.')
        : welcomeSlides[_step];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_step - 1);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.x8, AppSpace.screenH, AppSpace.x24),
            child: Column(
              children: [
                // Header: logo + Lewati.
                SizedBox(
                  height: AppSpace.touch,
                  child: Row(
                    children: [
                      const LogoMark(size: 32),
                      const SizedBox(width: AppSpace.x8),
                      Text('HitungIn', style: t.screenTitle.copyWith(fontSize: 18)),
                      const Spacer(),
                      Pressable(
                        onTap: () => _finish(saveName: false),
                        semanticLabel: 'Lewati',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16, vertical: AppSpace.x12),
                          child: Text('Lewati', style: t.label.copyWith(fontSize: 14, color: c.sub)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (d) {
                      final double v = d.primaryVelocity ?? 0;
                      if (v < -250) _go(_step + 1);
                      if (v > 250) _go(_step - 1);
                    },
                    child: AnimatedSwitcher(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
                      switchInCurve: AppMotion.easeOut,
                      // Isi menempel di atas (ilustrasi tepat di bawah header, seperti desain).
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
                      ),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _Slide(
                        key: ValueKey(_step),
                        art: art,
                        title: title,
                        body: body,
                        nameField: _isNamePage
                            ? TextField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                maxLength: 24,
                                style: t.item,
                                decoration: const InputDecoration(hintText: 'Nama panggilan', counterText: ''),
                                onSubmitted: (_) => _finish(),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.x16),
                _Dots(count: _pages, index: _step),
                const SizedBox(height: AppSpace.x24),
                AppButton(
                  label: _isNamePage ? 'Mulai sekarang' : 'Lanjut',
                  large: true,
                  onPressed: _restoring ? null : (_isNamePage ? _finish : () => _go(_step + 1)),
                ),
                const SizedBox(height: AppSpace.x16),
                Semantics(
                  button: true,
                  label: 'Sudah pernah pakai? Pulihkan dari backup',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _restoring ? null : _restore,
                    child: ExcludeSemantics(
                      child: Text.rich(
                        TextSpan(
                          text: 'Sudah pernah pakai? ',
                          children: [
                            TextSpan(
                              text: 'Pulihkan dari backup',
                              style: TextStyle(fontWeight: FontWeight.w700, color: c.accentText),
                            ),
                          ],
                        ),
                        style: t.caption.copyWith(color: c.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

class _Slide extends StatelessWidget {
  const _Slide({super.key, required this.art, required this.title, required this.body, this.nameField});

  final WelcomeArt art;
  final String title;
  final String body;
  final Widget? nameField;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    // Ilustrasi mengecil saat ruang sempit (layar pendek / keyboard terbuka).
    return LayoutBuilder(
      builder: (context, box) {
        final double artH = (box.maxHeight - (nameField != null ? 230 : 170)).clamp(0.0, 340.0);
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (artH >= 160)
                SizedBox(
                  height: artH,
                  child: Center(child: WelcomeIllustration(art: art, colors: c)),
                ),
              const SizedBox(height: AppSpace.x16),
              Text(title, style: t.greeting.copyWith(fontSize: 30, height: 1.15)),
              const SizedBox(height: AppSpace.x12),
              Text(body, style: t.body.copyWith(fontSize: 16, height: 1.6, color: c.sub)),
              if (nameField != null) ...[
                const SizedBox(height: AppSpace.x16),
                nameField!,
              ],
            ],
          ),
        );
      },
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
      label: 'Langkah ${index + 1} dari $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
              curve: AppMotion.easeOut,
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
