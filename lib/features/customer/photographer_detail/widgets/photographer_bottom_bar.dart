import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../models/photographer_detail_model.dart';

class PhotographerBottomBar extends StatelessWidget {
  final ProfilePackage? selectedPackage;
  final int startingPrice;
  final VoidCallback onMessage;
  final VoidCallback onBook;

  const PhotographerBottomBar({
    super.key,
    required this.selectedPackage,
    required this.startingPrice,
    required this.onMessage,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice =
        selectedPackage != null ? selectedPackage!.price : startingPrice;
    final priceLabel = selectedPackage != null ? 'Gói đã chọn' : 'Giá chỉ từ';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: Color(0xD9FFFFFF), // rgba(255, 255, 255, 0.85)
            border: Border(
              top: BorderSide(color: AppColors.pebble, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              // Price info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(priceLabel, style: AppTypography.labelSm()),
                    const SizedBox(height: 2),
                    Text(
                      AppTypography.formatCurrency(displayPrice),
                      style: AppTypography.priceDisplay(fontSize: 19),
                    ),
                  ],
                ),
              ),

              // Message Icon Button (44x44 circular target)
              GestureDetector(
                onTap: onMessage,
                child: Container(
                  width: AppTokens.iconButtonSize,
                  height: AppTokens.iconButtonSize,
                  decoration: BoxDecoration(
                    color: AppColors.fog,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pebble, width: 1.0),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.messageCircle,
                      color: AppColors.obsidian,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Book Now Button (Height 52px, Pill-shaped with scale feedback)
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'Đặt lịch ngay',
                  height: AppTokens.primaryButtonHeight, // 52px
                  onPressed: onBook,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
