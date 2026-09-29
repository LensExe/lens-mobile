import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
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
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch đặt của tôi',
              style: TextStyle(
                color: Color(0xFF1A1C1D),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${state.allBookings.length} tổng bản ghi',
              style: const TextStyle(
                color: Color(0xFF5F5E60),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: Color(0xFF1A1C1D),
              ),
            ),
            onPressed: () => controller.loadBookings(),
            tooltip: 'Tải lại',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF5A00),
        onRefresh: () => controller.loadBookings(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Client Workspace & Active Count Tag Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E9),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'CLIENT WORKSPACE',
                            style: TextStyle(
                              color: Color(0xFF5B4137),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDBCF),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5A00),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${state.activeCount} Đang hoạt động',
                                style: const TextStyle(
                                  color: Color(0xFF380D00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${state.filteredBookings.length} hiển thị',
                      style: const TextStyle(
                        color: Color(0xFF5F5E60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
              child: SizedBox(height: 4),
            ),

            // 4. Bookings List or Empty State
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF5A00),
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
              child: SizedBox(height: 32),
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
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarX2,
                size: 38,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1C1D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F5E60),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/customer_home/discovery'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A00),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5A00).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Khám phá nhiếp ảnh gia',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
