import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

class PhotographerCardHero extends StatefulWidget {
  final PhotographerModel photographer;
  final VoidCallback onTap;

  const PhotographerCardHero({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  @override
  State<PhotographerCardHero> createState() => _PhotographerCardHeroState();
}

class _PhotographerCardHeroState extends State<PhotographerCardHero> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final images = PhotographerDisplayHelper.getGalleryImages(widget.photographer);
    final priceStr = PhotographerDisplayHelper.formatPrice(widget.photographer.pricePerSession);
    final subtitle = PhotographerDisplayHelper.getCategorySubtitle(widget.photographer);

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
                // Full-width Hero Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: images[0],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.mist),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.mist,
                            child: const Icon(LucideIcons.imageOff, color: AppColors.steel),
                          ),
                        ),
                        // Top-left Availability Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Có lịch thứ Bảy này',
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Top-right Heart Button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : LucideIcons.heart,
                                color: isFavorite ? const Color(0xFFFF4848) : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left Film & Equipment Tags
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Máy phim 35mm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ánh sáng Studio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFF5A00), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.photographer.rating.toStringAsFixed(2),
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
                const SizedBox(height: 16),

                // Full Session Price & Dual Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trọn gói / buổi',
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
                    // Profile button
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Hồ sơ',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Instant Book button
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A00),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5A00).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Đặt lịch ngay',
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
