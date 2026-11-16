import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../discovery/models/photographer_model.dart';
import 'overview_section_heading.dart';

class RecommendationCard extends StatelessWidget {
  final PhotographerModel photographer;
  const RecommendationCard({super.key, required this.photographer});

  @override
  Widget build(BuildContext context) {
    final imageUrl = photographer.coverImageUrl.isNotEmpty
        ? photographer.coverImageUrl
        : photographer.avatarUrl;

    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: () =>
            context.push('/customer_home/photographer/${photographer.id}'),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            color: AppColors.slate,
            border: Border.all(color: AppColors.pebble),
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassContainer.mediaBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            color: AppColors.ember,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            photographer.rating.toStringAsFixed(1),
                            style: AppTypography.numeric(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (photographer.isFeatured)
                      const Icon(
                        LucideIcons.badgeCheck,
                        color: AppColors.emerald,
                        size: 18,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  photographer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${photographer.city} · ${photographer.styles.take(1).join()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTypography.formatCurrency(photographer.pricePerSession),
                  style: AppTypography.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverviewDiscoverySection extends StatelessWidget {
  final AsyncValue<List<PhotographerModel>> recommendations;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;

  const OverviewDiscoverySection({
    super.key,
    required this.recommendations,
    required this.onRetry,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.pageHorizontal, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.pageHorizontal),
            child: OverviewSectionHeading(
              title: 'Gợi ý dành cho bạn',
              subtitle: 'Theo phong cách và khu vực trong hồ sơ của bạn',
              onSeeAll: onSeeAll,
            ),
          ),
          const SizedBox(height: 14),
          recommendations.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              ),
            ),
            error: (error, _) => SizedBox(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Không thể tải danh sách gợi ý. Vui lòng thử lại.',
                      style: AppTypography.bodySm(color: AppColors.steel),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
            data: (photographers) => photographers.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Chưa có nhiếp ảnh gia phù hợp với hồ sơ của bạn.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm(color: AppColors.steel),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        right: AppTokens.pageHorizontal,
                      ),
                      itemCount: photographers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => RecommendationCard(
                        photographer: photographers[index],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

