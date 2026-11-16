import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

enum ReviewTab { pending, completed }

class ReviewTabs extends StatelessWidget {
  final ReviewTab selected;
  final int pendingCount;
  final int completedCount;
  final ValueChanged<ReviewTab> onChanged;

  const ReviewTabs({
    super.key,
    required this.selected,
    required this.pendingCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ReviewTabPill(
            label: 'Chờ đánh giá',
            count: pendingCount,
            selected: selected == ReviewTab.pending,
            onTap: () => onChanged(ReviewTab.pending),
          ),
          const SizedBox(width: 8),
          ReviewTabPill(
            label: 'Đã gửi phiên này',
            count: completedCount,
            selected: selected == ReviewTab.completed,
            onTap: () => onChanged(ReviewTab.completed),
          ),
        ],
      ),
    );
  }
}

class ReviewTabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const ReviewTabPill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: AppTokens.filterChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.obsidian : AppColors.fog,
          borderRadius: BorderRadius.circular(9999),
          border: selected
              ? null
              : Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMd(
                color: selected ? AppColors.snow : AppColors.steel,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ember : AppColors.mist,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: AppTypography.numeric(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.steel,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

