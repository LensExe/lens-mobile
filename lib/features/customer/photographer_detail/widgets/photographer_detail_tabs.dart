import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/photographer_detail_model.dart';

class PhotographerDetailTabs extends StatelessWidget {
  final PhotographerProfile profile;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const PhotographerDetailTabs({
    super.key,
    required this.profile,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'Tác phẩm (${profile.portfolio.length})',
      'Giới thiệu & Gói',
      'Đánh giá (${profile.reviewCount})',
    ];

    return SizedBox(
      height: AppTokens.filterChipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          final title = tabs[index];

          return InkWell(
            onTap: () => onTabSelected(index),
            borderRadius: BorderRadius.circular(9999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.obsidian : AppColors.fog,
                borderRadius: BorderRadius.circular(9999),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
              ),
              child: Text(
                title,
                style: AppTypography.labelMd(
                  color: isSelected ? AppColors.snow : AppColors.steel,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
