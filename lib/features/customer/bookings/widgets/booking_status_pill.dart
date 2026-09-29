import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/booking_model.dart';

class BookingStatusPill extends StatelessWidget {
  final BookingStatus status;
  final bool compact;

  const BookingStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _meta(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          color: meta.foreground,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

({String label, Color background, Color foreground}) _meta(
  BookingStatus status,
) {
  switch (status) {
    case BookingStatus.awaiting_deposit:
      return (
        label: 'Chờ đặt cọc',
        background: const Color(0xFFFFEDD5),
        foreground: AppColors.statusOrange,
      );
    case BookingStatus.pending:
      return (
        label: 'Chờ xác nhận',
        background: const Color(0xFFFEF3C7),
        foreground: AppColors.statusAmber,
      );
    case BookingStatus.confirmed:
      return (
        label: 'Chờ thanh toán',
        background: const Color(0xFFDBEAFE),
        foreground: AppColors.statusBlue,
      );
    case BookingStatus.held:
      return (
        label: 'Sàn đang giữ tiền',
        background: const Color(0xFFEDE9FE),
        foreground: AppColors.statusViolet,
      );
    case BookingStatus.released:
      return (
        label: 'Hoàn thành',
        background: const Color(0xFFD1FAE5),
        foreground: AppColors.success,
      );
    case BookingStatus.cancelled:
      return (
        label: 'Đã huỷ',
        background: AppColors.fog,
        foreground: AppColors.steel,
      );
  }
}
