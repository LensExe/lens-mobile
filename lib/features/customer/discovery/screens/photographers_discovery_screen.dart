import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/data_providers.dart';
import '../controllers/discovery_controller.dart';
import '../models/filter_criteria.dart';
import '../models/photo_style_options.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/photographer_feed_card.dart';
import '../widgets/sort_bottom_sheet.dart';

class PhotographersDiscoveryScreen extends ConsumerStatefulWidget {
  const PhotographersDiscoveryScreen({super.key});

  @override
  ConsumerState<PhotographersDiscoveryScreen> createState() =>
      _PhotographersDiscoveryScreenState();
}

class _PhotographersDiscoveryScreenState
    extends ConsumerState<PhotographersDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Timer? _debounce;

  // Danh sách phong cách chụp ảnh chuẩn hệ thống LENS kèm lựa chọn 'Tất cả'
  final List<String> _styleOptions = ['Tất cả', ...PhotoStyleOptions.all];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters.isNotEmpty) {
        ref.read(discoveryControllerProvider.notifier).applyQuery(uri);
      }
      final criteria = ref.read(discoveryControllerProvider).criteria;
      if (criteria.searchQuery != null && criteria.searchQuery!.isNotEmpty) {
        _searchController.text = criteria.searchQuery!;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(discoveryControllerProvider.notifier).search(query);
      _syncUrl();
    });
  }

  void _syncUrl() {
    if (!mounted) return;
    final state = ref.read(discoveryControllerProvider);
    final criteria = state.criteria;
    final params = <String, String>{};
    if (criteria.searchQuery?.trim().isNotEmpty == true) {
      params['q'] = criteria.searchQuery!.trim();
    }
    if (criteria.city?.isNotEmpty == true && criteria.city != 'Tất cả') {
      params['city'] = criteria.city!;
    }
    if (criteria.minPrice != null) {
      params['priceMin'] = criteria.minPrice!.toStringAsFixed(0);
    }
    if (criteria.maxPrice != null) {
      params['priceMax'] = criteria.maxPrice!.toStringAsFixed(0);
    }
    if (criteria.availableDate != null) {
      final date = criteria.availableDate!;
      params['date'] =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (criteria.minRating != null) {
      params['rating'] = criteria.minRating!.toString();
    }
    if (criteria.experience != null) params['exp'] = criteria.experience!.name;
    if (criteria.styles.isNotEmpty) {
      params['styles'] = criteria.styles.join(',');
    }
    if (state.sortOption != SortOption.featured) {
      params['sort'] = state.sortOption.name;
    }
    if (state.currentPage > 1) params['page'] = state.currentPage.toString();
    final target = Uri(
      path: '/customer_home/discovery',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
    if (GoRouterState.of(context).uri.toString() != target) {
      context.replace(target);
    }
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
          _syncUrl();
        },
      ),
    );
  }

  void _openSortBottomSheet() {
    final currentSort = ref.read(discoveryControllerProvider).sortOption;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheet(
        initialSort: currentSort,
        onApply: (newSort) {
          ref.read(discoveryControllerProvider.notifier).updateSort(newSort);
          _syncUrl();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final controller = ref.read(discoveryControllerProvider.notifier);
    final isGuest = ref.watch(authUserProvider) == null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageHorizontal,
                  20,
                  AppTokens.pageHorizontal,
                  4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm nhiếp ảnh gia của bạn',
                      style: AppTypography.headlineLg(fontSize: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tìm cảm hứng qua những bộ ảnh và phong cách khác nhau.',
                      style: AppTypography.bodyMd(color: AppColors.steel),
                    ),
                  ],
                ),
              ),
            ),
            if (isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.snow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.pebble),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tạo tài khoản để đặt lịch và trò chuyện với nhiếp ảnh gia.',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Đăng nhập'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => context.go('/signup'),
                              child: const Text('Đăng ký'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Top App Bar & Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    // Search Bar Pill (Height 48px, transitions to White + Pebble on focus)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: AppTokens.searchBarHeight,
                        decoration: BoxDecoration(
                          color: _isSearchFocused
                              ? AppColors.snow
                              : AppColors.fog,
                          borderRadius: BorderRadius.circular(
                            AppTokens.pillRadius,
                          ),
                          border: Border.all(
                            color: _isSearchFocused
                                ? AppColors.pebble
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: AppTypography.bodyMd(
                            color: AppColors.obsidian,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên thợ, phong cách...',
                            hintStyle: AppTypography.bodyMd(
                              color: AppColors.ash,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              color: AppColors.steel,
                              size: 19,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      ref
                                          .read(
                                            discoveryControllerProvider
                                                .notifier,
                                          )
                                          .search('');
                                      _syncUrl();
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      LucideIcons.x,
                                      color: AppColors.steel,
                                      size: 18,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Circular Filter Button (Height 48px, hairline Pebble border)
                    GestureDetector(
                      onTap: _openFilterBottomSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: AppTokens.searchBarHeight,
                            width: AppTokens.searchBarHeight,
                            decoration: BoxDecoration(
                              color: AppColors.snow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pebble,
                                width: 1.0,
                              ),
                              boxShadow: const [AppTokens.surfaceShadow],
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.slidersHorizontal,
                                color: AppColors.obsidian,
                                size: 19,
                              ),
                            ),
                          ),
                          if (state.activeFilterCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ember,
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
                            controller.updateFilters(
                              state.criteria.copyWith(styles: []),
                            );
                          } else {
                            controller.toggleStyle(style);
                          }
                          _syncUrl();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.obsidian
                                : AppColors.fog,
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
                                    color: AppColors.ember,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                              Text(
                                style,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.snow
                                      : AppColors.graphite,
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
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${state.totalCount}',
                              style: AppTypography.numeric(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.obsidian,
                              ),
                            ),
                            TextSpan(
                              text: ' nhiếp ảnh gia',
                              style: AppTypography.bodySm(
                                color: AppColors.steel,
                              ).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        final isCustomSort =
                            state.sortOption != SortOption.featured;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openSortBottomSheet,
                            borderRadius: BorderRadius.circular(
                              AppTokens.pillRadius,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: AppTokens.filterChipHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isCustomSort
                                    ? AppColors.ember.withValues(alpha: 0.08)
                                    : AppColors.snow,
                                borderRadius: BorderRadius.circular(
                                  AppTokens.pillRadius,
                                ),
                                border: Border.all(
                                  color: isCustomSort
                                      ? AppColors.ember
                                      : AppColors.pebble,
                                  width: 1.0,
                                ),
                                boxShadow: const [AppTokens.surfaceShadow],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.arrowDownUp,
                                    size: 14,
                                    color: isCustomSort
                                        ? AppColors.ember
                                        : AppColors.obsidian,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _sortLabel(state.sortOption),
                                    style:
                                        AppTypography.labelMd(
                                          color: isCustomSort
                                              ? AppColors.ember
                                              : AppColors.obsidian,
                                          fontSize: 12,
                                        ).copyWith(
                                          fontWeight: isCustomSort
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 13,
                                    color: isCustomSort
                                        ? AppColors.ember
                                        : AppColors.steel,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
            else if (state.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.errorMessage!),
                      TextButton(
                        onPressed: controller.retry,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
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
                          _syncUrl();
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

            if (!state.isLoading &&
                state.errorMessage == null &&
                state.totalCount > 9)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: state.currentPage > 1
                            ? () {
                                controller.previous();
                                _syncUrl();
                              }
                            : null,
                        child: const Text('Trước'),
                      ),
                      Text(
                        'Trang ${state.currentPage}/${(state.totalCount / 9).ceil()}',
                      ),
                      TextButton(
                        onPressed: state.hasNextPage
                            ? () {
                                controller.next();
                                _syncUrl();
                              }
                            : null,
                        child: const Text('Tiếp'),
                      ),
                    ],
                  ),
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
        return 'Giá thấp đến cao';
      case SortOption.priceDesc:
        return 'Giá cao đến thấp';
      case SortOption.reviewCount:
        return 'Nhiều đánh giá';
    }
  }
}
