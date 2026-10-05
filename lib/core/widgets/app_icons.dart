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
  };

  /// Pilihan ikon di form kategori.
  static const List<String> categoryKeys = [
    'food', 'transport', 'shopping', 'bills', 'home', 'fun', 'health', 'education',
    'gift', 'salary', 'bonus', 'business', 'invest', 'other',
  ];

  static IconData of(String key) => _map[key] ?? HiIcons.dots;
}
