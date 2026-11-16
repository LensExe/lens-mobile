import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';
import 'booking_progress_stepper.dart';
import 'booking_status_pill.dart';

class BookingDetailTimeline extends StatelessWidget {
  final Booking booking;
  const BookingDetailTimeline({super.key, required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến trình thực hiện',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            BookingStatusPill(
              status: booking.flowStatus,
              paymentDue: booking.paymentDue,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        BookingProgressStepper(booking: booking),
      ],
    ),
  );
}

