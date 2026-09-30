import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';

/// Design system typography tokens strictly aligned with DESIGN.md
abstract final class AppTypography {
  // --- Display & Headlines ---
  static TextStyle display({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 36,
    fontWeight: FontWeight.w800,
    height: 44 / 36,
    letterSpacing: -0.03 * (fontSize ?? 36),
    color: color,
  );

  static TextStyle headlineLg({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.025 * (fontSize ?? 28),
    color: color,
  );

  static TextStyle headlineMd({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.02 * (fontSize ?? 22),
    color: color,
  );

  static TextStyle headlineSm({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.015 * (fontSize ?? 18),
    color: color,
  );

  static TextStyle titleMd({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: -0.01 * (fontSize ?? 16),
    color: color,
  );

  // --- Body ---
  static TextStyle bodyLg({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: -0.005 * (fontSize ?? 16),
    color: color,
  );

  static TextStyle bodyMd({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: color,
  );

  static TextStyle bodySm({
    Color color = AppColors.steel,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    letterSpacing: 0,
    color: color,
  );

  // --- Labels ---
  static TextStyle labelMd({
    Color color = AppColors.obsidian,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.02 * (fontSize ?? 12),
    color: color,
  );

  static TextStyle labelSm({
    Color color = AppColors.steel,
    double? fontSize,
  }) => GoogleFonts.inter(
    fontSize: fontSize ?? 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
    letterSpacing: 0.03 * (fontSize ?? 11),
    color: color,
  );

  // --- Price Display with Tabular Figures ---
  static TextStyle priceDisplay({
    Color color = AppColors.obsidian,
    double fontSize = 20,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    height: 24 / 20,
    letterSpacing: -0.02 * 20,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // --- Numeric / Metric Tabular Style (Ratings, focal lengths, apertures) ---
  static TextStyle numeric({
    Color color = AppColors.obsidian,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w700,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // --- Currency & Numeric Formatting Helper ---
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );

  static String formatCurrency(num amount) => _vndFormat.format(amount);
}
