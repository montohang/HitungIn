import 'package:flutter/material.dart';

/// Kunci ikon yang disimpan di database (kolom `icon`) → IconData.
/// Jangan mengganti kunci yang sudah ada; cukup tambah yang baru.
abstract final class AppIcons {
  static const Map<String, IconData> _map = {
    // Dompet
    'wallet': Icons.account_balance_wallet_outlined,
    'cash': Icons.payments_outlined,
    'bank': Icons.account_balance_outlined,
    'ewallet': Icons.phone_iphone_outlined,
    // Kategori
    'food': Icons.local_cafe_outlined,
    'transport': Icons.directions_bus_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'bills': Icons.bolt_outlined,
    'home': Icons.home_outlined,
    'fun': Icons.movie_outlined,
    'health': Icons.favorite_border,
    'education': Icons.school_outlined,
    'gift': Icons.card_giftcard_outlined,
    'salary': Icons.work_outline,
    'bonus': Icons.star_outline,
    'business': Icons.storefront_outlined,
    'invest': Icons.trending_up,
    'other': Icons.more_horiz,
  };

  static IconData of(String key) => _map[key] ?? Icons.more_horiz;
}
