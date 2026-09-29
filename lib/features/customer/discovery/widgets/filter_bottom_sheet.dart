import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
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
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  final List<String> _cities = ['Tất cả', 'Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Đà Lạt', 'Cần Thơ', 'Hải Phòng'];
  
  // Rating logic
  // 'Tất cả' -> null, '4.5★ trở lên' -> 4.5, '4.8★ trở lên' -> 4.8
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bộ lọc tìm kiếm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
                      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.pebble),
                
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // City
                      _buildSectionTitle('Thành phố'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cities.map((city) {
                          final isSelected = (_criteria.city ?? 'Tất cả') == city;
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
                      // Phong cách chụp
                      _buildSectionTitle('Phong cách chụp'),
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
                                final currentStyles = List<String>.from(_criteria.styles);
                                if (isSelected) {
                                  currentStyles.remove(style);
                                } else {
                                  currentStyles.add(style);
                                }
                                _criteria = _criteria.copyWith(styles: currentStyles);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      
                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Mức giá / buổi'),
                          Text(
                            _formatPriceRange(_criteria.minPrice ?? 50000, _criteria.maxPrice ?? 400000),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ember, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: RangeValues(_criteria.minPrice ?? 50000, _criteria.maxPrice ?? 400000),
                        min: 50000,
                        max: 400000,
                        divisions: (400000 - 50000) ~/ 25000,
                        activeColor: AppColors.ember,
                        inactiveColor: AppColors.pebble,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _criteria = _criteria.copyWith(
                              minPrice: values.start,
                              maxPrice: values.end,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Date
                      _buildSectionTitle('Ngày rảnh'),
                      GestureDetector(
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
                            setState(() => _criteria = _criteria.copyWith(availableDate: date));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.snow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.pebble),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, color: AppColors.ember, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _criteria.availableDate == null ? 'Chọn ngày rảnh...' : DateFormat('dd/MM/yyyy').format(_criteria.availableDate!),
                                  style: TextStyle(
                                    color: _criteria.availableDate == null ? AppColors.steel : AppColors.obsidian,
                                    fontWeight: _criteria.availableDate == null ? FontWeight.normal : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (_criteria.availableDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _criteria = _criteria.copyWith(clearDate: true)),
                                  child: const Icon(LucideIcons.xCircle, color: AppColors.steel, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Rating
                      _buildSectionTitle('Đánh giá tối thiểu'),
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
                      const SizedBox(height: 32),
                      
                      // Experience
                      _buildSectionTitle('Kinh nghiệm'),
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.snow,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.pebble),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          onPressed: _reset,
                          child: const Text('Thiết lập lại', style: TextStyle(color: AppColors.obsidian, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ember,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          onPressed: _apply,
                          child: const Text('Áp dụng bộ lọc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian, fontSize: 15)),
    );
  }

  Widget _buildChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ember.withValues(alpha: 0.1) : AppColors.snow,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? AppColors.ember : AppColors.pebble),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.ember : AppColors.obsidian,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatPriceRange(double min, double max) {
    if (max >= 400000) {
      return '${currencyFormat.format(min)} - 400.000+ ₫';
    }
    return '${currencyFormat.format(min)} - ${currencyFormat.format(max)}';
  }
}
