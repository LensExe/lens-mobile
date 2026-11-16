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
        return 'Gói chụp & lịch trình';
      case 1:
        return 'Liên hệ & địa điểm';
      case 2:
        return 'Xem lại & cam kết';
      default:
        return 'Đặt lịch chụp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepNumber = currentStep + 1;
    return Container(
      color: AppColors.canvas,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        8,
        AppTokens.pageHorizontal,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: AppColors.snow,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pebble),
                    ),
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      size: 19,
                      color: AppColors.obsidian,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ĐẶT LỊCH · BƯỚC $stepNumber',
                      style: AppTypography.labelSm(
                        color: AppColors.steel,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _stepTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSm(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${stepNumber.toString().padLeft(2, '0')} / 03',
                style: AppTypography.numeric(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.pillRadius),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: stepNumber / 3,
              backgroundColor: AppColors.fog,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ember),
            ),
          ),
        ],
      ),
    );
  }
}
