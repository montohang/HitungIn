import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/core/db/providers.dart';
import 'package:hitungin/core/theme/theme_controller.dart';
import 'package:hitungin/core/widgets/hi_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => applyIconLook(const ThemeSettings()));

  test('gaya ikon mengganti font semua ikon tanpa mengubah kode glyph', () {
    const icon = HiIcons.calendar;
    applyIconLook(const ThemeSettings(iconStyle: HiIconStyle.isi, iconWrap: IconWrap.lingkaran));
    expect((icon.fontFamily, icon.codePoint), ('HitungInIconsIsi', HiIcons.calendar.codePoint));
    expect(IconLook.wrap, IconWrap.lingkaran);
    applyIconLook(const ThemeSettings(iconStyle: HiIconStyle.bulat));
    expect(icon.fontFamily, 'HitungInIconsBulat');
    applyIconLook(const ThemeSettings(iconStyle: HiIconStyle.duotone));
    expect(icon.fontFamily, 'HitungInIcons', reason: 'Duotone: garis di atas versi Isi');
    expect((icon.solid.fontFamily, icon.line.fontFamily), ('HitungInIconsIsi', 'HitungInIcons'));
    expect(HiIconStyle.values.where((s) => s.pro), [HiIconStyle.duotone, HiIconStyle.bulat]);
  });

  test('pilihan wadah ikon & label tab tersimpan', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final ctl = container.read(themeControllerProvider.notifier);
    ctl.setIconWrap(IconWrap.tanpa);
    ctl.setTabLabels(false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final s = await loadThemeSettings(db.settingsDao);
    expect((s.iconWrap, s.tabLabels), (IconWrap.tanpa, false));
    expect(const ThemeSettings().tabLabels, isTrue, reason: 'bawaan: label tampil');
    container.dispose();
    await db.close();
  });
}
