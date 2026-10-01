import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';

class BookingProgressStepper extends StatelessWidget {
  final Booking booking;

  const BookingProgressStepper({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.cancelled) {
      return const SizedBox.shrink();
    }

    int currentStep = 0;
    String statusTitle = 'Đang chờ xử lý';
    String proofInfo = '';

    switch (booking.status) {
      case BookingStatus.awaiting_deposit:
        currentStep = 0;
        statusTitle = 'Chờ thanh toán cọc 30%';
        proofInfo = 'Hạn trong 30 phút';
        break;
      case BookingStatus.pending:
        currentStep = 0;
        statusTitle = 'Đã cọc • Chờ NAG xác nhận';
        proofInfo = 'Đang chờ phản hồi';
        break;
      case BookingStatus.confirmed:
        currentStep = 1;
        statusTitle = 'Đã xác nhận lịch chụp';
        proofInfo = 'Chuẩn bị buổi chụp';
        break;
      case BookingStatus.held:
        currentStep = 2;
        statusTitle = 'Chọn ảnh nghiệm thu (65%)';
        proofInfo = booking.uploadedProofsCount > 0
            ? '${booking.uploadedProofsCount} ảnh đã tải lên'
            : 'Đang tải ảnh lên';
        break;
      case BookingStatus.released:
        currentStep = 3;
        statusTitle = 'Đã nghiệm thu & nhận ảnh';
        proofInfo = 'Đã hoàn tất 100%';
        break;
      case BookingStatus.cancelled:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper Status Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.ember,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd(
                      fontSize: 11.5,
                      color: AppColors.ember,
                    ),
                  ),
                ),
              ],
            ),
            if (proofInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 12),
                child: Text(
                  proofInfo,
                  style: AppTypography.bodySm(
                    fontSize: 11.5,
                    color: AppColors.steel,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // 4-Segment Progress Bar
        Row(
          children: List.generate(4, (index) {
            Color segmentColor;
            if (index < currentStep) {
              segmentColor = AppColors.emerald;
            } else if (index == currentStep) {
              segmentColor = AppColors.ember;
            } else {
              segmentColor = AppColors.mist;
            }

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0),
                decoration: BoxDecoration(
                  color: segmentColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),

        // 4 Steps Label Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildStepLabel(
                'Đã đặt',
                isActive: currentStep >= 0,
                isCurrent: currentStep == 0,
              ),
            ),
            Expanded(
              child: _buildStepLabel(
                'Đã chụp',
                isActive: currentStep >= 1,
                isCurrent: currentStep == 1,
              ),
            ),
            Expanded(
              child: _buildStepLabel(
                'Duyệt ảnh',
                isActive: currentStep >= 2,
                isCurrent: currentStep == 2,
              ),
            ),
            Expanded(
              child: _buildStepLabel(
                'Nghiệm thu',
                isActive: currentStep >= 3,
                isCurrent: currentStep == 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLabel(
    String text, {
    required bool isActive,
    required bool isCurrent,
  }) {
    Color textColor;
    FontWeight fontWeight;

    if (isCurrent) {
      textColor = AppColors.ember;
      fontWeight = FontWeight.w700;
    } else if (isActive) {
      textColor = AppColors.obsidian;
      fontWeight = FontWeight.w600;
    } else {
      textColor = AppColors.steel;
      fontWeight = FontWeight.w400;
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTypography.labelSm(
        fontSize: 11,
        color: textColor,
      ).copyWith(fontWeight: fontWeight),
    );
  }
}
