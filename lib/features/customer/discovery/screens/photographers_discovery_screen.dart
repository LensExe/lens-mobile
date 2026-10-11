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
import '../models/photographer_model.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Timer? _debounce;

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
    if (mounted) setState(() {});
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
    if (criteria.minRating != null) {
      params['rating'] = criteria.minRating!.toString();
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
            SliverToBoxAdapter(child: _buildPageHeading()),
            if (isGuest) SliverToBoxAdapter(child: _buildGuestPrompt(context)),
            SliverToBoxAdapter(child: _buildSearchAndFilters(state)),
            SliverToBoxAdapter(child: _buildResultsToolbar(state)),
            if (state.isLoading)
              _buildLoadingSliver()
            else if (state.errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DiscoveryStatePanel(
                  icon: LucideIcons.cloudOff,
                  title: 'Chưa thể tải bộ ảnh',
                  message: state.errorMessage!,
                  actionLabel: 'Thử lại',
                  onAction: controller.retry,
                ),
              )
            else if (state.photographers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DiscoveryStatePanel(
                  icon: LucideIcons.cameraOff,
                  title: 'Chưa tìm thấy phong cách phù hợp',
                  message: 'Thử đổi từ khóa hoặc nới lỏng bộ lọc để xem thêm nhiếp ảnh gia.',
                  actionLabel: 'Xóa tìm kiếm và bộ lọc',
                  onAction: () {
                    _searchController.clear();
                    controller.clearFilters();
                    _syncUrl();
                    setState(() {});
                  },
                ),
              )
            else ...[
              _buildPhotographerResults(state.photographers),
              if (state.totalCount > 9) _buildPagination(state),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        20,
        AppTokens.pageHorizontal,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LENS  /  KHÁM PHÁ',
            style: AppTypography.labelSm(color: AppColors.steel)
                .copyWith(letterSpacing: 1.3, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Khám phá', style: AppTypography.headlineLg(fontSize: 34)),
          const SizedBox(height: 4),
          Text(
            'Tìm phong cách hình ảnh bạn yêu thích.',
            style: AppTypography.bodyMd(color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        8,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng nhập để đặt lịch và trò chuyện với nhiếp ảnh gia.',
              style: AppTypography.bodySm(color: AppColors.graphite),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(width: 4),
                FilledButton.tonal(
                  onPressed: () => context.go('/signup'),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.obsidian,
                    backgroundColor: AppColors.pebble,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                  ),
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(DiscoveryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        22,
        AppTokens.pageHorizontal,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: _isSearchFocused
                      ? AppColors.obsidian
                      : AppColors.pebble,
                  width: _isSearchFocused ? 1.2 : 0.8,
                ),
                boxShadow: _isSearchFocused
                    ? const [AppTokens.surfaceShadow]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMd(color: AppColors.obsidian),
                decoration: InputDecoration(
                  hintText: 'Tên nhiếp ảnh gia hoặc phong cách',
                  hintStyle: AppTypography.bodySm(color: AppColors.ash),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 15, right: 11),
                    child: Icon(
                      LucideIcons.search,
                      color: AppColors.obsidian,
                      size: 19,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(discoveryControllerProvider.notifier)
                                .search('');
                            _syncUrl();
                            setState(() {});
                          },
                          icon: const Icon(
                            LucideIcons.x,
                            size: 17,
                            color: AppColors.steel,
                          ),
                        ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: state.activeFilterCount == 0
                ? 'Mở bộ lọc'
                : 'Mở bộ lọc, đang áp dụng ${state.activeFilterCount}',
            child: Material(
              color: AppColors.obsidian,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: _openFilterBottomSheet,
                borderRadius: BorderRadius.circular(17),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        LucideIcons.slidersHorizontal,
                        color: AppColors.snow,
                        size: 19,
                      ),
                      if (state.activeFilterCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 17,
                            height: 17,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.ember,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              state.activeFilterCount.toString(),
                              style: AppTypography.numeric(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.snow,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsToolbar(DiscoveryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        20,
        AppTokens.pageHorizontal,
        12,
      ),
      child: Row(
        children: [
          Text(
            state.totalCount.toString(),
            style: AppTypography.numeric(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'nhiếp ảnh gia',
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.crossAxisExtent >= 350;
        final itemCount = twoColumns ? 5 : 3;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          sliver: SliverGrid.builder(
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: twoColumns ? 2 : 1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 22,
              childAspectRatio: twoColumns ? 0.76 : 1.02,
            ),
            itemBuilder: (context, index) =>
                _PhotographerTileSkeleton(compact: twoColumns),
          ),
        );
      },
    );
  }

  Widget _buildPhotographerResults(List<PhotographerModel> photographers) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.crossAxisExtent >= 350;
        final rowCount = twoColumns
            ? 1 + ((photographers.length - 1 + 1) ~/ 2)
            : photographers.length;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageHorizontal,
          ),
          sliver: SliverList.builder(
            itemCount: rowCount,
            itemBuilder: (context, rowIndex) {
              if (!twoColumns) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _buildPhotographerCard(
                    photographers[rowIndex],
                    rowIndex,
                    compact: false,
                  ),
                );
              }

              if (rowIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _buildPhotographerCard(
                    photographers.first,
                    0,
                    compact: false,
                  ),
                );
              }

              final firstIndex = 1 + (rowIndex - 1) * 2;
              final secondIndex = firstIndex + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPhotographerCard(
                        photographers[firstIndex],
                        firstIndex,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: secondIndex < photographers.length
                          ? _buildPhotographerCard(
                              photographers[secondIndex],
                              secondIndex,
                              compact: true,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPhotographerCard(
    PhotographerModel photographer,
    int index, {
    required bool compact,
  }) {
    return PhotographerFeedCard(
      key: ValueKey(photographer.id),
      photographer: photographer,
      index: index,
      compact: compact,
      onTap: () {
        context.push('/customer_home/photographer/${photographer.id}');
      },
    );
  }

  Widget _buildPagination(DiscoveryState state) {
    final controller = ref.read(discoveryControllerProvider.notifier);
    final pageCount = (state.totalCount / 9).ceil();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          4,
          AppTokens.pageHorizontal,
          16,
        ),
        child: Row(
          children: [
            _PageButton(
              label: 'Trước',
              icon: LucideIcons.arrowLeft,
              enabled: state.currentPage > 1,
              onTap: () {
                controller.previous();
                _syncUrl();
              },
            ),
            Expanded(
              child: Text(
                'Trang ${state.currentPage} / $pageCount',
                textAlign: TextAlign.center,
                style: AppTypography.labelSm(color: AppColors.steel),
              ),
            ),
            _PageButton(
              label: 'Tiếp',
              icon: LucideIcons.arrowRight,
              trailingIcon: true,
              enabled: state.hasNextPage,
              onTap: () {
                controller.next();
                _syncUrl();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool trailingIcon;
  final VoidCallback onTap;

  const _PageButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.obsidian : AppColors.ash;
    final iconWidget = Icon(icon, size: 15, color: foreground);
    final labelWidget = Text(
      label,
      style: AppTypography.labelMd(color: foreground, fontSize: 12),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTokens.pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingIcon
                ? [labelWidget, const SizedBox(width: 5), iconWidget]
                : [iconWidget, const SizedBox(width: 5), labelWidget],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _DiscoveryStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 28, 36, 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 26, color: AppColors.steel),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMd(
                color: AppColors.obsidian,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.steel)
                  .copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onAction,
              icon: Icon(
                icon == LucideIcons.cloudOff
                    ? LucideIcons.rotateCcw
                    : LucideIcons.rotateCcw,
                size: 16,
              ),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.obsidian,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotographerTileSkeleton extends StatelessWidget {
  final bool compact;

  const _PhotographerTileSkeleton({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: compact ? 1.12 : 1.24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              compact ? 17 : AppTokens.largeCardRadius,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.fog, AppColors.pebble],
                ),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.aperture,
                  color: AppColors.snow,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: compact ? double.infinity : 190,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.fog,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: compact ? 104 : 150,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.fog,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        if (compact) ...[
          const SizedBox(height: 7),
          Container(
            width: 78,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ],
    );
  }
}
