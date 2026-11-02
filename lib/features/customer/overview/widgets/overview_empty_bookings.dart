import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import 'overview_filter_tabs.dart';

class OverviewEmptyBookings extends StatelessWidget {
  final OverviewFilter filter;

  const OverviewEmptyBookings({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        12,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarDays,
                size: 24,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              filter == OverviewFilter.completed
                  ? 'Chưa có buổi chụp hoàn thành'
                  : 'Chưa có buổi chụp phù hợp',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 6),
            Text(
              'Khám phá nhiếp ảnh gia hàng đầu và đặt lịch chụp cho bạn.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Tìm nhiếp ảnh gia',
              expand: false,
              onPressed: () => context.go('/customer_home/discovery'),
            ),
          ],
        ),
      ),
    );
  }
}

