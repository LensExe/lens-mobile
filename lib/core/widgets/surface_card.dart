import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final bool isMuted;

  const SurfaceCard({super.key, required this.child, this.isMuted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isMuted ? AppColors.fog : AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppColors.pebble, width: 1.0),
        boxShadow: isMuted ? null : const [AppTokens.surfaceShadow],
      ),
      child: child,
    );
  }
}
