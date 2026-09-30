import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import '../customer/bookings/controllers/customer_bookings_controller.dart';
import '../customer/bookings/models/booking_model.dart';
import '../customer/bookings/widgets/booking_card.dart';
import '../customer/bookings/widgets/booking_status_filter_tabs.dart';
import '../customer/bookings/widgets/escrow_summary_card.dart';

class BookingsListScreen extends ConsumerWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerBookingsControllerProvider);
    final controller = ref.read(customerBookingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch chụp của tôi',
              style: AppTypography.headlineMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 2),
            Text(
              '${state.allBookings.length} tổng buổi chụp',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.snow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: const Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: AppColors.obsidian,
              ),
            ),
            onPressed: () => controller.loadBookings(),
            tooltip: 'Tải lại',
          ),
          const SizedBox(width: AppTokens.pageHorizontal),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: () => controller.loadBookings(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Client Workspace & Active Count Tag Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.pageHorizontal,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.fog,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            'KHÁCH HÀNG',
                            style: AppTypography.numeric(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.ember.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.ember,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${state.activeCount} Đang hoạt động',
                                style: AppTypography.numeric(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ember,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${state.filteredBookings.length} hiển thị',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Status Filter Tabs (Horizontal list)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: BookingStatusFilterTabs(
                  selectedTab: state.selectedTab,
                  onTabSelected: (tab) => controller.selectTab(tab),
                  countProvider: (tab) => state.getCountForTab(tab),
                ),
              ),
            ),

            // 3. Escrow Protection Summary Card
            SliverToBoxAdapter(
              child: EscrowSummaryCard(
                totalAmount: state.totalEscrowHeld,
                activeShootsCount: state.inProgressBookings.length,
                onTap: () {
                  controller.selectTab('Đang thực hiện');
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 6),
            ),

            // 4. Bookings List or Empty State
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.ember,
                  ),
                ),
              )
            else if (state.filteredBookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, state.selectedTab),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = state.filteredBookings[index];
                    return BookingCard(
                      booking: booking,
                      onTap: () => _handleCardTap(context, booking),
                      onPrimaryAction: () => _handlePrimaryAction(context, booking),
                      onMessage: () => _handleMessage(context, booking),
                    );
                  },
                  childCount: state.filteredBookings.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 48),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardTap(BuildContext context, Booking booking) {
    context.push('/customer_home/bookings/${booking.id}');
  }

  void _handlePrimaryAction(BuildContext context, Booking booking) {
    switch (booking.status) {
      case BookingStatus.held:
        context.push('/customer_home/bookings/${booking.id}/gallery');
        break;
      case BookingStatus.awaiting_deposit:
        context.push('/customer_home/bookings/${booking.id}/deposit');
        break;
      case BookingStatus.pending:
      case BookingStatus.confirmed:
      case BookingStatus.released:
      case BookingStatus.cancelled:
        context.push('/customer_home/bookings/${booking.id}');
        break;
    }
  }

  void _handleMessage(BuildContext context, Booking booking) {
    context.push('/customer_home/messages/${booking.photographerId}');
  }

  Widget _buildEmptyState(BuildContext context, String selectedTab) {
    String title = 'Không có lịch đặt nào';
    String subtitle = 'Bạn chưa có buổi chụp nào trong mục "$selectedTab".';

    if (selectedTab == 'Tất cả') {
      title = 'Bạn chưa có lịch đặt nào';
      subtitle = 'Hãy khám phá các nhiếp ảnh gia hàng đầu và đặt lịch chụp ảnh ngay!';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarX2,
                size: 32,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Khám phá nhiếp ảnh gia',
              expand: false,
              onPressed: () => context.go('/customer_home/discovery'),
            ),
          ],
        ),
      ),
    );
  }
}
