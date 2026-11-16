import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BadgeType { darkOverlay, darkFilled, ember, blue, purple, green, red }

class LensBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const LensBadge({
    super.key,
    required this.text,
    this.type = BadgeType.darkFilled,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    switch (type) {
      case BadgeType.darkOverlay:
        bgColor = Colors.transparent;
        textColor = AppColors.snow;
        border = Border.all(
          color: Colors.white.withAlpha(76),
        ); // approx 0.3 opacity
        break;
      case BadgeType.darkFilled:
        bgColor = AppColors.graphite;
        textColor = const Color(0xFFFAFAFA);
        break;
      case BadgeType.ember:
        bgColor = AppColors.ember;
        textColor = AppColors.snow;
        break;
      case BadgeType.blue:
        bgColor = Colors.blue;
        textColor = AppColors.snow;
        break;
      case BadgeType.purple:
        bgColor = Colors.purple;
        textColor = AppColors.snow;
        break;
      case BadgeType.green:
        bgColor = Colors.green;
        textColor = AppColors.snow;
        break;
      case BadgeType.red:
        bgColor = Colors.red;
        textColor = AppColors.snow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: type == BadgeType.ember
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
    );
  }
}
