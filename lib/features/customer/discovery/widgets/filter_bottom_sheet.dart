import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../models/filter_criteria.dart';

/// Search filters currently supported by GET /photographers.
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  final FilterCriteria initialCriteria;
  final ValueChanged<FilterCriteria> onApply;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const _cities = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Đà Lạt',
    'Cần Thơ',
    'Hải Phòng',
  ];
  late String? _city = widget.initialCriteria.city;
  late double? _minRating = widget.initialCriteria.minRating;

  void _apply() {
    widget.onApply(
      FilterCriteria(
        city: _city,
        minRating: _minRating,
        searchQuery: widget.initialCriteria.searchQuery,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.58,
    minChildSize: 0.42,
    maxChildSize: 0.8,
    expand: false,
    builder: (context, controller) => Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.largeCardRadius),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bộ lọc tìm kiếm',
                    style: AppTypography.headlineSm(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Text('Khu vực', style: AppTypography.titleMd(fontSize: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      'Tất cả',
                      _city == null,
                      () => setState(() => _city = null),
                    ),
                    for (final city in _cities)
                      _chip(
                        city,
                        _city == city,
                        () => setState(() => _city = city),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Đánh giá tối thiểu',
                  style: AppTypography.titleMd(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(
                      'Tất cả',
                      _minRating == null,
                      () => setState(() => _minRating = null),
                    ),
                    _chip(
                      '4.5★ trở lên',
                      _minRating == 4.5,
                      () => setState(() => _minRating = 4.5),
                    ),
                    _chip(
                      '4.8★ trở lên',
                      _minRating == 4.8,
                      () => setState(() => _minRating = 4.8),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Kết quả chỉ lọc theo khu vực, từ khóa và điểm đánh giá mà Backend hỗ trợ.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PrimaryButton(
              text: 'Áp dụng',
              height: AppTokens.primaryButtonHeight,
              onPressed: _apply,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.obsidian,
    labelStyle: TextStyle(
      color: selected ? AppColors.snow : AppColors.obsidian,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    side: BorderSide(color: selected ? AppColors.obsidian : AppColors.pebble),
    backgroundColor: AppColors.snow,
  );
}
