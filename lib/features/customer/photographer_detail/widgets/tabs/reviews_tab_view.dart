import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../models/photographer_detail_model.dart';

class ReviewsTabView extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<ClientReview> reviews;

  const ReviewsTabView({
    super.key,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header with overall rating score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Đánh giá từ khách hàng',
                      style: AppTypography.headlineSm(
                        fontSize: 17,
                        color: AppColors.obsidian,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.ember.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.star, size: 12, color: AppColors.ember),
                        const SizedBox(width: 3),
                        Text(
                          '$rating',
                          style: AppTypography.numeric(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ember,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Xem tất cả ($reviewCount)',
              style: AppTypography.labelMd(
                fontSize: 12,
                color: AppColors.ember,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Reviews List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rev = reviews[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Identity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.fog,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                rev.clientInitials,
                                style: AppTypography.numeric(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.obsidian,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rev.clientName,
                                    style: AppTypography.titleMd(
                                      fontSize: 14,
                                      color: AppColors.obsidian,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rev.clientRole,
                                    style: AppTypography.bodySm(
                                      fontSize: 11.5,
                                      color: AppColors.steel,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rev.timeAgo,
                        style: AppTypography.labelSm(
                          fontSize: 11,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stars & Tag
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (starIdx) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(
                              LucideIcons.star,
                              color: AppColors.ember,
                              size: 13,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.fog,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          rev.packageTag,
                          style: AppTypography.labelSm(
                            fontSize: 10.5,
                            color: AppColors.steel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Content
                  Text(
                    rev.content,
                    style: AppTypography.bodySm(
                      fontSize: 13,
                      color: AppColors.graphite,
                    ).copyWith(height: 1.45),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
