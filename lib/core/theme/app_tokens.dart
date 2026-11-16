import 'package:flutter/material.dart';

/// Shared geometry for the customer experience. Keeping these values together
/// prevents individual screens from slowly developing different visual rules.
abstract final class AppTokens {
  static const double pageHorizontal = 16;
  static const double pageHorizontalCompact = 16;
  static const double cardRadius = 20;
  static const double largeCardRadius = 24;
  static const double pillRadius = 9999;
  static const double fieldRadius = 9999; // Search & inputs use pill by default
  static const double inputFieldRadius = 14; // Form text fields
  static const double nestedBadgeRadius = 12;
  static const double bottomSheetRadius = 24;

  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Component heights
  static const double primaryButtonHeight = 52;
  static const double filterChipHeight = 36;
  static const double searchBarHeight = 48;
  static const double iconButtonSize = 44;

  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );

  // Elevation Level 1 (Surface Cards) - Subtle ambient shadow
  static const BoxShadow surfaceShadow = BoxShadow(
    color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  // Elevation Level 2 (Floating Controls / Cards)
  static const BoxShadow floatingShadow = BoxShadow(
    color: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  // Elevation Level 3 (Modals & Bottom Sheets)
  static const BoxShadow modalShadow = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    blurRadius: 32,
    offset: Offset(0, -8),
  );
}
