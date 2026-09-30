import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

class BookingStepperHeader extends StatelessWidget {
  final int currentStep; // 0, 1, 2
  final VoidCallback onBack;

  const BookingStepperHeader({
    super.key,
    required this.currentStep,
    required this.onBack,
  });

  String get _stepTitle {
    switch (currentStep) {
      case 0:
        return 'Gói chụp & Lịch trình';
      case 1:
        return 'Liên hệ & Địa điểm';
      case 2:
        return 'Xem lại & Cam kết';
      default:
        return 'Đặt lịch chụp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.snow,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        10,
        AppTokens.pageHorizontal,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.snow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pebble),
                    boxShadow: const [AppTokens.surfaceShadow],
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BƯỚC ${currentStep + 1} / 3',
                    style: AppTypography.numeric(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ember,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stepTitle,
                    style: AppTypography.titleMd(
                      fontSize: 15,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ember : AppColors.fog,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
