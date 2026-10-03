import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

/// An image-led discovery tile. Details remain secondary to the photographer's
/// own cover image and are drawn only from the discovery model.
class PhotographerFeedCard extends StatefulWidget {
  final PhotographerModel photographer;
  final int index;
  final VoidCallback onTap;

  const PhotographerFeedCard({
    super.key,
    required this.photographer,
    required this.index,
    required this.onTap,
  });

  @override
  State<PhotographerFeedCard> createState() => _PhotographerFeedCardState();
}

class _PhotographerFeedCardState extends State<PhotographerFeedCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final photographer = widget.photographer;
    final style = photographer.styles.isEmpty
        ? null
        : photographer.styles.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
          child: Material(
            color: AppColors.fog,
            child: InkWell(
              onTap: widget.onTap,
              child: AspectRatio(
                aspectRatio: 1.18,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photographer.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ColoredBox(color: AppColors.fog),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          LucideIcons.imageOff,
                          color: AppColors.steel,
                          size: 28,
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Colors.transparent,
                            Color(0xAA000000),
                            Color(0xD9000000),
                          ],
                          stops: [0, .28, .68, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: photographer.isFeatured
                          ? GlassContainer.mediaBadge(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                'Nổi bật',
                                style: AppTypography.labelSm(
                                  color: AppColors.snow,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        button: true,
                        label: _isSaved
                            ? 'Bỏ lưu nhiếp ảnh gia'
                            : 'Lưu nhiếp ảnh gia',
                        child: GestureDetector(
                          onTap: () => setState(() => _isSaved = !_isSaved),
                          child: GlassContainer.floatingControl(
                            size: AppTokens.iconButtonSize,
                            isDark: true,
                            child: Icon(
                              _isSaved ? Icons.favorite : LucideIcons.heart,
                              color: _isSaved
                                  ? AppColors.ember
                                  : AppColors.snow,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 17,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photographer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineMd(
                              color: AppColors.snow,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 7,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                photographer.city,
                                style: AppTypography.bodySm(
                                  color: AppColors.snow.withValues(alpha: .92),
                                ),
                              ),
                              if (style != null) ...[
                                _dot,
                                Text(
                                  style,
                                  style: AppTypography.bodySm(
                                    color: AppColors.snow.withValues(
                                      alpha: .92,
                                    ),
                                  ),
                                ),
                              ],
                              if (photographer.isVerified) ...[
                                _dot,
                                const Icon(
                                  LucideIcons.badgeCheck,
                                  size: 14,
                                  color: AppColors.snow,
                                ),
                                Text(
                                  'Đã xác minh',
                                  style: AppTypography.bodySm(
                                    color: AppColors.snow.withValues(
                                      alpha: .92,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (photographer.reviewCount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: AppColors.snow,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  photographer.rating.toStringAsFixed(1),
                                  style: AppTypography.numeric(
                                    color: AppColors.snow,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '(${photographer.reviewCount} đánh giá)',
                                  style: AppTypography.bodySm(
                                    color: AppColors.snow.withValues(
                                      alpha: .88,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Từ ', style: AppTypography.bodySm(color: AppColors.steel)),
            Expanded(
              child: Text(
                PhotographerDisplayHelper.formatPrice(
                  photographer.pricePerSession,
                ),
                style: AppTypography.priceDisplay(fontSize: 18),
              ),
            ),
            Text(
              'Mở hồ sơ',
              style: AppTypography.labelMd(color: AppColors.steel),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.arrowUpRight,
              size: 16,
              color: AppColors.steel,
            ),
          ],
        ),
      ],
    );
  }

  static const Widget _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: Icon(Icons.circle, size: 3, color: AppColors.snow),
  );
}
