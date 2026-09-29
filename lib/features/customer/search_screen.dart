import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/data_providers.dart';
import '../../core/widgets/photographer_card.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _city = 'Tất cả';
  final List<String> _cities = ['Tất cả', 'Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Đà Lạt'];
  
  double _minPrice = 0;
  double _maxPrice = 10000000;
  
  String _rating = 'Tất cả';
  final List<String> _ratings = ['Tất cả', 'Từ 4.5 sao', 'Từ 4.0 sao'];
  
  DateTime? _selectedDate;

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
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bộ lọc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.obsidian)),
                      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // City
                        const Text('Thành phố', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _cities.map((city) {
                            final isSelected = _city == city;
                            return GestureDetector(
                              onTap: () => setState(() => _city = city),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.obsidian : AppColors.snow,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: isSelected ? AppColors.obsidian : AppColors.pebble),
                                ),
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.obsidian,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        
                        // Price
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
                            Text('${(_minPrice/1000000).toStringAsFixed(1)}Tr - ${(_maxPrice/1000000).toStringAsFixed(1)}Tr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ember)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 20000000,
                          divisions: 20,
                          activeColor: AppColors.obsidian,
                          inactiveColor: AppColors.pebble,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _minPrice = values.start;
                              _maxPrice = values.end;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Date
                        const Text('Ngày rảnh', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.snow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.pebble),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, color: AppColors.steel, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null ? 'Chọn ngày...' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(color: _selectedDate == null ? AppColors.steel : AppColors.obsidian, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Rating
                        const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.obsidian)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ratings.map((rating) {
                            final isSelected = _rating == rating;
                            return GestureDetector(
                              onTap: () => setState(() => _rating = rating),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.obsidian : AppColors.snow,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: isSelected ? AppColors.obsidian : AppColors.pebble),
                                ),
                                child: Text(
                                  rating,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.obsidian,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.pebble),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          onPressed: () {
                            setState(() {
                              _city = 'Tất cả';
                              _minPrice = 0;
                              _maxPrice = 10000000;
                              _selectedDate = null;
                              _rating = 'Tất cả';
                            });
                          },
                          child: const Text('Xóa lọc', style: TextStyle(color: AppColors.obsidian, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.obsidian,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _selectedSort = 'Đề xuất';
  final List<String> _sortOptions = ['Đề xuất', 'Giá thấp nhất', 'Giá cao nhất', 'Đánh giá cao'];
  
  String _selectedStyle = '';
  final List<String> _styles = ['Tất cả', 'Chân dung', 'Sự kiện', 'Cưới hỏi', 'Thời trang', 'Kỷ yếu'];

  @override
  Widget build(BuildContext context) {
    final photographers = ref.watch(photographersProvider);
    
    // Filter and Sort mock logic
    var results = photographers.where((p) {
      if (_selectedStyle.isNotEmpty && _selectedStyle != 'Tất cả') {
        return p.styles.contains(_selectedStyle);
      }
      return true;
    }).toList();
    
    if (_selectedSort == 'Giá thấp nhất') {
      results.sort((a, b) => a.pricePerSession.compareTo(b.pricePerSession));
    } else if (_selectedSort == 'Giá cao nhất') {
      results.sort((a, b) => b.pricePerSession.compareTo(a.pricePerSession));
    } else if (_selectedSort == 'Đánh giá cao') {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.mist,
            pinned: true,
            title: const Text('Khám phá', style: TextStyle(color: AppColors.obsidian, fontSize: 18, fontWeight: FontWeight.bold)),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.mist,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.snow,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.pebble),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(LucideIcons.search, color: AppColors.steel, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm tên, địa điểm, phong cách...',
                            hintStyle: TextStyle(color: AppColors.steel, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.mist,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tìm nhiếp ảnh gia của bạn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.obsidian, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text('Chọn người kể câu chuyện của bạn qua từng khung hình.', style: TextStyle(color: AppColors.steel, height: 1.5, fontSize: 15)),
                  const SizedBox(height: 20),
                  
                  // 3-step guide
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStep(1, 'Chọn phong cách'),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.steel),
                        const SizedBox(width: 12),
                        _buildStep(2, 'So sánh hồ sơ'),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.steel),
                        const SizedBox(width: 12),
                        _buildStep(3, 'Đặt lịch'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: AppColors.mist,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Nút Lọc
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const FilterBottomSheet(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.snow,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.pebble),
                          ),
                          child: const Icon(LucideIcons.slidersHorizontal, color: AppColors.obsidian, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dropdown Sort
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.snow,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.pebble),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.arrowDownUp, size: 14, color: AppColors.obsidian),
                            const SizedBox(width: 6),
                            DropdownButton<String>(
                              value: _selectedSort,
                              underline: const SizedBox(),
                              icon: const Icon(LucideIcons.chevronDown, size: 16),
                              style: const TextStyle(color: AppColors.obsidian, fontSize: 13, fontWeight: FontWeight.w600),
                              isDense: true,
                              items: _sortOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedSort = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dropdown Style
                      ..._styles.map((style) {
                        final isSelected = _selectedStyle == style || (_selectedStyle.isEmpty && style == 'Tất cả');
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStyle = style == 'Tất cả' ? '' : style),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.obsidian : AppColors.snow,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: isSelected ? AppColors.obsidian : AppColors.pebble),
                            ),
                            child: Text(
                              style,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.obsidian,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(bottom: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PhotographerCard(
                      photographer: results[index],
                      onTap: () => context.go('/customer_home/photographer/${results[index].id}'),
                    ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.1, end: 0),
                  );
                },
                childCount: results.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.obsidian,
            shape: BoxShape.circle,
          ),
          child: Text(number.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.steel, fontSize: 13)),
      ],
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
