import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';

class BookingDetailGalleryPanel extends StatelessWidget {
  final Booking booking;
  const BookingDetailGalleryPanel({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final delivered = booking.uploadedProofsCount;
    final previews = booking.deliveryPhotoUrls.take(4).toList();
    final total = booking.packageSnapshot?.photoCount ?? previews.length;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.image,
                    size: 18,
                    color: AppColors.ember,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ sưu tập bàn giao',
                    style: AppTypography.titleMd(color: AppColors.obsidian),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.pebble.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '$delivered / $total ảnh',
                  style: AppTypography.numeric(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4-preview grid
          if (previews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nhiếp ảnh gia chưa giao ảnh cho lịch này.'),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previews.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: previews[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.fog),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.fog,
                      child: const Icon(
                        LucideIcons.image,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/gallery'),
            icon: const Icon(LucideIcons.externalLink, size: 15),
            label: Text(
              'Mở toàn bộ bộ sưu tập & nghiệm thu',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pebble),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

