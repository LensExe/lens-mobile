import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  size: 20,
                  color: AppColors.obsidian,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bước ${currentStep + 1} / 3',
                style: const TextStyle(
                  color: AppColors.ember,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                _stepTitle,
                style: const TextStyle(
                  color: Color(0xFF5F5E60),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ember : const Color(0xFFE8E8E9),
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
