import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../models/filter_criteria.dart';

/// Customer discovery filters. Some criteria are applied locally because the
/// photographer list endpoint does not expose dedicated query parameters.
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
  static const _styleOptions = [
    'Chân dung',
    'Cưới',
    'Sự kiện',
    'Thời trang',
    'Sản phẩm',
    'Gia đình',
    'Du lịch',
    'Ẩm thực',
    'Kiến trúc',
    'Đường phố',
  ];
  static const _cities = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Đà Lạt',
    'Cần Thơ',
    'Hải Phòng',
  ];
  late final Set<String> _selectedStyles = {...widget.initialCriteria.styles};
  late String? _city = widget.initialCriteria.city;
  late double? _minRating = widget.initialCriteria.minRating;
  late RangeValues _priceRange = RangeValues(
    widget.initialCriteria.priceMin,
    widget.initialCriteria.priceMax,
  );
  late String? _experienceBucket = widget.initialCriteria.experienceBucket;

  void _apply() {
    widget.onApply(
      FilterCriteria(
        city: _city,
        minRating: _minRating,
        searchQuery: widget.initialCriteria.searchQuery,
        styles: _selectedStyles.toList(),
        priceMin: _priceRange.start,
        priceMax: _priceRange.end,
        experienceBucket: _experienceBucket,
        sort: widget.initialCriteria.sort,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.70,
    minChildSize: 0.45,
    maxChildSize: 0.92,
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
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedStyles.clear();
                      _city = null;
                      _minRating = null;
                      _priceRange = const RangeValues(
                        FilterCriteria.defaultPriceMin,
                        FilterCriteria.defaultPriceMax,
                      );
                      _experienceBucket = null;
                    }),
                    child: const Text('Xoá lọc'),
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
                Text(
                  'Phong cách chụp',
                  style: AppTypography.titleMd(fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Tất cả', _selectedStyles.isEmpty, () {
                      setState(_selectedStyles.clear);
                    }),
                    for (final style in _styleOptions)
                      _multiChip(
                        style,
                        _selectedStyles.contains(style),
                        () => setState(() {
                          if (!_selectedStyles.add(style)) {
                            _selectedStyles.remove(style);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
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
                  'Mức giá / buổi',
                  style: AppTypography.titleMd(fontSize: 15),
                ),
                const SizedBox(height: 5),
                RangeSlider(
                  min: FilterCriteria.defaultPriceMin,
                  max: FilterCriteria.defaultPriceMax,
                  divisions: 118,
                  values: _priceRange,
                  labels: RangeLabels(
                    _formatPrice(_priceRange.start),
                    _priceRange.end >= FilterCriteria.defaultPriceMax
                        ? '${_formatPrice(FilterCriteria.defaultPriceMax)}+'
                        : _formatPrice(_priceRange.end),
                  ),
                  onChanged: (value) => setState(() => _priceRange = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatPrice(_priceRange.start),
                      style: AppTypography.bodySm(color: AppColors.steel),
                    ),
                    Text(
                      _priceRange.end >= FilterCriteria.defaultPriceMax
                          ? '${_formatPrice(FilterCriteria.defaultPriceMax)}+'
                          : _formatPrice(_priceRange.end),
                      style: AppTypography.bodySm(color: AppColors.steel),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Kinh nghiệm', style: AppTypography.titleMd(fontSize: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Tất cả', _experienceBucket == null, () {
                      setState(() => _experienceBucket = null);
                    }),
                    for (final option in _experienceOptions)
                      _chip(
                        option.$2,
                        _experienceBucket == option.$1,
                        () => setState(
                          () => _experienceBucket =
                              _experienceBucket == option.$1 ? null : option.$1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Kết quả được lọc theo phong cách, khu vực, ngân sách, đánh giá và kinh nghiệm.',
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

  Widget _multiChip(String label, bool selected, VoidCallback onTap) =>
      FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.obsidian,
        labelStyle: TextStyle(
          color: selected ? AppColors.snow : AppColors.obsidian,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: selected ? AppColors.obsidian : AppColors.pebble,
        ),
        backgroundColor: AppColors.snow,
        checkmarkColor: AppColors.snow,
      );

  bool get _hasActiveFilters =>
      _selectedStyles.isNotEmpty ||
      _city != null ||
      _minRating != null ||
      _experienceBucket != null ||
      _priceRange.start > FilterCriteria.defaultPriceMin ||
      _priceRange.end < FilterCriteria.defaultPriceMax;
}

const _experienceOptions = [
  ('lt1', 'Dưới 1 năm'),
  ('1-3', '1 – 3 năm'),
  ('3-5', '3 – 5 năm'),
  ('5+', 'Trên 5 năm'),
];

String _formatPrice(double value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  return '$grouped ₫';
}
