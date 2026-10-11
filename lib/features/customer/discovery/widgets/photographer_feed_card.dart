import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_container.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_display_helper.dart';

/// A portfolio-led discovery tile with a compact gallery presentation.
class PhotographerFeedCard extends StatefulWidget {
  final PhotographerModel photographer;
  final int index;
  final bool compact;
  final VoidCallback onTap;

  const PhotographerFeedCard({
    super.key,
    required this.photographer,
    required this.index,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<PhotographerFeedCard> createState() => _PhotographerFeedCardState();
}

class _PhotographerFeedCardState extends State<PhotographerFeedCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final photographer = widget.photographer;
    final cardRadius = widget.compact ? 17.0 : AppTokens.largeCardRadius;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: true,
      label: 'Mở hồ sơ ${photographer.name}, ${photographer.city}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(photographer, cardRadius),
              if (widget.compact)
                _buildCompactCaption(photographer)
              else
                _buildLeadCaption(photographer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(PhotographerModel photographer, double radius) {
    final style = photographer.styles.isEmpty
        ? null
        : photographer.styles.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: AppColors.fog,
        child: AspectRatio(
          aspectRatio: widget.compact ? 1.12 : 1.24,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photographer.coverImageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: photographer.coverImageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 280),
                  placeholder: (context, url) => const ColoredBox(
                    color: AppColors.fog,
                    child: Center(
                      child: Icon(
                        LucideIcons.aperture,
                        color: AppColors.ash,
                        size: 24,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: AppColors.fog,
                    child: Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        color: AppColors.steel,
                        size: 26,
                      ),
                    ),
                  ),
                )
              else
                const ColoredBox(
                  color: AppColors.fog,
                  child: Center(
                    child: Icon(
                      LucideIcons.image,
                      color: AppColors.ash,
                      size: 28,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.compact
                        ? const [Color(0x26000000), Colors.transparent]
                        : const [
                            Color(0x2A000000),
                            Colors.transparent,
                            Color(0x1A000000),
                            Color(0xD9000000),
                          ],
                    stops: widget.compact
                        ? const [0, .42]
                        : const [0, .25, .54, 1],
                  ),
                ),
              ),
              if (photographer.isFeatured)
                Positioned(
                  top: 11,
                  left: 11,
                  child: GlassContainer.mediaBadge(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    child: Text(
                      'Nổi bật',
                      style: AppTypography.labelSm(
                        color: AppColors.snow,
                        fontSize: 10,
                      ),
                    ),
                  ),
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
                      size: 38,
                      isDark: true,
                      child: Icon(
                        _isSaved ? Icons.favorite : LucideIcons.heart,
                        color: _isSaved ? AppColors.ember : AppColors.snow,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.compact)
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
                          fontSize: 23,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            photographer.city,
                            style: AppTypography.bodySm(
                              color: AppColors.snow.withValues(alpha: .94),
                            ),
                          ),
                          if (style != null) ...[
                            _dot,
                            Text(
                              style,
                              style: AppTypography.bodySm(
                                color: AppColors.snow.withValues(alpha: .94),
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
                                color: AppColors.snow.withValues(alpha: .94),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (photographer.reviewCount > 0) ...[
                        const SizedBox(height: 8),
                        _RatingLine(
                          rating: photographer.rating,
                          reviewCount: photographer.reviewCount,
                          light: true,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCaption(PhotographerModel photographer) {
    final style = photographer.styles.isEmpty
        ? null
        : photographer.styles.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  photographer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd(
                    fontSize: 14,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
              if (photographer.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.badgeCheck,
                  size: 15,
                  color: AppColors.emerald,
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            style == null ? photographer.city : '${photographer.city} · $style',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm(color: AppColors.steel)
                .copyWith(fontSize: 11.5),
          ),
          if (photographer.reviewCount > 0) ...[
            const SizedBox(height: 5),
            _RatingLine(
              rating: photographer.rating,
              reviewCount: photographer.reviewCount,
            ),
          ],
          const SizedBox(height: 5),
          if (photographer.pricePerSession > 0)
            Row(
              children: [
                Text(
                  'Từ ',
                  style: AppTypography.bodySm(color: AppColors.steel)
                      .copyWith(fontSize: 11),
                ),
                Expanded(
                  child: Text(
                    PhotographerDisplayHelper.formatPrice(
                      photographer.pricePerSession,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.priceDisplay(
                      fontSize: 14,
                      color: AppColors.obsidian,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.arrowUpRight,
                  size: 15,
                  color: AppColors.steel,
                ),
              ],
            )
          else
            Text(
              'Xem gói chụp',
              style: AppTypography.labelMd(color: AppColors.steel),
            ),
        ],
      ),
    );
  }

  Widget _buildLeadCaption(PhotographerModel photographer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 11, 3, 0),
      child: Row(
        children: [
          Expanded(
            child: photographer.pricePerSession > 0
                ? Text(
                    'Từ ${PhotographerDisplayHelper.formatPrice(photographer.pricePerSession)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.priceDisplay(fontSize: 19),
                  )
                : Text(
                    'Xem gói chụp',
                    style: AppTypography.labelMd(color: AppColors.steel),
                  ),
          ),
          Text(
            'Mở hồ sơ',
            style: AppTypography.labelMd(color: AppColors.steel),
          ),
          const SizedBox(width: 5),
          const Icon(
            LucideIcons.arrowUpRight,
            size: 16,
            color: AppColors.steel,
          ),
        ],
      ),
    );
  }

  static const Widget _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: Icon(Icons.circle, size: 3, color: AppColors.snow),
  );
}

class _RatingLine extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool light;

  const _RatingLine({
    required this.rating,
    required this.reviewCount,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? AppColors.snow : AppColors.steel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.star,
          size: 13,
          color: light ? AppColors.snow : AppColors.ember,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.numeric(
            color: textColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySm(
            color: textColor.withValues(alpha: light ? .88 : 1),
          ).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
