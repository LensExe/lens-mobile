import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../models/photographer_model.dart';

class PhotographerMasonryCard extends StatelessWidget {
  final PhotographerModel photographer;
  final VoidCallback onTap;

  const PhotographerMasonryCard({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pebble),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges and Heart
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4, // Tỷ lệ dọc nghệ thuật
                  child: CachedNetworkImage(
                    imageUrl: photographer.coverImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.mist),
                    errorWidget: (context, url, error) => Container(color: AppColors.mist, child: const Icon(LucideIcons.imageOff)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.heart, color: Colors.white, size: 18),
                  ),
                ),
                if (photographer.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.ember,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('NỔI BẬT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(photographer.avatarUrl),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          photographer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.obsidian),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (photographer.isVerified)
                        const Icon(LucideIcons.badgeCheck, color: Colors.blue, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${photographer.rating} (${photographer.reviewCount})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.obsidian),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.mapPin, color: AppColors.steel, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          photographer.city,
                          style: const TextStyle(fontSize: 12, color: AppColors.steel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: photographer.styles.take(2).map((style) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(style, style: const TextStyle(fontSize: 10, color: AppColors.steel)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.pebble),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormat.format(photographer.pricePerSession)} / buổi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.obsidian),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
