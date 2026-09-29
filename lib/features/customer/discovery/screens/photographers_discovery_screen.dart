import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../core/theme/app_colors.dart';
import '../controllers/discovery_controller.dart';
import '../models/filter_criteria.dart';
import '../models/photo_style_options.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/photographer_feed_card.dart';

class PhotographersDiscoveryScreen extends ConsumerStatefulWidget {
  const PhotographersDiscoveryScreen({super.key});

  @override
  ConsumerState<PhotographersDiscoveryScreen> createState() =>
      _PhotographersDiscoveryScreenState();
}

class _PhotographersDiscoveryScreenState
    extends ConsumerState<PhotographersDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Danh sách phong cách chụp ảnh chuẩn hệ thống LENS kèm lựa chọn 'Tất cả'
  final List<String> _styleOptions = ['Tất cả', ...PhotoStyleOptions.all];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final criteria = ref.read(discoveryControllerProvider).criteria;
      if (criteria.searchQuery != null && criteria.searchQuery!.isNotEmpty) {
        _searchController.text = criteria.searchQuery!;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(discoveryControllerProvider.notifier).search(query);
    });
  }

  void _openFilterBottomSheet() {
    final currentCriteria = ref.read(discoveryControllerProvider).criteria;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCriteria: currentCriteria,
        onApply: (newCriteria) {
          ref
              .read(discoveryControllerProvider.notifier)
              .updateFilters(newCriteria);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final controller = ref.read(discoveryControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tìm nhiếp ảnh gia của bạn',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Khám phá portfolio, so sánh phong cách và đặt lịch an toàn cùng nhiếp ảnh gia phù hợp.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Top App Bar & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Search Bar Pill
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm theo tên thợ, phong cách...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              LucideIcons.search,
                              color: Color(0xFF4B5563),
                              size: 20,
                            ),
                            suffixIcon: Icon(
                              LucideIcons.audioWaveform,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Circular Filter Button with Orange Dot
                    GestureDetector(
                      onTap: _openFilterBottomSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.slidersHorizontal,
                                color: Color(0xFF1F2937),
                                size: 20,
                              ),
                            ),
                          ),
                          if (state.activeFilterCount > 0)
                            Positioned(
                              top: 1,
                              right: 1,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5A00),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${state.activeFilterCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Genres / Style Filter Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: _styleOptions.length,
                  itemBuilder: (context, index) {
                    final style = _styleOptions[index];
                    final bool isAllGenres = (style == 'Tất cả');
                    final bool isSelected = isAllGenres
                        ? state.criteria.styles.isEmpty
                        : state.criteria.styles.contains(style);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          if (isAllGenres) {
                            controller.clearFilters();
                          } else {
                            controller.toggleStyle(style);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E2022)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5A00),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                              Text(
                                style,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${state.photographers.length} nhiếp ảnh gia',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<SortOption>(
                      initialValue: state.sortOption,
                      onSelected: controller.updateSort,
                      position: PopupMenuPosition.under,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: SortOption.featured,
                          child: Text('Nổi bật'),
                        ),
                        PopupMenuItem(
                          value: SortOption.rating,
                          child: Text('Đánh giá cao'),
                        ),
                        PopupMenuItem(
                          value: SortOption.priceAsc,
                          child: Text('Giá thấp đến cao'),
                        ),
                        PopupMenuItem(
                          value: SortOption.priceDesc,
                          child: Text('Giá cao đến thấp'),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.arrowDownUp,
                            size: 16,
                            color: Color(0xFF374151),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _sortLabel(state.sortOption),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Loading or Empty
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ember),
                ),
              )
            else if (state.photographers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.cameraOff,
                        size: 64,
                        color: AppColors.pebble,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không tìm thấy nhiếp ảnh gia phù hợp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          controller.clearFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.ember),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Text(
                          'Xóa tất cả bộ lọc',
                          style: TextStyle(
                            color: AppColors.ember,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Vertical List of Redesigned Feed Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final photographer = state.photographers[index];

                    // Before the second photographer (index 1), display "Curated Portfolios" header
                    final bool showSectionHeader = (index == 1);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showSectionHeader) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bộ sưu tập tuyển chọn',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF111827),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Những nhiếp ảnh gia tiêu biểu có lịch rảnh',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Xem tất cả',
                                    style: TextStyle(
                                      color: Color(0xFFFF5A00),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        PhotographerFeedCard(
                          photographer: photographer,
                          index: index,
                          onTap: () {
                            context.push(
                              '/customer_home/photographer/${photographer.id}',
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  }, childCount: state.photographers.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.featured:
        return 'Nổi bật';
      case SortOption.rating:
        return 'Đánh giá cao';
      case SortOption.priceAsc:
        return 'Giá thấp';
      case SortOption.priceDesc:
        return 'Giá cao';
    }
  }
}
