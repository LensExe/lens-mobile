import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

enum OverviewFilter { all, payment, pending, completed }

class OverviewFilterTabs extends StatelessWidget {
  final OverviewFilter selectedFilter;
  final ValueChanged<OverviewFilter> onFilterSelected;

  const OverviewFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (OverviewFilter.all, 'Tất cả'),
      (OverviewFilter.payment, 'Cần thanh toán'),
      (OverviewFilter.pending, 'Chờ duyệt'),
      (OverviewFilter.completed, 'Đã hoàn tất'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        14,
        AppTokens.pageHorizontal,
        6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            final isSelected = selectedFilter == item.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onFilterSelected(item.$1),
                borderRadius: BorderRadius.circular(9999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: AppTokens.filterChipHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.obsidian : AppColors.fog,
                    borderRadius: BorderRadius.circular(9999),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppColors.pebble.withValues(alpha: 0.5),
                          ),
                  ),
                  child: Text(
                    item.$2,
                    style: AppTypography.labelMd(
                      color: isSelected ? AppColors.snow : AppColors.steel,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

