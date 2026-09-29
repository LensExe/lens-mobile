import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/photographer_detail_controller.dart';
import '../models/photographer_detail_model.dart';
import '../widgets/photographer_detail_header.dart';
import '../widgets/photographer_profile_info.dart';
import '../widgets/photographer_detail_tabs.dart';
import '../widgets/tabs/portfolio_tab_view.dart';
import '../widgets/tabs/packages_tab_view.dart';
import '../widgets/tabs/reviews_tab_view.dart';
import '../widgets/tabs/studio_gear_tab_view.dart';
import '../widgets/photographer_bottom_bar.dart';

class PhotographerDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const PhotographerDetailScreen({
    super.key,
    required this.id,
  });

  @override
  ConsumerState<PhotographerDetailScreen> createState() => _PhotographerDetailScreenState();
}

class _PhotographerDetailScreenState extends ConsumerState<PhotographerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photographerDetailControllerProvider.notifier).loadProfile(widget.id);
    });
  }

  @override
  void didUpdateWidget(covariant PhotographerDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(photographerDetailControllerProvider.notifier).loadProfile(widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photographerDetailControllerProvider);
    final controller = ref.read(photographerDetailControllerProvider.notifier);

    if (state.isLoading || state.profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5A00),
          ),
        ),
      );
    }

    final profile = state.profile!;

    return Scaffold(
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
                    onBack: () => context.pop(),
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép liên kết hồ sơ của ${profile.name}'),
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
                context.push('/customer_home/photographer/${profile.id}/book');
              },
            ),
          ),
        ],
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
            _showImagePreview(context, item);
          },
        );
      case 1:
        return PackagesTabView(
          packages: profile.packages,
          selectedPackage: state.selectedPackage,
          onSelectPackage: (pkg) => controller.selectPackage(pkg),
          onBookPackage: (pkg) {
            controller.selectPackage(pkg);
            context.push('/customer_home/photographer/${profile.id}/book');
          },
        );
      case 2:
        return ReviewsTabView(
          rating: profile.rating,
          reviewCount: profile.reviewCount,
          reviews: profile.reviews,
        );
      case 3:
        return StudioGearTabView(
          gearInfo: profile.gearInfo,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showImagePreview(BuildContext context, PortfolioItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.black45,
                    child: const Center(
                      child: Text('Không thể tải ảnh', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${item.title} • ${item.cameraGear}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
