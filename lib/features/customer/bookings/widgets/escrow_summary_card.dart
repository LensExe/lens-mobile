import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class EscrowSummaryCard extends StatelessWidget {
  final int totalAmount;
  final int activeShootsCount;
  final VoidCallback? onTap;

  const EscrowSummaryCard({
    super.key,
    required this.totalAmount,
    required this.activeShootsCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ember.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                LucideIcons.shieldCheck,
                color: AppColors.ember,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ESCROW BẢO VỆ',
                      style: AppTypography.labelSm(
                        fontSize: 10.5,
                        color: AppColors.steel,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  AppTypography.formatCurrency(totalAmount),
                  style: AppTypography.priceDisplay(
                    fontSize: 20,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeShootsCount > 0
                      ? '$activeShootsCount buổi chụp đang xử lý & chọn ảnh'
                      : 'Không có buổi chụp nào đang giữ tiền',
                  style: AppTypography.bodySm(
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
          // Trailing action
          if (onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
                ),
                child: const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.steel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
