import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/widgets/booking_status_pill.dart';

class OverviewBookingCard extends StatelessWidget {
  final Booking booking;

  const OverviewBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final end = booking.timeSlot == null || booking.packageSnapshot == null
        ? null
        : _addMinutes(
            booking.timeSlot!,
            booking.packageSnapshot!.durationHours * 60,
          );

    final isAwaitingDeposit =
        booking.flowStatus == BookingStatus.awaiting_deposit;

    return Container(
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  color: AppColors.fog,
                ),
                child: ClipOval(
                  child:
                      booking.photographerAvatar != null &&
                          booking.photographerAvatar!.isNotEmpty
                      ? Image.network(
                          booking.photographerAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              booking.photographerName.isNotEmpty
                                  ? booking.photographerName.substring(0, 1)
                                  : '?',
                              style: AppTypography.titleMd(),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            booking.photographerName.isNotEmpty
                                ? booking.photographerName.substring(0, 1)
                                : '?',
                            style: AppTypography.titleMd(),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.photographerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd(
                        fontSize: 15,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.style,
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusPill(
                status: booking.flowStatus,
                paymentDue: booking.paymentDue,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.pebble.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendarDays,
                      size: 14,
                      color: AppColors.steel,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_dateLabel(booking.date)}${booking.timeSlot == null ? '' : ' · ${booking.timeSlot}${end == null ? '' : '–$end'}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.numeric(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: AppColors.steel,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm(
                          fontSize: 12,
                          color: AppColors.steel,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (booking.status != BookingStatus.cancelled) ...[
            const SizedBox(height: 14),
            BookingProgress(status: booking.status),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng chi phí',
                    style: AppTypography.labelSm(
                      fontSize: 10,
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    AppTypography.formatCurrency(booking.price),
                    style: AppTypography.priceDisplay(
                      fontSize: 15,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isAwaitingDeposit)
                FilledButton(
                  onPressed: () => GoRouter.of(context)
                      .push('/customer_home/bookings/${booking.id}/deposit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ember,
                    foregroundColor: AppColors.snow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Đặt cọc ngay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () =>
                      GoRouter.of(context)
                          .push('/customer_home/bookings/${booking.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.obsidian,
                    side: const BorderSide(color: AppColors.pebble),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết',
                        style: AppTypography.labelMd(
                          fontSize: 12,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppColors.steel,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateLabel(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  static String _addMinutes(String value, double minutes) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final date = DateTime(
      2000,
      1,
      1,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    ).add(Duration(minutes: minutes.round()));
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class BookingProgress extends StatelessWidget {
  final BookingStatus status;
  const BookingProgress({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final active = switch (status) {
      BookingStatus.awaiting_deposit => 0,
      BookingStatus.pending => 1,
      BookingStatus.confirmed => 2,
      BookingStatus.held => 3,
      BookingStatus.released => 4,
      BookingStatus.cancelled => 0,
      BookingStatus.accepted => 2,
      BookingStatus.inProgress => 3,
      BookingStatus.shot => 4,
      BookingStatus.completed => 4,
      BookingStatus.rejected => 0,
      BookingStatus.expired => 0,
    };
    const labels = ['Đặt cọc', 'Xác nhận', 'Thanh toán', 'Hoàn tất'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < active
                        ? AppColors.emerald
                        : i == active
                        ? AppColors.ember
                        : AppColors.fog,
                    border: Border.all(
                      color: i <= active
                          ? Colors.transparent
                          : AppColors.pebble,
                      width: 1,
                    ),
                  ),
                  child: i < active
                      ? const Icon(
                          LucideIcons.check,
                          size: 13,
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: i == active ? Colors.white : AppColors.steel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: i <= active ? AppColors.obsidian : AppColors.steel,
                    fontWeight: i <= active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: i < active ? AppColors.emerald : AppColors.pebble,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class OverviewLoadingCards extends StatelessWidget {
  const OverviewLoadingCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        12,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 142,
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                border: Border.all(color: AppColors.pebble),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

