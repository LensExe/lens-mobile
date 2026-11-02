import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bookings/models/booking_model.dart';

class MetricData {
  final String label;
  final int value;
  const MetricData(this.label, this.value);
}

class OverviewMetricsRow extends StatelessWidget {
  final List<Booking> bookings;
  final List<Booking> needsPayment;
  final List<Booking> pending;
  final List<Booking> completed;

  const OverviewMetricsRow({
    super.key,
    required this.bookings,
    required this.needsPayment,
    required this.pending,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      MetricData('Buổi chụp', bookings.length),
      MetricData('Cần thanh toán', needsPayment.length),
      MetricData('Chờ xác nhận', pending.length),
      MetricData('Hoàn thành', completed.length),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        20,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${metrics[index].value}',
                    style: AppTypography.numeric(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    metrics[index].label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm(color: AppColors.steel),
                  ),
                ],
              ),
            ),
            if (index < metrics.length - 1)
              Container(
                width: 1,
                height: 30,
                color: AppColors.pebble,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ],
      ),
    );
  }
}

