import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';
import 'booking_progress_stepper.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onPrimaryAction;
  final VoidCallback onMessage;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onPrimaryAction,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageHorizontal,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.fog,
                  border: Border(
                    bottom: BorderSide(color: AppColors.pebble, width: 0.8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${booking.displayCode}',
                            style: AppTypography.numeric(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.obsidian,
                            ),
                          ),
                          Text(
                            booking.createdTimeAgo ?? 'Vừa xong',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm(
                              fontSize: 12,
                              color: AppColors.steel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusPill(booking.status),
                  ],
                ),
              ),

              // 2. Card Content Padding
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photographer Row
                    Row(
                      children: [
                        // Avatar with indicator
                        Stack(
                          clipBehavior: Clip.none,
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
                                    ? CachedNetworkImage(
                                        imageUrl: booking.photographerAvatar!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => const Center(
                                          child: Icon(
                                            LucideIcons.camera,
                                            color: AppColors.steel,
                                            size: 20,
                                          ),
                                        ),
                                        errorWidget: (_, _, _) => Center(
                                          child: Text(
                                            booking.photographerName.isNotEmpty
                                                ? booking.photographerName
                                                      .substring(0, 1)
                                                : '?',
                                            style: AppTypography.titleMd(),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          booking.photographerName.isNotEmpty
                                              ? booking.photographerName
                                                    .substring(0, 1)
                                              : '?',
                                          style: AppTypography.titleMd(),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.ember,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.snow,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Name & Rating
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      booking.photographerName,
                                      style: AppTypography.titleMd(
                                        fontSize: 15,
                                        color: AppColors.obsidian,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.fog,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.pebble.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'PRO',
                                      style: AppTypography.numeric(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.steel,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.star,
                                    color: AppColors.ember,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${booking.rating}',
                                    style: AppTypography.numeric(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.obsidian,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${booking.reviewCount} đánh giá)',
                                    style: AppTypography.bodySm(
                                      fontSize: 11.5,
                                      color: AppColors.steel,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Message Button
                        InkWell(
                          onTap: onMessage,
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.fog,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pebble.withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.messageCircle,
                              color: AppColors.obsidian,
                              size: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Session Details Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.pebble.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  booking.style,
                                  style: AppTypography.titleMd(
                                    fontSize: 14,
                                    color: AppColors.obsidian,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (booking.packageSnapshot != null) ...[
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 130,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.ember.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      booking.packageSnapshot!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSm(
                                        fontSize: 11,
                                        color: AppColors.ember,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Time Row
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                size: 13,
                                color: AppColors.steel,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${booking.date}${booking.timeSlot != null ? ' • ${booking.timeSlot}' : ''}',
                                  style: AppTypography.bodySm(
                                    fontSize: 12.5,
                                    color: AppColors.steel,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Location Row
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 13,
                                color: AppColors.steel,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  booking.location,
                                  style: AppTypography.bodySm(
                                    fontSize: 12.5,
                                    color: AppColors.steel,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Progress Stepper
                    BookingProgressStepper(booking: booking),
                    if (booking.status != BookingStatus.cancelled)
                      const SizedBox(height: 14),

                    // 5. Total Package & Escrow Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng gói chụp',
                              style: AppTypography.labelSm(
                                fontSize: 11,
                                color: AppColors.steel,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppTypography.formatCurrency(booking.price),
                              style: AppTypography.priceDisplay(
                                fontSize: 18,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildEscrowBadge(booking),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6. Action Button
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onPrimaryAction,
                            borderRadius: BorderRadius.circular(9999),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.ember,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getPrimaryActionLabel(booking),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd(
                                  fontSize: 13.5,
                                  color: AppColors.snow,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: AppColors.fog,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: AppColors.pebble),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Chi tiết',
                              style: AppTypography.labelMd(
                                fontSize: 13,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(BookingStatus status) {
    Color dotColor;
    Color textColor;
    String label;

    switch (status) {
      case BookingStatus.awaiting_deposit:
        dotColor = AppColors.ember;
        textColor = AppColors.ember;
        label = 'Chờ cọc 30%';
        break;
      case BookingStatus.pending:
        dotColor = AppColors.lagoon;
        textColor = AppColors.lagoon;
        label = 'Chờ xác nhận';
        break;
      case BookingStatus.confirmed:
        dotColor = AppColors.lagoon;
        textColor = AppColors.lagoon;
        label = 'Đã xác nhận';
        break;
      case BookingStatus.held:
        dotColor = AppColors.ember;
        textColor = AppColors.ember;
        label = 'Đang xử lý ảnh';
        break;
      case BookingStatus.released:
        dotColor = AppColors.emerald;
        textColor = AppColors.emerald;
        label = 'Đã hoàn thành';
        break;
      case BookingStatus.cancelled:
        dotColor = AppColors.crimson;
        textColor = AppColors.crimson;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.pebble.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSm(
              fontSize: 11,
              color: textColor,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowBadge(Booking booking) {
    String text;
    Color dotColor = AppColors.ember;

    switch (booking.status) {
      case BookingStatus.held:
        text = '100% Escrow giữ tiền';
        break;
      case BookingStatus.confirmed:
        text = 'Đã cọc 30% • Giữ tiền';
        break;
      case BookingStatus.awaiting_deposit:
        text = 'Chưa nạp Escrow';
        dotColor = AppColors.steel;
        break;
      case BookingStatus.released:
        text = 'Đã giải ngân';
        dotColor = AppColors.emerald;
        break;
      case BookingStatus.cancelled:
        text = 'Đã hoàn tiền';
        dotColor = AppColors.steel;
        break;
      case BookingStatus.pending:
        text = 'Đã giữ cọc 30%';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fog,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelSm(fontSize: 11, color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  String _getPrimaryActionLabel(Booking booking) {
    switch (booking.status) {
      case BookingStatus.held:
        return booking.uploadedProofsCount > 0
            ? 'Duyệt ảnh (${booking.uploadedProofsCount})'
            : 'Theo dõi tiến độ';
      case BookingStatus.awaiting_deposit:
        return 'Đặt cọc 30%';
      case BookingStatus.pending:
        return 'Xem chi tiết lịch hẹn';
      case BookingStatus.confirmed:
        return 'Thanh toán nốt 70%';
      case BookingStatus.released:
        return 'Xem ảnh đã nhận';
      case BookingStatus.cancelled:
        return 'Đặt lịch lại';
    }
  }
}
