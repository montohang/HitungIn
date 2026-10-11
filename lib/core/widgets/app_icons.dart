import 'package:flutter/material.dart';
import 'hi_icons.dart';

/// Kunci ikon yang disimpan di database (kolom `icon`) → IconData.
/// Jangan mengganti kunci yang sudah ada; cukup tambah yang baru.
abstract final class AppIcons {
  static const Map<String, IconData> _map = {
    // Dompet
    'wallet': HiIcons.wallet,
    'cash': HiIcons.cash,
    'bank': HiIcons.bank,
    'ewallet': HiIcons.phone,
    // Kategori
    'food': HiIcons.food,
    'transport': HiIcons.bus,
    'shopping': HiIcons.shopping,
    'bills': HiIcons.bolt,
    'home': HiIcons.home,
    'fun': HiIcons.film,
    'health': HiIcons.heart,
    'education': HiIcons.education,
    'gift': HiIcons.gift,
    'salary': HiIcons.briefcase,
    'bonus': HiIcons.star,
    'business': HiIcons.store,
    'invest': HiIcons.trendUp,
    'other': HiIcons.dots,
    // P1-4
    'pet': HiIcons.pet,
    'baby': HiIcons.baby,
    'fitness': HiIcons.fitness,
    'coffee': HiIcons.coffee,
    'fuel': HiIcons.fuel,
    'parking': HiIcons.parking,
    'service': HiIcons.wrench,
    'travel': HiIcons.suitcase,
    'laundry': HiIcons.laundry,
    'beauty': HiIcons.scissors,
    'medicine': HiIcons.pill,
    'donation': HiIcons.donation,
    'arisan': HiIcons.people,
    'game': HiIcons.gamepad,
    'data': HiIcons.signal,
    'installment': HiIcons.installment,
  };

  /// Pilihan ikon di form kategori.
  static const List<String> categoryKeys = [
    'food', 'transport', 'shopping', 'bills', 'home', 'fun', 'health', 'education',
    'gift', 'salary', 'bonus', 'business', 'invest', 'other',
    'pet', 'baby', 'fitness', 'coffee', 'fuel', 'parking', 'service', 'travel',
    'laundry', 'beauty', 'medicine', 'donation', 'arisan', 'game', 'data', 'installment',
  ];

  /// Emoji pilihan pengguna disimpan di kolom ikon sebagai `e:🍜` (P1-4).
  static const String emojiPrefix = 'e:';

  /// Emoji pilihan untuk kategori/dompet (Unicode ≤ 12 supaya tampil di HP lama).
  static const List<String> emojiChoices = [
    '🍜', '🍔', '☕', '🥤', '🍱', '🍳', '🛒', '🥦', '🚗', '🛵', '🚌', '⛽', '🏠', '💡', '💧', '🔥',
    '📱', '💻', '🎮', '🎬', '🎵', '📚', '🎓', '💊', '🏥', '🐱', '🐶', '👶', '👕', '💄', '🎁', '💝',
    '🤲', '💰', '💳', '🏦', '📈', '🧾', '🎉', '🧺',
  ];

  static String emojiKey(String emoji) => '$emojiPrefix$emoji';

  /// Emoji bila kunci berupa emoji, selain itu null.
  static String? emojiOf(String key) =>
      key.startsWith(emojiPrefix) && key.length > emojiPrefix.length ? key.substring(emojiPrefix.length) : null;

  static IconData of(String key) => _map[key] ?? HiIcons.dots;
}
