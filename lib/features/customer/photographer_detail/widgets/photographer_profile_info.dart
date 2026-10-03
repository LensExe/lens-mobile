import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/photographer_detail_model.dart';

/// Compact identity block that leaves the portfolio as the main event.
class PhotographerProfileInfo extends StatelessWidget {
  final PhotographerProfile profile;

  const PhotographerProfileInfo({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final styles = profile.styles.where((style) => style != 'Tất cả').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.avatarUrl,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ColoredBox(color: AppColors.fog),
                      errorWidget: (context, url, error) => const SizedBox(
                        width: 62,
                        height: 62,
                        child: Icon(LucideIcons.user, color: AppColors.steel),
                      ),
                    ),
                  ),
                  if (profile.isVerified)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.canvas, width: 2),
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: AppColors.snow,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd(fontSize: 21),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          profile.city,
                          style: AppTypography.bodySm(color: AppColors.steel),
                        ),
                        const Icon(
                          LucideIcons.star,
                          size: 13,
                          color: AppColors.ember,
                        ),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: AppTypography.numeric(fontSize: 12),
                        ),
                        Text(
                          '(${profile.reviewCount})',
                          style: AppTypography.bodySm(color: AppColors.steel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (styles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: styles
                  .map(
                    (style) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        borderRadius: BorderRadius.circular(
                          AppTokens.pillRadius,
                        ),
                      ),
                      child: Text(
                        style,
                        style: AppTypography.labelSm(color: AppColors.graphite),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              profile.bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd(color: AppColors.graphite)
                  .copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
