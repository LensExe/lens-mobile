import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bookings/models/booking_model.dart';
import '../models/customer_review_model.dart';

class PendingReviewRow extends StatelessWidget {
  final Booking booking;
  final VoidCallback onReview;

  const PendingReviewRow({
    super.key,
    required this.booking,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Row(
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMd(
                  fontSize: 14.5,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${booking.style} · ${_dateLabel(booking.date)}',
                style: AppTypography.bodySm(
                  color: AppColors.steel,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(
                  color: AppColors.steel,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.ember,
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
              'Viết đánh giá',
              style: AppTypography.labelMd(fontSize: 12, color: AppColors.snow),
            ),
          ),
        ),
      ],
    ),
  );

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

class CompletedReviewCard extends StatelessWidget {
  final SubmittedCustomerReview review;
  final VoidCallback onTap;

  const CompletedReviewCard({
    super.key,
    required this.review,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pebble),
                    color: AppColors.fog,
                  ),
                  child: ClipOval(
                    child: review.photographerAvatar.isNotEmpty
                        ? Image.network(
                            review.photographerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                _initials(review.photographerName),
                                style: AppTypography.titleMd(fontSize: 12),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _initials(review.photographerName),
                              style: AppTypography.titleMd(fontSize: 12),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.photographerName,
                        style: AppTypography.titleMd(
                          fontSize: 13.5,
                          color: AppColors.obsidian,
                        ),
                      ),
                      Text(
                        '${review.style} · ${_dateLabel(review.date)}',
                        style: AppTypography.bodySm(
                          fontSize: 11,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTypography.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(
                fontSize: 12.5,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}',
                  style: AppTypography.bodySm(
                    fontSize: 11,
                    color: AppColors.steel,
                  ),
                ),
                Text(
                  'Xem chi tiết',
                  style: AppTypography.labelSm(
                    fontSize: 11,
                    color: AppColors.ember,
                  ),
                ),
              ],
            ),
          ],
        ),
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

