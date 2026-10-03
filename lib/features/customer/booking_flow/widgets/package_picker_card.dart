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
    final selectionLabel = package.highlightBadge.isNotEmpty
        ? package.highlightBadge
        : package.isMostSelected
        ? 'Được chọn nhiều nhất'
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.ember.withValues(alpha: .035)
                  : AppColors.snow,
              borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
              border: Border.all(
                color: isSelected ? AppColors.ember : AppColors.pebble,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ember : AppColors.snow,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.ember
                              : AppColors.pebble,
                          width: 1.3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              LucideIcons.check,
                              size: 13,
                              color: AppColors.snow,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.name,
                            style: AppTypography.titleMd(fontSize: 16),
                          ),
                          if (package.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              package.subtitle,
                              style: AppTypography.bodySm(
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                          if (selectionLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              selectionLabel,
                              style: AppTypography.labelSm(
                                color: AppColors.ember,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          AppTypography.formatCurrency(package.price),
                          style: AppTypography.priceDisplay(
                            fontSize: 20,
                            color: AppColors.obsidian,
                          ),
                        ),
                      ),
                      Text(
                        package.duration,
                        style: AppTypography.labelSm(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 7, right: 9),
                                decoration: const BoxDecoration(
                                  color: AppColors.ash,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTypography.bodySm(
                                    color: AppColors.graphite,
                                  ),
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
        ),
      ),
    );
  }
}
