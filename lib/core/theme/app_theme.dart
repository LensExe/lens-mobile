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
      fontFamily: GoogleFonts.dmSans().fontFamily,
      textTheme: GoogleFonts.dmSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w700,
          color: AppColors.obsidian,
          height: 1.0,
          letterSpacing: -1.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: AppColors.obsidian,
          height: 1.12,
          letterSpacing: -0.5,
        ),
        displaySmall: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: AppColors.obsidian,
          height: 1.25,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.obsidian,
          height: 1.28,
          letterSpacing: -0.5,
        ),
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.obsidian,
          height: 1.35,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.obsidian,
          height: 1.45,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.obsidian,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.obsidian,
          height: 1.56,
        ),
        labelSmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.steel,
          height: 1.8,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.obsidian,
        secondary: AppColors.ember,
        surface: AppColors.snow,
        surfaceContainerHighest: AppColors.fog,
        error: AppColors.destructive,
        onPrimary: AppColors.snow,
        onSecondary: AppColors.snow,
        onSurface: AppColors.ink,
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
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.pebble),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.pebble),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.obsidian, width: 1.2),
        ),
        hintStyle: const TextStyle(color: AppColors.ash, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.snow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.pebble),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: AppColors.snow,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.obsidian,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: AppColors.pebble),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.snow,
        selectedItemColor: AppColors.obsidian,
        unselectedItemColor: AppColors.steel,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
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
