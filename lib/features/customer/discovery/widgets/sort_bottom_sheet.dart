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
        color: AppColors.canvas,
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Column(
                children: _sortOptions.map((item) {
                  final isSelected = item.option == _selectedOption;

                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedOption = item.option),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.snow
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style:
                                        AppTypography.bodyMd(
                                          color: AppColors.obsidian,
                                        ).copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 21,
                                  height: 21,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.obsidian
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.obsidian
                                          : AppColors.ash,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            LucideIcons.check,
                                            size: 12,
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
                      if (item != _sortOptions.last)
                        const Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: AppColors.pebble,
                        ),
                    ],
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
