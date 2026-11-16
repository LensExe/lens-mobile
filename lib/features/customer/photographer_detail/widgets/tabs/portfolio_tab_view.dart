import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../models/photographer_detail_model.dart';

class PortfolioTabView extends StatelessWidget {
  final List<String> styles;
  final String selectedStyle;
  final List<PortfolioItem> items;
  final Function(String) onStyleSelected;
  final Function(PortfolioItem)? onItemTap;

  const PortfolioTabView({
    super.key,
    required this.styles,
    required this.selectedStyle,
    required this.items,
    required this.onStyleSelected,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final featuredItem = items.firstWhere(
      (item) => item.isFeatured,
      orElse: () => items.isNotEmpty
          ? items.first
          : const PortfolioItem(
              id: 'empty',
              imageUrl: '',
              title: '',
              style: '',
              subtitle: '',
              cameraGear: '',
            ),
    );

    final regularItems = items
        .where((item) => item.id != featuredItem.id)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Style Filter Pills
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: styles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final style = styles[index];
                final isSelected = style == selectedStyle;

                return GestureDetector(
                  onTap: () => onStyleSelected(style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.obsidian : AppColors.fog,
                      borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    ),
                    child: Center(
                      child: Text(
                        style,
                        style: AppTypography.labelSm(
                          color: isSelected ? AppColors.snow : AppColors.steel,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 2. Featured Hero Photo Card (if available)
          if (featuredItem.imageUrl.isNotEmpty) ...[
            _buildFeaturedCard(context, featuredItem),
            const SizedBox(height: 14),
          ],

          // 3. Grid of Portfolio Photos
          if (regularItems.isEmpty && featuredItem.imageUrl.isEmpty)
            _buildEmptyPortfolio()
          else
            _buildPortfolioGrid(context, regularItems),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, PortfolioItem item) {
    return GestureDetector(
      onTap: () => onItemTap?.call(item),
      child: Container(
        height: (MediaQuery.sizeOf(context).width * .88)
            .clamp(300.0, 390.0)
            .toDouble(),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: const Color(0xFFE8E8E9)),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFE8E8E9),
                child: const Icon(LucideIcons.image, color: Color(0xFF5F5E60)),
              ),
            ),
            // Bottom Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x331A1C1D),
                    Color(0xE61A1C1D),
                  ],
                  stops: [0.4, 0.7, 1.0],
                ),
              ),
            ),
            // Content Info Overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.style.isNotEmpty) ...[
                    Text(
                      item.style.toUpperCase(),
                      style: AppTypography.labelSm(color: AppColors.snow),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm(color: AppColors.snow),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm(
                        color: AppColors.snow.withValues(alpha: .88),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid(BuildContext context, List<PortfolioItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onItemTap?.call(item),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: const Color(0xFFE8E8E9)),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFE8E8E9),
                    child: const Icon(
                      LucideIcons.image,
                      color: Color(0xFF5F5E60),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x331A1C1D),
                        Color(0xD91A1C1D),
                      ],
                      stops: [0.5, 0.75, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.style.isNotEmpty ? item.style : item.subtitle,
                        style: AppTypography.bodySm(
                          color: AppColors.snow.withValues(alpha: .88),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyPortfolio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(LucideIcons.imageOff, size: 36, color: Color(0xFF5F5E60)),
          SizedBox(height: 12),
          Text(
            'Chưa có ảnh trong phong cách này',
            style: TextStyle(color: Color(0xFF5F5E60), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
