import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

abstract final class AppFonts {
  static const title = 'Caveat';
  static const label = 'PatrickHand';
  static const hand = 'Kalam';
  static const body = 'Nunito';
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.rosePink,
    brightness: Brightness.light,
    primary: AppColors.rosePink,
    onPrimary: Colors.white,
    surface: AppColors.ivory,
    onSurface: AppColors.charcoal,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ivory,
    fontFamily: AppFonts.body,
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.ivory),
    bottomSheetTheme:
        const BottomSheetThemeData(backgroundColor: AppColors.ivory),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.charcoal,
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
}
