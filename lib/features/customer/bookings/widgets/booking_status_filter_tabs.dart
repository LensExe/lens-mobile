import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class BookingStatusFilterTabs extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabSelected;
  final int Function(String) countProvider;

  const BookingStatusFilterTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.countProvider,
  });

  static const List<String> tabs = [
    'Tất cả',
    'Chờ đặt cọc',
    'Chờ xác nhận',
    'Chờ thanh toán',
    'Sàn đang giữ tiền',
    'Hoàn thành',
    'Đã huỷ',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.filterChipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pageHorizontal,
        ),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = (tab == selectedTab);
          final count = countProvider(tab);

          return InkWell(
            onTap: () => onTabSelected(tab),
            borderRadius: BorderRadius.circular(9999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab,
                    style: AppTypography.labelMd(
                      color: isSelected ? AppColors.snow : AppColors.steel,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ember : AppColors.mist,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: AppTypography.numeric(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.steel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
