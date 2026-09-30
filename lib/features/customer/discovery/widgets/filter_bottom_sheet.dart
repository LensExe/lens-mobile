import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import '../models/photo_style_options.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final FilterCriteria initialCriteria;
  final Function(FilterCriteria) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late FilterCriteria _criteria;

  static const double _minPriceLimit = 500000;
  static const double _maxPriceLimit = 5000000;

  final List<String> _cities = [
    'Tất cả',
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Đà Lạt',
    'Cần Thơ',
    'Hải Phòng',
  ];

  final List<double?> _ratingValues = [null, 4.5, 4.8];
  final List<String> _ratingLabels = ['Tất cả', '4.5★ trở lên', '4.8★ trở lên'];

  final Map<Experience?, String> _experienceLabels = {
    null: 'Tất cả',
    Experience.under1Year: 'Dưới 1 năm',
    Experience.from1To3Years: '1 - 3 năm',
    Experience.from3To5Years: '3 - 5 năm',
    Experience.over5Years: 'Trên 5 năm',
  };

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria.copyWith();
  }

  void _reset() {
    setState(() {
      _criteria = FilterCriteria();
    });
  }

  void _apply() {
    widget.onApply(_criteria);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.snow,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTokens.largeCardRadius),
            ),
            boxShadow: [AppTokens.modalShadow],
          ),
          child: Column(
            children: [
              // Modal Header with Drag Handle
              _buildHeader(),

              // Filter Content Scrollable View
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Section 1: Thành phố
                    _buildSectionHeader('Thành phố', LucideIcons.mapPin),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cities.map((city) {
                        final isSelected =
                            (_criteria.city ?? 'Tất cả') == city;
                        return _buildChip(
                          label: city,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _criteria = _criteria.copyWith(
                                city: city == 'Tất cả' ? null : city,
                                clearCity: city == 'Tất cả',
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Phong cách chụp
                    _buildSectionHeader('Phong cách chụp', LucideIcons.palette),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PhotoStyleOptions.all.map((style) {
                        final isSelected = _criteria.styles.contains(style);
                        return _buildChip(
                          label: style,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              final currentStyles =
                                  List<String>.from(_criteria.styles);
                              if (isSelected) {
                                currentStyles.remove(style);
                              } else {
                                currentStyles.add(style);
                              }
                              _criteria =
                                  _criteria.copyWith(styles: currentStyles);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Section 3: Mức giá / buổi
                    _buildPriceSection(),

                    const SizedBox(height: 24),

                    // Section 4: Ngày rảnh
                    _buildSectionHeader('Ngày chụp', LucideIcons.calendarDays),
                    _buildDatePicker(),

                    const SizedBox(height: 24),

                    // Section 5: Đánh giá tối thiểu
                    _buildSectionHeader(
                      'Đánh giá tối thiểu',
                      LucideIcons.star,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_ratingValues.length, (index) {
                        final val = _ratingValues[index];
                        final label = _ratingLabels[index];
                        final isSelected = _criteria.minRating == val;
                        return _buildChip(
                          label: label,
                          isSelected: isSelected,
                          leadingIcon: val != null ? LucideIcons.star : null,
                          onTap: () {
                            setState(() {
                              _criteria = _criteria.copyWith(
                                minRating: val,
                                clearRating: val == null,
                              );
                            });
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Section 6: Kinh nghiệm
                    _buildSectionHeader('Kinh nghiệm', LucideIcons.award),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _experienceLabels.entries.map((entry) {
                        final isSelected = _criteria.experience == entry.key;
                        return _buildChip(
                          label: entry.value,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _criteria = _criteria.copyWith(
                                experience: entry.key,
                                clearExperience: entry.key == null,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Sticky Bottom Action Bar
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag Handle
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

        // Header Title and Close Action
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
          child: Row(
            children: [
              Text(
                'Bộ lọc tìm kiếm',
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
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.obsidian),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.titleMd(
              color: AppColors.obsidian,
              fontSize: 15,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    final currentMin = _criteria.minPrice ?? _minPriceLimit;
    final currentMax = _criteria.maxPrice ?? _maxPriceLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.circleDollarSign,
                  size: 16,
                  color: AppColors.obsidian,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mức giá / buổi',
                  style: AppTypography.titleMd(
                    color: AppColors.obsidian,
                    fontSize: 15,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ember.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTokens.pillRadius),
              ),
              child: Text(
                _formatPriceRange(currentMin, currentMax),
                style: AppTypography.numeric(
                  color: AppColors.ember,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.ember,
            inactiveTrackColor: AppColors.fog,
            thumbColor: AppColors.snow,
            overlayColor: AppColors.ember.withValues(alpha: 0.12),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 2,
            ),
          ),
          child: RangeSlider(
            values: RangeValues(currentMin, currentMax),
            min: _minPriceLimit,
            max: _maxPriceLimit,
            divisions: ((_maxPriceLimit - _minPriceLimit) / 250000).round(),
            onChanged: (RangeValues values) {
              setState(() {
                _criteria = _criteria.copyWith(
                  minPrice: values.start == _minPriceLimit &&
                          values.end == _maxPriceLimit
                      ? null
                      : values.start,
                  maxPrice: values.start == _minPriceLimit &&
                          values.end == _maxPriceLimit
                      ? null
                      : values.end,
                );
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '500.000 ₫',
                style: AppTypography.labelSm(color: AppColors.steel),
              ),
              Text(
                '5.000.000+ ₫',
                style: AppTypography.labelSm(color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final hasDate = _criteria.availableDate != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _criteria.availableDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.ember,
                    onPrimary: Colors.white,
                    onSurface: AppColors.obsidian,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            setState(
              () => _criteria = _criteria.copyWith(availableDate: date),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: hasDate
                ? AppColors.ember.withValues(alpha: 0.04)
                : AppColors.snow,
            borderRadius: BorderRadius.circular(AppTokens.inputFieldRadius),
            border: Border.all(
              color: hasDate ? AppColors.ember : AppColors.pebble,
              width: hasDate ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasDate
                      ? AppColors.ember.withValues(alpha: 0.12)
                      : AppColors.fog,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: hasDate ? AppColors.ember : AppColors.steel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasDate
                      ? DateFormat(
                          'dd/MM/yyyy',
                        ).format(_criteria.availableDate!)
                      : 'Chọn ngày bạn muốn chụp...',
                  style: AppTypography.bodyMd(
                    color: hasDate ? AppColors.obsidian : AppColors.steel,
                  ).copyWith(
                    fontWeight:
                        hasDate ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (hasDate)
                InkWell(
                  onTap: () => setState(
                    () => _criteria = _criteria.copyWith(clearDate: true),
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      LucideIcons.xCircle,
                      color: AppColors.steel,
                      size: 18,
                    ),
                  ),
                )
              else
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.steel,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? leadingIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.obsidian : AppColors.snow,
        borderRadius: BorderRadius.circular(AppTokens.pillRadius),
        border: Border.all(
          color: isSelected ? AppColors.obsidian : AppColors.pebble,
          width: 1.0,
        ),
        boxShadow: isSelected ? null : const [AppTokens.surfaceShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.pillRadius),
          child: Container(
            height: AppTokens.filterChipHeight,
            padding: EdgeInsets.symmetric(
              horizontal: leadingIcon != null ? 12 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 13,
                    color: isSelected ? AppColors.warning : AppColors.steel,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppTypography.labelMd(
                    color: isSelected ? AppColors.snow : AppColors.graphite,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasFilter = _criteria.city != null ||
        _criteria.minPrice != null ||
        _criteria.maxPrice != null ||
        _criteria.styles.isNotEmpty ||
        _criteria.availableDate != null ||
        _criteria.minRating != null ||
        _criteria.experience != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.snow,
        border: Border(
          top: BorderSide(color: AppColors.pebble, width: 1),
        ),
        boxShadow: [AppTokens.modalShadow],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: AppTokens.primaryButtonHeight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.obsidian,
                    side: const BorderSide(color: AppColors.pebble),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                    ),
                  ),
                  onPressed: hasFilter ? _reset : null,
                  child: Text(
                    'Thiết lập lại',
                    style: AppTypography.labelMd(
                      color: hasFilter ? AppColors.obsidian : AppColors.ash,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: PrimaryButton(
                text: 'Áp dụng bộ lọc',
                height: AppTokens.primaryButtonHeight,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPriceRange(double min, double max) {
    final formattedMin = AppTypography.formatCurrency(min);
    if (max >= _maxPriceLimit) {
      return '$formattedMin – 5.000.000+ ₫';
    }
    final formattedMax = AppTypography.formatCurrency(max);
    return '$formattedMin – $formattedMax';
  }
}


