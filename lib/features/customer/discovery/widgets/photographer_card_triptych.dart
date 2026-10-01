import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

class PhotographerCardTriptych extends StatefulWidget {
  final PhotographerModel photographer;
  final VoidCallback onTap;

  const PhotographerCardTriptych({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  @override
  State<PhotographerCardTriptych> createState() =>
      _PhotographerCardTriptychState();
}

class _PhotographerCardTriptychState extends State<PhotographerCardTriptych> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final images = PhotographerDisplayHelper.getGalleryImages(
      widget.photographer,
    );
    final priceStr = PhotographerDisplayHelper.formatPrice(
      widget.photographer.pricePerSession,
    );
    final subtitle = PhotographerDisplayHelper.getCategorySubtitle(
      widget.photographer,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Vertical Photo Strips Side-by-side
                SizedBox(
                  height: 185,
                  child: Row(
                    children: [
                      // Strip 1
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: images[0],
                            fit: BoxFit.cover,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                Container(color: AppColors.mist),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.mist),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Strip 2
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: images.length > 1 ? images[1] : images[0],
                            fit: BoxFit.cover,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                Container(color: AppColors.mist),
                            errorWidget: (context, url, error) =>
                                Container(color: AppColors.mist),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Strip 3 with Favorite Heart Overlay
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: images.length > 2
                                    ? images[2]
                                    : images[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.mist),
                                errorWidget: (context, url, error) =>
                                    Container(color: AppColors.mist),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFavorite = !isFavorite;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : LucideIcons.heart,
                                      color: isFavorite
                                          ? const Color(0xFFFF4848)
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Rating Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.photographer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFFFF5A00),
                      size: 18,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFF5A00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.photographer.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Tags: Fast Delivery & Gear Specs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.zap,
                              color: Color(0xFFFF5A00),
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Giao ảnh 48h',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              color: Color(0xFF6B7280),
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Sony A7R V + Tilt-Shift',
                              style: TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Project Rate & Check Schedule Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giá theo dự án',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 21,
                            color: Color(0xFF09090B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B), // Black / Obsidian
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Xem lịch chụp',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
