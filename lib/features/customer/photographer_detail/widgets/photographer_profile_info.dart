import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/photographer_detail_model.dart';

class PhotographerProfileInfo extends StatelessWidget {
  final PhotographerProfile profile;

  const PhotographerProfileInfo({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avatar & Identity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with active verified badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.snow, width: 3),
                      boxShadow: const [AppTokens.surfaceShadow],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.fog),
                        errorWidget: (context, url, error) => const Icon(
                          LucideIcons.user,
                          size: 36,
                          color: AppColors.steel,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.snow, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name, Rank & City
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: AppTypography.headlineSm(
                              fontSize: 20,
                              color: AppColors.obsidian,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.fog,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            profile.rank,
                            style: AppTypography.numeric(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // City & Rating
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 13, color: AppColors.steel),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            profile.city,
                            style: AppTypography.bodySm(
                              fontSize: 12.5,
                              color: AppColors.steel,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.steel,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.star, color: AppColors.ember, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${profile.rating}',
                          style: AppTypography.numeric(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.obsidian,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${profile.reviewCount})',
                          style: AppTypography.bodySm(
                            fontSize: 11.5,
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
          const SizedBox(height: 16),

          // 2. Bio Summary
          Text(
            profile.bio,
            style: AppTypography.bodySm(
              fontSize: 13.5,
              color: AppColors.graphite,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),

          // 3. Trust Metrics Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  '${profile.experienceYears}+ Năm',
                  'Kinh nghiệm',
                  LucideIcons.award,
                ),
                _buildDivider(),
                _buildMetricItem(
                  '${profile.completedShoots}+',
                  'Buổi chụp xong',
                  LucideIcons.camera,
                ),
                _buildDivider(),
                _buildMetricItem(
                  '${profile.completionRate}%',
                  'Nghiệm thu',
                  LucideIcons.shieldCheck,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.ember),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.numeric(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.obsidian,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSm(
            fontSize: 11,
            color: AppColors.steel,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.pebble,
    );
  }
}
