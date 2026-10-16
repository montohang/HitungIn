import 'package:flutter/widgets.dart';

/// Gaya set ikon di seluruh aplikasi (P2b). Duotone memakai glyph Garis
/// di atas glyph Isi transparan (lihat `HiIcon`).
enum HiIconStyle {
  garis('Garis', 'HitungInIcons'),
  isi('Isi', 'HitungInIconsIsi'),
  duotone('Duotone', 'HitungInIcons'),
  bulat('Bulat', 'HitungInIconsBulat');

  const HiIconStyle(this.label, this.family);
  final String label;
  final String family;

  bool get pro => this == duotone || this == bulat;
}

/// IconData HitungIn: kode glyph tetap, font mengikuti [HiIcons.style] —
/// semua `Icon(HiIcons.x)` ikut berganti gaya tanpa diubah satu per satu.
class HiIconData extends IconData {
  const HiIconData(super.codePoint) : super(fontFamily: 'HitungInIcons');

  @override
  String? get fontFamily => HiIcons.style.family;

  /// Glyph versi Isi (lapisan bawah Duotone).
  IconData get solid => IconData(codePoint, fontFamily: HiIconStyle.isi.family);

  /// Glyph versi Garis.
  IconData get line => IconData(codePoint, fontFamily: HiIconStyle.garis.family);
}

/// Ikon garis HitungIn (dihasilkan tool/icons/build_icons.py — jangan diedit manual).
abstract final class HiIcons {
  /// Gaya aktif; diatur dari pengaturan Tema (lihat app.dart).
  static HiIconStyle style = HiIconStyle.garis;

  /// back (desain).
  static const HiIconData back = HiIconData(0xe000);
  /// forward (desain).
  static const HiIconData forward = HiIconData(0xe001);
  /// close (desain).
  static const HiIconData close = HiIconData(0xe002);
  /// check (desain).
  static const HiIconData check = HiIconData(0xe003);
  /// plus (desain).
  static const HiIconData plus = HiIconData(0xe004);
  /// minus (gaya desain).
  static const HiIconData minus = HiIconData(0xe005);
  /// arrowRight (desain).
  static const HiIconData arrowRight = HiIconData(0xe006);
  /// home (desain).
  static const HiIconData home = HiIconData(0xe007);
  /// report (desain).
  static const HiIconData report = HiIconData(0xe008);
  /// target (desain).
  static const HiIconData target = HiIconData(0xe009);
  /// grid (desain).
  static const HiIconData grid = HiIconData(0xe00a);
  /// shield (desain).
  static const HiIconData shield = HiIconData(0xe00b);
  /// sparkle (desain).
  static const HiIconData sparkle = HiIconData(0xe00c);
  /// eye (desain).
  static const HiIconData eye = HiIconData(0xe00d);
  /// eyeOff (desain).
  static const HiIconData eyeOff = HiIconData(0xe00e);
  /// lock (desain).
  static const HiIconData lock = HiIconData(0xe00f);
  /// info (desain).
  static const HiIconData info = HiIconData(0xe010);
  /// warning (desain).
  static const HiIconData warning = HiIconData(0xe011);
  /// fingerprint (desain).
  static const HiIconData fingerprint = HiIconData(0xe012);
  /// filter (desain).
  static const HiIconData filter = HiIconData(0xe013);
  /// camera (desain).
  static const HiIconData camera = HiIconData(0xe014);
  /// search (desain).
  static const HiIconData search = HiIconData(0xe015);
  /// swap (desain).
  static const HiIconData swap = HiIconData(0xe016);
  /// bell (desain).
  static const HiIconData bell = HiIconData(0xe017);
  /// calendar (desain).
  static const HiIconData calendar = HiIconData(0xe018);
  /// download (desain).
  static const HiIconData download = HiIconData(0xe019);
  /// upload (desain).
  static const HiIconData upload = HiIconData(0xe01a);
  /// palette (desain).
  static const HiIconData palette = HiIconData(0xe01b);
  /// document (desain).
  static const HiIconData document = HiIconData(0xe01c);
  /// fileCheck (desain).
  static const HiIconData fileCheck = HiIconData(0xe01d);
  /// star (desain).
  static const HiIconData star = HiIconData(0xe01e);
  /// noAds (desain).
  static const HiIconData noAds = HiIconData(0xe01f);
  /// music (desain).
  static const HiIconData music = HiIconData(0xe020);
  /// wifi (desain).
  static const HiIconData wifi = HiIconData(0xe021);
  /// wallet (desain).
  static const HiIconData wallet = HiIconData(0xe022);
  /// cash (desain).
  static const HiIconData cash = HiIconData(0xe023);
  /// bank (desain).
  static const HiIconData bank = HiIconData(0xe024);
  /// phone (desain).
  static const HiIconData phone = HiIconData(0xe025);
  /// food (desain).
  static const HiIconData food = HiIconData(0xe026);
  /// shopping (desain).
  static const HiIconData shopping = HiIconData(0xe027);
  /// bolt (desain).
  static const HiIconData bolt = HiIconData(0xe028);
  /// bus (desain).
  static const HiIconData bus = HiIconData(0xe029);
  /// film (desain).
  static const HiIconData film = HiIconData(0xe02a);
  /// heart (desain).
  static const HiIconData heart = HiIconData(0xe02b);
  /// education (desain).
  static const HiIconData education = HiIconData(0xe02c);
  /// gift (desain).
  static const HiIconData gift = HiIconData(0xe02d);
  /// briefcase (desain).
  static const HiIconData briefcase = HiIconData(0xe02e);
  /// laptop (desain).
  static const HiIconData laptop = HiIconData(0xe02f);
  /// trendUp (desain).
  static const HiIconData trendUp = HiIconData(0xe030);
  /// dots (gaya desain).
  static const HiIconData dots = HiIconData(0xe031);
  /// store (gaya desain).
  static const HiIconData store = HiIconData(0xe032);
  /// backspace (gaya desain).
  static const HiIconData backspace = HiIconData(0xe033);
  /// edit (gaya desain).
  static const HiIconData edit = HiIconData(0xe034);
  /// trash (gaya desain).
  static const HiIconData trash = HiIconData(0xe035);
  /// copy (gaya desain).
  static const HiIconData copy = HiIconData(0xe036);
  /// repeat (gaya desain).
  static const HiIconData repeat = HiIconData(0xe037);
  /// user (gaya desain).
  static const HiIconData user = HiIconData(0xe038);
  /// history (gaya desain).
  static const HiIconData history = HiIconData(0xe039);
  /// restore (gaya desain).
  static const HiIconData restore = HiIconData(0xe03a);
  /// today (gaya desain).
  static const HiIconData today = HiIconData(0xe03b);
  /// pin (gaya desain).
  static const HiIconData pin = HiIconData(0xe03c);
  /// table (gaya desain).
  static const HiIconData table = HiIconData(0xe03d);
  /// hourglass (gaya desain).
  static const HiIconData hourglass = HiIconData(0xe03e);
  /// play (gaya desain).
  static const HiIconData play = HiIconData(0xe03f);
  /// receipt (gaya desain).
  static const HiIconData receipt = HiIconData(0xe040);
  /// bars (gaya desain).
  static const HiIconData bars = HiIconData(0xe041);
  /// checkCircle (gaya desain).
  static const HiIconData checkCircle = HiIconData(0xe042);
  /// error (gaya desain).
  static const HiIconData error = HiIconData(0xe043);
  /// gradient (gaya desain).
  static const HiIconData gradient = HiIconData(0xe044);
  /// jar (gaya desain).
  static const HiIconData jar = HiIconData(0xe045);
  /// chevronDown (gaya desain).
  static const HiIconData chevronDown = HiIconData(0xe046);
  /// pet (desain).
  static const HiIconData pet = HiIconData(0xe047);
  /// baby (desain).
  static const HiIconData baby = HiIconData(0xe048);
  /// fitness (desain).
  static const HiIconData fitness = HiIconData(0xe049);
  /// coffee (desain).
  static const HiIconData coffee = HiIconData(0xe04a);
  /// fuel (desain).
  static const HiIconData fuel = HiIconData(0xe04b);
  /// parking (desain).
  static const HiIconData parking = HiIconData(0xe04c);
  /// wrench (desain).
  static const HiIconData wrench = HiIconData(0xe04d);
  /// suitcase (desain).
  static const HiIconData suitcase = HiIconData(0xe04e);
  /// laundry (desain).
  static const HiIconData laundry = HiIconData(0xe04f);
  /// scissors (desain).
  static const HiIconData scissors = HiIconData(0xe050);
  /// pill (desain).
  static const HiIconData pill = HiIconData(0xe051);
  /// donation (desain).
  static const HiIconData donation = HiIconData(0xe052);
  /// people (desain).
  static const HiIconData people = HiIconData(0xe053);
  /// gamepad (desain).
  static const HiIconData gamepad = HiIconData(0xe054);
  /// signal (desain).
  static const HiIconData signal = HiIconData(0xe055);
  /// installment (desain).
  static const HiIconData installment = HiIconData(0xe056);
  /// coin (gaya desain).
  static const HiIconData coin = HiIconData(0xe057);

