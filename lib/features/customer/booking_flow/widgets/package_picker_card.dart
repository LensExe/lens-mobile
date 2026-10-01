import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../photographer_detail/models/photographer_detail_model.dart';

class PackagePickerCard extends StatelessWidget {
  final ProfilePackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const PackagePickerCard({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular =
        package.isMostSelected ||
        package.highlightBadge.contains('Phổ biến') ||
        package.highlightBadge.contains('nhiều nhất') ||
        package.name.contains('Editorial');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.ember : AppColors.pebble,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.ember.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [AppTokens.surfaceShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Radio icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.ember : AppColors.fog,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.pebble,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                size: 13,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                right: isPopular ? 80 : 0,
                              ),
                              child: Text(
                                package.name,
                                style: AppTypography.titleMd(
                                  fontSize: 16,
                                  color: AppColors.obsidian,
                                ),
                              ),
                            ),
                            if (package.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                package.subtitle,
                                style: AppTypography.bodySm(
                                  fontSize: 12,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price & Duration
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppTypography.formatCurrency(package.price),
                          style: AppTypography.priceDisplay(
                            fontSize: 19,
                            color: AppColors.ember,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fog,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: AppColors.pebble.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            package.duration,
                            style: AppTypography.numeric(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Deliverables list
                  if (package.deliverables.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: package.deliverables.take(4).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.check,
                                  size: 13,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: AppTypography.bodySm(
                                      fontSize: 12,
                                      color: AppColors.graphite,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Top-right "PHỔ BIẾN" badge
            if (isPopular)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.ember,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'PHỔ BIẾN',
                    style: AppTypography.labelSm(
                      fontSize: 10,
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
