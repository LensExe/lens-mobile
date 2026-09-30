import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.obsidian,
      scaffoldBackgroundColor: AppColors.mist,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: AppTypography.display(),
        headlineLarge: AppTypography.headlineLg(),
        headlineMedium: AppTypography.headlineMd(),
        headlineSmall: AppTypography.headlineSm(),
        titleLarge: AppTypography.headlineSm(),
        titleMedium: AppTypography.titleMd(),
        bodyLarge: AppTypography.bodyLg(),
        bodyMedium: AppTypography.bodyMd(),
        bodySmall: AppTypography.bodySm(),
        labelLarge: AppTypography.titleMd(),
        labelMedium: AppTypography.labelMd(),
        labelSmall: AppTypography.labelSm(),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.obsidian,
        secondary: AppColors.ember,
        surface: AppColors.snow,
        surfaceContainerHighest: AppColors.fog,
        error: AppColors.destructive,
        onPrimary: AppColors.snow,
        onSecondary: AppColors.snow,
        onSurface: AppColors.obsidian,
        onError: AppColors.snow,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mist,
        foregroundColor: AppColors.obsidian,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.snow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
          borderSide: const BorderSide(color: AppColors.pebble),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
          borderSide: const BorderSide(color: AppColors.pebble),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
          borderSide: const BorderSide(color: AppColors.obsidian, width: 1.2),
        ),
        hintStyle: const TextStyle(color: AppColors.ash, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.snow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          side: const BorderSide(color: AppColors.pebble, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: AppColors.snow,
          elevation: 0,
          minimumSize: const Size(0, AppTokens.primaryButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.pillRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01 * 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.obsidian,
          backgroundColor: AppColors.snow,
          minimumSize: const Size(0, AppTokens.primaryButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.pebble, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.pillRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01 * 15,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, // Handled by frosted container
        selectedItemColor: AppColors.obsidian,
        unselectedItemColor: AppColors.steel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }
}