  /// Semua ikon (galeri desain).
  static const Map<String, HiIconData> all = {
    'back': back,
    'forward': forward,
    'close': close,
    'check': check,
    'plus': plus,
    'minus': minus,
    'arrowRight': arrowRight,
    'home': home,
    'report': report,
    'target': target,
    'grid': grid,
    'shield': shield,
    'sparkle': sparkle,
    'eye': eye,
    'eyeOff': eyeOff,
    'lock': lock,
    'info': info,
    'warning': warning,
    'fingerprint': fingerprint,
    'filter': filter,
    'camera': camera,
    'search': search,
    'swap': swap,
    'bell': bell,
    'calendar': calendar,
    'download': download,
    'upload': upload,
    'palette': palette,
    'document': document,
    'fileCheck': fileCheck,
    'star': star,
    'noAds': noAds,
    'music': music,
    'wifi': wifi,
    'wallet': wallet,
    'cash': cash,
    'bank': bank,
    'phone': phone,
    'food': food,
    'shopping': shopping,
    'bolt': bolt,
    'bus': bus,
    'film': film,
    'heart': heart,
    'education': education,
    'gift': gift,
    'briefcase': briefcase,
    'laptop': laptop,
    'trendUp': trendUp,
    'dots': dots,
    'store': store,
    'backspace': backspace,
    'edit': edit,
    'trash': trash,
    'copy': copy,
    'repeat': repeat,
    'user': user,
    'history': history,
    'restore': restore,
    'today': today,
    'pin': pin,
    'table': table,
    'hourglass': hourglass,
    'play': play,
    'receipt': receipt,
    'bars': bars,
    'checkCircle': checkCircle,
    'error': error,
    'gradient': gradient,
    'jar': jar,
    'chevronDown': chevronDown,
    'pet': pet,
    'baby': baby,
    'fitness': fitness,
    'coffee': coffee,
    'fuel': fuel,
    'parking': parking,
    'wrench': wrench,
    'suitcase': suitcase,
    'laundry': laundry,
    'scissors': scissors,
    'pill': pill,
    'donation': donation,
    'people': people,
    'gamepad': gamepad,
    'signal': signal,
    'installment': installment,
    'coin': coin,
  };
}
