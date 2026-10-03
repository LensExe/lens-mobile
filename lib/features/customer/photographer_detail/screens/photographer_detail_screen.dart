import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../../providers/data_providers.dart';

import '../controllers/photographer_detail_controller.dart';
import '../models/photographer_detail_model.dart';
import '../widgets/photographer_detail_header.dart';
import '../widgets/photographer_profile_info.dart';
import '../widgets/photographer_detail_tabs.dart';
import '../widgets/tabs/about_tab_view.dart';
import '../widgets/tabs/portfolio_tab_view.dart';
import '../widgets/tabs/reviews_tab_view.dart';
import '../widgets/photographer_bottom_bar.dart';
import '../widgets/portfolio_lightbox.dart';

class PhotographerDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const PhotographerDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PhotographerDetailScreen> createState() =>
      _PhotographerDetailScreenState();
}

class _PhotographerDetailScreenState
    extends ConsumerState<PhotographerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(photographerDetailControllerProvider.notifier)
          .loadProfile(widget.id);
    });
  }

  @override
  void didUpdateWidget(covariant PhotographerDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(photographerDetailControllerProvider.notifier)
            .loadProfile(widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photographerDetailControllerProvider);
    final controller = ref.read(photographerDetailControllerProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5A00)),
        ),
      );
    }

    if (state.profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ nhiếp ảnh gia')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Không tìm thấy hồ sơ.'),
              TextButton(
                onPressed: () => controller.loadProfile(widget.id),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = state.profile!;

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/customer_home/discovery');
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/customer_home/discovery');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FA),
        body: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cover Image & Badges
                    PhotographerDetailHeader(
                      profile: profile,
                      isBookmarked: state.isBookmarked,
                      onBack: handleBack,
                      onShare: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: '/customer_home/photographer/${profile.id}',
                          ),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã sao chép liên kết hồ sơ của ${profile.name}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onToggleBookmark: () => controller.toggleBookmark(),
                    ),
                    const SizedBox(height: 12),

                    // 2. Profile Info & Trust Metrics
                    PhotographerProfileInfo(profile: profile),
                    const SizedBox(height: 20),

                    // 3. Tab Bar
                    PhotographerDetailTabs(
                      profile: profile,
                      selectedIndex: state.selectedTabIndex,
                      onTabSelected: (index) => controller.selectTab(index),
                    ),
                    const SizedBox(height: 16),

                    // 4. Tab Content View
                    _buildTabContent(context, state, controller, profile),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Booking Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PhotographerBottomBar(
                selectedPackage: state.selectedPackage,
                startingPrice: profile.startingPrice,
                onMessage: () {
                  context.push('/customer_home/messages/${profile.id}');
                },
                onBook: () {
                  final selected = state.selectedPackage;
                  context.push(
                    '/customer_home/photographer/${profile.id}/book${selected == null ? '' : '?package=${Uri.encodeComponent(selected.id)}'}',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    PhotographerDetailState state,
    PhotographerDetailController controller,
    PhotographerProfile profile,
  ) {
    switch (state.selectedTabIndex) {
      case 0:
        return PortfolioTabView(
          styles: profile.styles,
          selectedStyle: state.selectedPortfolioStyle,
          items: state.filteredPortfolio,
          onStyleSelected: (style) => controller.selectPortfolioStyle(style),
          onItemTap: (item) {
            _showImagePreview(context, item, state.filteredPortfolio, profile);
          },
        );
      case 1:
        return AboutTabView(
          profile: profile,
          packages: profile.packages,
          gearInfo: profile.gearInfo,
          selectedPackage: state.selectedPackage,
          onSelectPackage: controller.selectPackage,
          onBookPackage: (pkg) =>
              _bookPackage(context, controller, profile, pkg),
        );
      case 2:
        final myReviews = ref.watch(customerReviewsProvider).value ?? [];
        final customerName =
            ref.read(authUserProvider)?.name ?? 'Khách hàng LENS';
        final visibleReviews = [
          for (final review in myReviews.where(
            (review) => review.photographerId == profile.id,
          ))
            ClientReview(
              id: review.bookingId,
              clientName: customerName,
              clientRole: 'Khách hàng LENS',
              clientInitials: 'KH',
              rating: review.rating,
              timeAgo:
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
              packageTag: review.style,
              content: review.comment,
            ),
          ...profile.reviews,
        ];
        return ReviewsTabView(
          rating: profile.rating,
          reviewCount: profile.reviewCount,
          reviews: visibleReviews,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _bookPackage(
    BuildContext context,
    PhotographerDetailController controller,
    PhotographerProfile profile,
    ProfilePackage package,
  ) {
    controller.selectPackage(package);
    context.push(
      '/customer_home/photographer/${profile.id}/book?package=${Uri.encodeComponent(package.id)}',
    );
  }

  void _showImagePreview(
    BuildContext context,
    PortfolioItem item,
    List<PortfolioItem> allItems,
    PhotographerProfile profile,
  ) {
    final index = allItems.indexWhere((i) => i.id == item.id);
    PortfolioLightbox.show(
      context,
      items: allItems,
      initialIndex: index >= 0 ? index : 0,
      photographerId: profile.id,
      photographerName: profile.name,
    );
  }
}
