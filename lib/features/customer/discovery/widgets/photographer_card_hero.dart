import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

class PhotographerCardHero extends StatefulWidget {
  final PhotographerModel photographer;
  final VoidCallback onTap;

  const PhotographerCardHero({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  @override
  State<PhotographerCardHero> createState() => _PhotographerCardHeroState();
}

class _PhotographerCardHeroState extends State<PhotographerCardHero> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final images = PhotographerDisplayHelper.getGalleryImages(widget.photographer);
    final priceStr = PhotographerDisplayHelper.formatPrice(widget.photographer.pricePerSession);
    final subtitle = PhotographerDisplayHelper.getCategorySubtitle(widget.photographer);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
        border: Border.all(color: AppColors.pebble, width: 1.0),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-width Hero Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: images[0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppColors.mist),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.mist,
                            child: const Icon(
                              LucideIcons.imageOff,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                        // Top-left Availability Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTokens.pillRadius,
                              ),
                              boxShadow: const [AppTokens.surfaceShadow],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Có lịch thứ Bảy này',
                                  style: AppTypography.labelMd(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Top-right Glassmorphic Heart Button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                            child: GlassContainer.floatingControl(
                              size: 36,
                              isDark: true,
                              child: Icon(
                                isFavorite ? Icons.favorite : LucideIcons.heart,
                                color: isFavorite
                                    ? AppColors.ember
                                    : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left Film & Equipment Badges (Glassmorphic)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Row(
                            children: [
                              GlassContainer.mediaBadge(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Máy phim 35mm',
                                  style: AppTypography.labelSm(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GlassContainer.mediaBadge(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Ánh sáng Studio',
                                  style: AppTypography.labelSm(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Rating Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.photographer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: AppColors.emerald, // Emerald per DESIGN.md
                      size: 18,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        borderRadius: BorderRadius.circular(
                          AppTokens.nestedBadgeRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.ember,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.photographer.rating.toStringAsFixed(2),
                            style: AppTypography.numeric(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  style: AppTypography.bodySm(color: AppColors.steel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Full Session Price & Dual Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trọn gói / buổi',
                          style: AppTypography.labelSm(color: AppColors.steel),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceStr,
                          style: AppTypography.priceDisplay(fontSize: 20),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Profile button (Secondary Action per DESIGN.md)
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.snow,
                          borderRadius: BorderRadius.circular(
                            AppTokens.pillRadius,
                          ),
                          border: Border.all(
                            color: AppColors.pebble,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'Hồ sơ',
                          style: AppTypography.titleMd(
                            color: AppColors.obsidian,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Instant Book button (Primary Action per DESIGN.md)
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ember,
                          borderRadius: BorderRadius.circular(
                            AppTokens.pillRadius,
                          ),
                          boxShadow: const [AppTokens.surfaceShadow],
                        ),
                        child: Text(
                          'Đặt lịch ngay',
                          style: AppTypography.titleMd(
                            color: Colors.white,
                            fontSize: 13,
                          ),
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
    );
  }
}
