import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';
import 'booking_status_pill.dart';

class BookingDetailHeading extends StatelessWidget {
  final Booking booking;
  const BookingDetailHeading({super.key, required this.booking});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Buổi chụp #${booking.displayCode}',
        style: AppTypography.headlineSm(
          fontSize: 20,
          color: AppColors.obsidian,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${_dateLabel(booking.date)} · Mã đặt: ${booking.id}',
        style: AppTypography.bodySm(color: AppColors.steel),
      ),
      const SizedBox(height: 8),
      BookingStatusPill(
        status: booking.flowStatus,
        paymentDue: booking.paymentDue,
      ),
    ],
  );

  static String _dateLabel(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }
}

