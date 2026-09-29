import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lens_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class Review {
  final String id;
  final String photographerId;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.id,
    required this.photographerId,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class ReviewItemWidget extends StatelessWidget {
  final Review review;
  final bool showDivider;

  const ReviewItemWidget({super.key, required this.review, this.showDivider = true});

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.fog,
              backgroundImage: review.authorAvatar.isNotEmpty
                  ? CachedNetworkImageProvider(review.authorAvatar)
                  : null,
              child: review.authorAvatar.isEmpty
                  ? Text(
                      review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.obsidian),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name and Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          review.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.obsidian),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review.date),
                        style: const TextStyle(color: AppColors.steel, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 2: Stars
                  Row(
                    children: List.generate(5, (index) {
                      if (index < review.rating.floor()) {
                        return const Icon(LucideIcons.star, color: AppColors.ember, size: 16);
                      } else if (index < review.rating && review.rating % 1 != 0) {
                        return const Icon(LucideIcons.starHalf, color: AppColors.ember, size: 16);
                      } else {
                        return const Icon(LucideIcons.star, color: AppColors.pebble, size: 16);
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Row 3: Comment
                  Text(
                    review.comment,
                    style: TextStyle(
                      color: AppColors.obsidian.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.mist, height: 1, thickness: 1),
          ),
        if (!showDivider)
          const SizedBox(height: 16),
      ],
    );
  }
}
