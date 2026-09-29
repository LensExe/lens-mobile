import 'package:flutter/material.dart';
import '../models/booking_model.dart';

class BookingProgressStepper extends StatelessWidget {
  final Booking booking;

  const BookingProgressStepper({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    if (booking.status == BookingStatus.cancelled) {
      return const SizedBox.shrink();
    }

    // Determine step states (0: Booked, 1: Shot Done, 2: Review Proofs, 3: Sign-off)
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA83900),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: Color(0xFFA83900),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (proofInfo.isNotEmpty)
              Text(
                proofInfo,
                style: const TextStyle(
                  color: Color(0xFF5F5E60),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
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
              segmentColor = const Color(0xFFFF5A00);
            } else if (index == currentStep) {
              segmentColor = const Color(0xFFFF5A00);
            } else {
              segmentColor = const Color(0xFFE8E8E9);
            }

            return Expanded(
              child: Container(
                height: 6,
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
            _buildStepLabel('Đã đặt', isActive: currentStep >= 0, isCurrent: currentStep == 0),
            _buildStepLabel('Đã chụp', isActive: currentStep >= 1, isCurrent: currentStep == 1),
            _buildStepLabel('Duyệt ảnh', isActive: currentStep >= 2, isCurrent: currentStep == 2),
            _buildStepLabel('Nghiệm thu', isActive: currentStep >= 3, isCurrent: currentStep == 3),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLabel(String text, {required bool isActive, required bool isCurrent}) {
    Color textColor;
    FontWeight fontWeight;

    if (isCurrent) {
      textColor = const Color(0xFFA83900);
      fontWeight = FontWeight.w800;
    } else if (isActive) {
      textColor = const Color(0xFF1A1C1D);
      fontWeight = FontWeight.w600;
    } else {
      textColor = const Color(0xFF5F5E60);
      fontWeight = FontWeight.w400;
    }

    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: fontWeight,
      ),
    );
  }
}
