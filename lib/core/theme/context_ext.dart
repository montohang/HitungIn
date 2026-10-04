import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

extension HitungInTheme on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  AppText get text => Theme.of(this).extension<AppText>()!;

  /// True bila pengguna menyalakan "kurangi gerakan" di HP.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
