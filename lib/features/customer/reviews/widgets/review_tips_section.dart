import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class ReviewTips extends StatelessWidget {
  const ReviewTips({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.star, size: 16, color: AppColors.ember),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tiêu chí đánh giá chất lượng tại Lens',
                style: AppTypography.titleMd(
                  fontSize: 14,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Đánh giá công tâm giúp cộng đồng chọn được nhiếp ảnh gia ưng ý nhất.',
          style: AppTypography.bodySm(color: AppColors.steel, fontSize: 12),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: ReviewTipItem(
                icon: LucideIcons.clock3,
                title: 'Đúng giờ',
                color: AppColors.ember,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ReviewTipItem(
                icon: LucideIcons.handshake,
                title: 'Tận tâm',
                color: AppColors.lagoon,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ReviewTipItem(
                icon: LucideIcons.image,
                title: 'Chất lượng',
                color: AppColors.emerald,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ReviewTipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const ReviewTipItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTypography.labelMd(fontSize: 12, color: AppColors.obsidian),
        ),
      ],
    ),
  );
}

class ReviewEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const ReviewEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: AppColors.fog,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.star, size: 24, color: AppColors.steel),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
      ],
    ),
  );
}

class ReviewSkeleton extends StatelessWidget {
  const ReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
    ),
  );
}

