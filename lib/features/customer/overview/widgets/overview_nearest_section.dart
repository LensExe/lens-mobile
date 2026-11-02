import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/widgets/booking_status_pill.dart';

class OverviewNearestSection extends StatelessWidget {
  final Booking? nearest;

  const OverviewNearestSection({super.key, required this.nearest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        14,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
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
              children: [
                const Icon(
                  LucideIcons.calendarClock,
                  size: 16,
                  color: AppColors.ember,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lịch chụp gần nhất',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (nearest == null)
              Text(
                'Bạn chưa có lịch chụp nào sắp tới.',
                style: AppTypography.bodySm(color: AppColors.steel),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    context.push('/customer_home/bookings/${nearest!.id}'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fog,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.pebble.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nearest!.timeSlot ?? '--:--',
                            style: AppTypography.numeric(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.obsidian,
                            ),
                          ),
                          BookingStatusPill(
                            status: nearest!.flowStatus,
                            paymentDue: nearest!.paymentDue,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nearest!.style,
                        style: AppTypography.titleMd(color: AppColors.obsidian),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 13,
                            color: AppColors.steel,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(nearest!.date),
                            style: AppTypography.numeric(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.steel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            LucideIcons.mapPin,
                            size: 13,
                            color: AppColors.steel,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nearest!.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(
                                color: AppColors.steel,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'với nhiếp ảnh gia ${nearest!.photographerName}',
                        style: AppTypography.labelSm(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }
}

