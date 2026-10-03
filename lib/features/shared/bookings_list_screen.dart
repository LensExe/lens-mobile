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

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingsControllerProvider);
    final controller = ref.read(customerBookingsControllerProvider.notifier);

    if (state.errorMessage != null && state.allBookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lịch chụp của tôi')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage!),
              TextButton(
                onPressed: controller.loadBookings,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate 4 summary metrics for Flow 9
    final totalCount = state.allBookings.length;
    final pendingCount = state.allBookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final needsActionCount = state.allBookings
        .where(
          (b) =>
              b.status == BookingStatus.awaiting_deposit ||
              b.status == BookingStatus.confirmed,
        )
        .length;
    final completedCount = state.allBookings
        .where((b) => b.status == BookingStatus.released)
        .length;

    // Filter by search query if any
    final displayList = state.filteredBookings.where((booking) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return booking.photographerName.toLowerCase().contains(query) ||
          booking.style.toLowerCase().contains(query) ||
          booking.location.toLowerCase().contains(query) ||
          (booking.note?.toLowerCase().contains(query) ?? false) ||
          booking.displayCode.toLowerCase().contains(query);
    }).toList();

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
              '$totalCount tổng lịch chụp · $needsActionCount cần xử lý',
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
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Search Bar (Flow 9)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageHorizontal,
                  8,
                  AppTokens.pageHorizontal,
                  12,
                ),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.snow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.pebble),
                    boxShadow: const [AppTokens.surfaceShadow],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText:
                          'Tìm theo tên thợ, địa điểm, phong cách, mã đơn...',
                      hintStyle: AppTypography.bodySm(
                        color: AppColors.steel,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.steel,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                size: 16,
                                color: AppColors.steel,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Urgent Action Banner (Flow 9)
            if (needsActionCount > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.pageHorizontal,
                    0,
                    AppTokens.pageHorizontal,
                    14,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.ember.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.ember.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.ember,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.bellRing,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cần bạn xử lý ngay ($needsActionCount đơn)',
                                style: AppTypography.titleMd(
                                  fontSize: 13,
                                  color: AppColors.obsidian,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hoàn tất đặt cọc hoặc thanh toán đợt 2 để giữ chỗ lịch chụp.',
                                style: AppTypography.bodySm(
                                  fontSize: 11.5,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            controller.selectTab('Cần thanh toán');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ember,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: const Text(
                            'Xem ngay',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. 4 Summary Metrics Cards (Flow 9)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageHorizontal,
                  4,
                  AppTokens.pageHorizontal,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Tổng lịch',
                        value: '$totalCount',
                        selected: state.selectedTab == 'Tất cả',
                        onTap: () => controller.selectTab('Tất cả'),
                      ),
                    ),
                    _metricDivider,
                    Expanded(
                      child: _MetricCard(
                        title: 'Chờ thợ nhận',
                        value: '$pendingCount',
                        selected: state.selectedTab == 'Chờ xác nhận',
                        onTap: () => controller.selectTab('Chờ xác nhận'),
                      ),
                    ),
                    _metricDivider,
                    Expanded(
                      child: _MetricCard(
                        title: 'Cần xử lý',
                        value: '$needsActionCount',
                        selected: state.selectedTab == 'Cần thanh toán',
                        onTap: () => controller.selectTab('Cần thanh toán'),
                      ),
                    ),
                    _metricDivider,
                    Expanded(
                      child: _MetricCard(
                        title: 'Hoàn thành',
                        value: '$completedCount',
                        selected: state.selectedTab == 'Đã hoàn tất',
                        onTap: () => controller.selectTab('Đã hoàn tất'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Status Filter Tabs (Horizontal list)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: BookingStatusFilterTabs(
                  selectedTab: state.selectedTab,
                  onTabSelected: (tab) => controller.selectTab(tab),
                  countProvider: (tab) => state.getCountForTab(tab),
                ),
              ),
            ),

            // 5. Escrow Protection Summary Card
            SliverToBoxAdapter(
              child: EscrowSummaryCard(
                totalAmount: state.totalEscrowHeld,
                activeShootsCount: state.inProgressBookings.length,
                onTap: () {
                  controller.selectTab('Tất cả');
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 6)),

            // 6. Bookings List or Empty State
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ember),
                ),
              )
            else if (displayList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, state.selectedTab),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final booking = displayList[index];
                  return BookingCard(
                    booking: booking,
                    onTap: () => _handleCardTap(context, booking),
                    onPrimaryAction: () =>
                        _handlePrimaryAction(context, booking),
                    onMessage: () => _handleMessage(context, booking),
                  );
                }, childCount: displayList.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
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
      case BookingStatus.confirmed:
        context.push('/customer_home/bookings/${booking.id}/pay');
        break;
      case BookingStatus.pending:
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
      subtitle =
          'Hãy khám phá các nhiếp ảnh gia hàng đầu và đặt lịch chụp ảnh ngay!';
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTypography.numeric(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.ember : AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: AppTypography.labelSm(color: AppColors.steel),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

const _metricDivider = Padding(
  padding: EdgeInsets.symmetric(horizontal: 2),
  child: SizedBox(height: 28, child: VerticalDivider(color: AppColors.pebble)),
);
