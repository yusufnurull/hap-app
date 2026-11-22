// Konfigurasi tema visual aplikasi (Material 3, palet Hap!).

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gaya teks ringkas. [tabular] dipakai untuk angka (harga, jam, jumlah).
TextStyle hapText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.textDark,
  bool tabular = false,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.textDark,
        surface: Colors.white,
        onSurface: AppColors.textDark,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      dividerColor: AppColors.surface,
      dividerTheme: const DividerThemeData(
        color: AppColors.surface,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
