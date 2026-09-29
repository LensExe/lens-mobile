import 'package:flutter/material.dart';

/// Shared geometry for the customer experience. Keeping these values together
/// prevents individual screens from slowly developing different visual rules.
abstract final class AppTokens {
  static const double pageHorizontal = 20;
  static const double pageHorizontalCompact = 16;
  static const double cardRadius = 20;
  static const double largeCardRadius = 28;
  static const double pillRadius = 999;
  static const double fieldRadius = 14;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
  );
  static const BoxShadow surfaceShadow = BoxShadow(
    color: Color(0x0A18181B),
    blurRadius: 24,
    offset: Offset(0, 10),
  );
}
