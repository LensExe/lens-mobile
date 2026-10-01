import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../models/photographer_detail_model.dart';

class PackagesTabView extends StatelessWidget {
  final List<ProfilePackage> packages;
  final ProfilePackage? selectedPackage;
  final Function(ProfilePackage) onSelectPackage;
  final Function(ProfilePackage) onBookPackage;

  const PackagesTabView({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.onBookPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Gói chụp đề xuất',
              style: AppTypography.headlineSm(
                fontSize: 18,
                color: AppColors.obsidian,
              ),
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 14,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bảo hiểm Escrow',
                  style: AppTypography.labelSm(
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Packages List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: packages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final pkg = packages[index];
            final isChosen = selectedPackage?.id == pkg.id;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(20),
                border: isChosen
                    ? Border.all(color: AppColors.ember, width: 2)
                    : Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge (if most selected or featured)
                  if (pkg.highlightBadge.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: pkg.isMostSelected
                                ? AppColors.ember
                                : AppColors.ember.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            pkg.highlightBadge,
                            style: AppTypography.labelSm(
                              fontSize: 11,
                              color: pkg.isMostSelected
                                  ? Colors.white
                                  : AppColors.ember,
                            ).copyWith(fontWeight: FontWeight.w700),
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
                            pkg.duration,
                            style: AppTypography.numeric(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Title & Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.name,
                              style: AppTypography.titleMd(
                                fontSize: 17,
                                color: AppColors.obsidian,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pkg.subtitle,
                              style: AppTypography.bodySm(
                                fontSize: 12.5,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppTypography.formatCurrency(pkg.price),
                            style: AppTypography.priceDisplay(
                              fontSize: 18,
                              color: AppColors.obsidian,
                            ),
                          ),
                          if (pkg.highlightBadge.isEmpty)
                            Text(
                              pkg.duration,
                              style: AppTypography.numeric(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.steel,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Deliverables Checklist
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fog,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.pebble.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pkg.deliverables.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.check,
                                size: 14,
                                color: AppColors.emerald,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTypography.bodySm(
                                    fontSize: 12.5,
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
                  const SizedBox(height: 16),

                  // Action Button
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            onSelectPackage(pkg);
                            onBookPackage(pkg);
                          },
                          borderRadius: BorderRadius.circular(9999),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: pkg.isMostSelected
                                  ? AppColors.ember
                                  : AppColors.obsidian,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              pkg.isMostSelected
                                  ? 'Chọn gói này & Đặt lịch'
                                  : 'Đặt gói này',
                              style: AppTypography.labelMd(
                                fontSize: 14,
                                color: AppColors.snow,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
