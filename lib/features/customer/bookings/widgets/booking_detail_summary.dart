import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';

class BookingDetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const BookingDetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.steel),
      const SizedBox(width: 10),
      SizedBox(
        width: 78,
        child: Text(
          label,
          style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: AppTypography.titleMd(fontSize: 13, color: AppColors.obsidian),
        ),
      ),
    ],
  );
}

class BookingDetailSummary extends StatelessWidget {
  final Booking booking;
  const BookingDetailSummary({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 48,
                height: 48,
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
                              _initials(booking.photographerName),
                              style: AppTypography.titleMd(),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(booking.photographerName),
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
                      style: AppTypography.titleMd(
                        fontSize: 16,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nhiếp ảnh gia chuyên nghiệp',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => context.push(
                      '/customer_home/messages/${booking.photographerId}',
                    ),
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
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.pebble, height: 1),
          ),
          BookingDetailInfoRow(
            icon: LucideIcons.calendarDays,
            label: 'Thời gian',
            value:
                '${_dateLabel(booking.date)}${booking.timeSlot == null ? '' : ' · ${booking.timeSlot}'}',
          ),
          const SizedBox(height: 12),
          BookingDetailInfoRow(
            icon: LucideIcons.mapPin,
            label: 'Địa điểm',
            value: booking.location,
          ),
          const SizedBox(height: 12),
          BookingDetailInfoRow(
            icon: LucideIcons.camera,
            label: 'Gói chụp',
            value: booking.packageSnapshot?.name ?? booking.style,
          ),
          if (booking.note != null && booking.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            BookingDetailInfoRow(
              icon: LucideIcons.stickyNote,
              label: 'Ghi chú',
              value: booking.note!,
            ),
          ],
        ],
      ),
    );
  }

  static String _dateLabel(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  static String _initials(String value) => value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.substring(0, 1))
      .join()
      .toUpperCase();
}

