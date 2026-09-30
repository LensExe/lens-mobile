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
    final p = profile;
    final name = p?.name ?? 'Elena Rostova';
    final avatar =
        p?.avatarUrl ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80';
    final rank = p?.rank ?? 'PRO GOLD';
    final city = p?.city ?? 'TP. Hồ Chí Minh';
    final rating = p?.rating.toStringAsFixed(2) ?? '4.98';
    final reviewCount = p?.reviewCount ?? 124;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  image: DecorationImage(
                    image: NetworkImage(avatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.snow, width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTypography.titleMd(
                          fontSize: 16,
                          color: AppColors.obsidian,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ember.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        rank,
                        style: AppTypography.numeric(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ember,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Nhiếp ảnh gia chuyên nghiệp • $city',
                  style: AppTypography.bodySm(
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.star,
                      size: 12,
                      color: AppColors.ember,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: AppTypography.numeric(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($reviewCount đánh giá)',
                      style: AppTypography.bodySm(
                        fontSize: 11,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
