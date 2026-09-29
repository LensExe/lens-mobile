import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

class PhotographerCardCollage extends StatefulWidget {
  final PhotographerModel photographer;
  final VoidCallback onTap;

  const PhotographerCardCollage({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  @override
  State<PhotographerCardCollage> createState() => _PhotographerCardCollageState();
}

class _PhotographerCardCollageState extends State<PhotographerCardCollage> {
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
                // Image Collage Gallery
                SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      // Large Main Left Image
                      Expanded(
                        flex: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
                              // Rating pill overlay
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.photographer.rating} (${widget.photographer.reviewCount})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Favorite Heart Button
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right Stacked Images
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            // Top image
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: images.length > 1 ? images[1] : images[0],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(color: AppColors.mist),
                                  errorWidget: (context, url, error) => Container(color: AppColors.mist),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Bottom image with +14 overlay
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: images.length > 2 ? images[2] : images[0],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: AppColors.mist),
                                      errorWidget: (context, url, error) => Container(color: AppColors.mist),
                                    ),
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.38),
                                      child: const Center(
                                        child: Text(
                                          '+14',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name, Badges & Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE8DE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HẠNG VÀNG',
                                  style: TextStyle(
                                    color: Color(0xFFC2410C),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Giá từ',
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
                  ],
                ),
                const SizedBox(height: 16),

                // Next slot and View Portfolio Action Row
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Lịch gần nhất: Ngày mai,\n14:00',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A00),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5A00).withValues(alpha: 0.38),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Xem\nHồ sơ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 17,
                              color: Colors.white,
                            ),
                          ],
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
