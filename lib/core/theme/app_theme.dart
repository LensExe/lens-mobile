import 'package:flutter/material.dart';
import 'app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.obsidian,
      scaffoldBackgroundColor: AppColors.mist,
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.obsidian, height: 1.0, letterSpacing: -1.5),
        displayMedium: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: AppColors.obsidian, height: 1.12, letterSpacing: -0.5),
        displaySmall: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.obsidian, height: 1.25, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.obsidian, height: 1.28, letterSpacing: -0.5),
        headlineSmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.obsidian, height: 1.35),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.obsidian, height: 1.45),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.obsidian, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.obsidian, height: 1.56),
        labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.steel, height: 1.8),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.obsidian,
        secondary: AppColors.ember,
        surface: AppColors.snow,
        error: AppColors.destructive,
        onPrimary: AppColors.snow,
        onSecondary: AppColors.snow,
        onSurface: AppColors.ink,
        onError: AppColors.snow,
      ),
    );
  }
}
