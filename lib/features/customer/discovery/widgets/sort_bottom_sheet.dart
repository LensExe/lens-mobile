import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../models/filter_criteria.dart';

class SortBottomSheet extends StatefulWidget {
  final SortOption initialSort;
  final ValueChanged<SortOption> onApply;

  const SortBottomSheet({
    super.key,
    required this.initialSort,
    required this.onApply,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late SortOption _selectedOption;

  static const List<({SortOption option, String label})> _sortOptions = [
    (option: SortOption.featured, label: 'Nổi bật'),
    (option: SortOption.rating, label: 'Đánh giá cao'),
    (option: SortOption.priceAsc, label: 'Giá thấp đến cao'),
    (option: SortOption.priceDesc, label: 'Giá cao đến thấp'),
    (option: SortOption.reviewCount, label: 'Nhiều đánh giá nhất'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialSort;
  }

  void _handleApply() {
    widget.onApply(_selectedOption);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.largeCardRadius),
        ),
        boxShadow: [AppTokens.modalShadow],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Indicator
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.pebble,
                  borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                ),
              ),
            ),

            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
              child: Row(
                children: [
                  Text(
                    'Sắp xếp theo',
                    style: AppTypography.headlineSm(fontSize: 18),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.fog,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppColors.pebble),

            // Options List
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: _sortOptions.map((item) {
                  final isSelected = item.option == _selectedOption;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedOption = item.option;
                          });
                        },
                        borderRadius: BorderRadius.circular(
                          AppTokens.cardRadius,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.ember.withValues(alpha: 0.04)
                                : AppColors.snow,
                            borderRadius: BorderRadius.circular(
                              AppTokens.cardRadius,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.ember
                                  : AppColors.pebble,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? const [AppTokens.surfaceShadow]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.label,
                                  style:
                                      AppTypography.bodyMd(
                                        color: isSelected
                                            ? AppColors.obsidian
                                            : AppColors.obsidian,
                                      ).copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                              // Custom Radio Indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.ember
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.ember
                                        : AppColors.ash,
                                    width: isSelected ? 2.0 : 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          LucideIcons.check,
                                          size: 13,
                                          color: AppColors.snow,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                text: 'Áp dụng',
                height: AppTokens.primaryButtonHeight,
                onPressed: _handleApply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
