import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFFF3F3F4)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${booking.displayCode}',
                          style: const TextStyle(
                            color: Color(0xFF1A1C1D),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5F5E60),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.createdTimeAgo ?? 'Vừa xong',
                          style: const TextStyle(
                            color: Color(0xFF5F5E60),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEEEEEF),
                              backgroundImage: booking.photographerAvatar != null
                                  ? CachedNetworkImageProvider(booking.photographerAvatar!)
                                  : null,
                              child: booking.photographerAvatar == null
                                  ? const Icon(LucideIcons.camera, color: Color(0xFF5F5E60), size: 22)
                                  : null,
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5A00),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
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
                                      style: const TextStyle(
                                        color: Color(0xFF1A1C1D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8E8E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'PRO',
                                      style: TextStyle(
                                        color: Color(0xFF5B4137),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFF5A00), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${booking.rating}',
                                    style: const TextStyle(
                                      color: Color(0xFF1A1C1D),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${booking.reviewCount} đánh giá)',
                                    style: const TextStyle(
                                      color: Color(0xFF5F5E60),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Message Button
                        GestureDetector(
                          onTap: onMessage,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F3F4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.messageCircle,
                              color: Color(0xFF1A1C1D),
                              size: 18,
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
                        color: const Color(0xFFF3F3F4),
                        borderRadius: BorderRadius.circular(16),
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
                                  style: const TextStyle(
                                    color: Color(0xFF1A1C1D),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (booking.packageSnapshot != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDBCF),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    booking.packageSnapshot!.name,
                                    style: const TextStyle(
                                      color: Color(0xFF380D00),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
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
                              const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF5F5E60)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${booking.date}${booking.timeSlot != null ? ' • ${booking.timeSlot}' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xFF5F5E60),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
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
                              const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF5F5E60)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  booking.location,
                                  style: const TextStyle(
                                    color: Color(0xFF5F5E60),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng gói chụp',
                              style: TextStyle(
                                color: Color(0xFF5F5E60),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormat.format(booking.price),
                              style: const TextStyle(
                                color: Color(0xFF1A1C1D),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        _buildEscrowBadge(booking),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6. Action Button
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onPrimaryAction,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5A00),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5A00).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getPrimaryActionLabel(booking),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F4),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Chi tiết',
                              style: TextStyle(
                                color: Color(0xFF1A1C1D),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
        dotColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
        label = 'Chờ đặt cọc 30%';
        break;
      case BookingStatus.pending:
        dotColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
        label = 'Chờ xác nhận';
        break;
      case BookingStatus.confirmed:
        dotColor = const Color(0xFF3B82F6);
        textColor = const Color(0xFF1D4ED8);
        label = 'Đã xác nhận';
        break;
      case BookingStatus.held:
        dotColor = const Color(0xFFFF5A00);
        textColor = const Color(0xFFA83900);
        label = 'Đang xử lý & duyệt ảnh';
        break;
      case BookingStatus.released:
        dotColor = const Color(0xFF10B981);
        textColor = const Color(0xFF047857);
        label = 'Đã hoàn thành';
        break;
      case BookingStatus.cancelled:
        dotColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFB91C1C);
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscrowBadge(Booking booking) {
    String text;
    Color dotColor = const Color(0xFFFF5A00);

    switch (booking.status) {
      case BookingStatus.held:
        text = '100% Escrow giữ tiền';
        break;
      case BookingStatus.confirmed:
        text = 'Đã cọc 30% • Giữ tiền';
        break;
      case BookingStatus.awaiting_deposit:
        text = 'Chưa nạp Escrow';
        dotColor = const Color(0xFF9CA3AF);
        break;
      case BookingStatus.released:
        text = 'Đã giải ngân cho thợ';
        dotColor = const Color(0xFF10B981);
        break;
      case BookingStatus.cancelled:
        text = 'Đã hoàn tiền (nếu có)';
        dotColor = const Color(0xFF9CA3AF);
        break;
      case BookingStatus.pending:
        text = 'Đã giữ cọc 30%';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEF),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5F5E60),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
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
