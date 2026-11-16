import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../photographer_detail/models/photographer_detail_model.dart';

class PhotographerSummaryBanner extends StatelessWidget {
  final PhotographerProfile? profile;

  const PhotographerSummaryBanner({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final photographer = profile;
    if (photographer == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
          border: Border.all(color: AppColors.pebble),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.camera, color: AppColors.steel),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đang tải hồ sơ', style: AppTypography.titleMd()),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.fog,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.ember,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final styles = photographer.styles
        .where((style) => style != 'Tất cả')
        .take(2)
        .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: photographer.avatarUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const ColoredBox(color: AppColors.fog),
              errorWidget: (context, url, error) => const SizedBox(
                width: 54,
                height: 54,
                child: Icon(LucideIcons.camera, color: AppColors.steel),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photographer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    photographer.city,
                    styles,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                if (photographer.reviewCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.star,
                        size: 13,
                        color: AppColors.ember,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photographer.rating.toStringAsFixed(1),
                        style: AppTypography.numeric(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${photographer.reviewCount})',
                        style: AppTypography.bodySm(
                          color: AppColors.steel,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (photographer.isVerified) ...[
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.badgeCheck,
              size: 19,
              color: AppColors.lagoon,
            ),
          ],
        ],
      ),
    );
  }
}
