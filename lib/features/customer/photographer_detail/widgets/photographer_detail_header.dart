import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../models/photographer_detail_model.dart';

class PhotographerDetailHeader extends StatelessWidget {
  final PhotographerProfile profile;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleBookmark;

  const PhotographerDetailHeader({
    super.key,
    required this.profile,
    required this.isBookmarked,
    required this.onBack,
    required this.onShare,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 296,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cover Image
          CachedNetworkImage(
            imageUrl: profile.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: const Color(0xFFE8E8E9)),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFE8E8E9),
              child: const Icon(
                LucideIcons.image,
                color: Color(0xFF5F5E60),
                size: 40,
              ),
            ),
          ),

          // 2. Gradient Overlay for smooth transition into background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black38,
                  Colors.transparent,
                  Color(0x40F9F9FA),
                  Color(0xFFF9F9FA),
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),

          // 3. Top Action Row with Safe Area (Glassmorphic Floating Controls 44x44px)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Glassmorphic 44px)
                    GestureDetector(
                      onTap: onBack,
                      child: GlassContainer.floatingControl(
                        size: AppTokens.iconButtonSize,
                        child: const Icon(
                          LucideIcons.arrowLeft,
                          color: AppColors.obsidian,
                          size: 18,
                        ),
                      ),
                    ),

                    // Right Actions (Share + Favorite)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onShare,
                          child: GlassContainer.floatingControl(
                            size: AppTokens.iconButtonSize,
                            child: const Icon(
                              LucideIcons.share2,
                              color: AppColors.obsidian,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onToggleBookmark,
                          child: GlassContainer.floatingControl(
                            size: AppTokens.iconButtonSize,
                            child: Icon(
                              isBookmarked ? Icons.favorite : LucideIcons.heart,
                              color: isBookmarked
                                  ? AppColors.ember
                                  : AppColors.obsidian,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Studio Verified & Insured Floating Badge (Glassmorphic with Emerald Accent)
          if (profile.isVerified)
            Positioned(
              left: 16,
              bottom: 14,
              child: GlassContainer.mediaBadge(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: AppColors.emerald, // Emerald #16A34A per DESIGN.md
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đã xác minh',
                      style: AppTypography.labelSm(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
