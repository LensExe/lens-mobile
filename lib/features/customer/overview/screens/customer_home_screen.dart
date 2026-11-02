import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/vietnam_time.dart';
import '../../../../core/widgets/lens_page.dart';
import '../../../../core/widgets/lens_tab_app_bar.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../../discovery/repositories/customer_recommendations_repository.dart';
import '../../messages/repositories/api_customer_chat_repository.dart';
import '../widgets/overview_booking_card.dart';
import '../widgets/overview_discovery_section.dart';
import '../widgets/overview_empty_bookings.dart';
import '../widgets/overview_filter_tabs.dart';
import '../widgets/overview_metrics_row.dart';
import '../widgets/overview_nearest_section.dart';
import '../widgets/overview_section_heading.dart';
import '../widgets/overview_todo_section.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  OverviewFilter _filter = OverviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final bookingState = ref.watch(customerBookingsControllerProvider);
    final recommendationsState = ref.watch(customerRecommendationsProvider);
    final bookings = bookingState.allBookings;
    final upcoming = bookings.where((booking) => _isUpcoming(booking)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final needsPayment = bookings
        .where(
          (booking) =>
              booking.flowStatus == BookingStatus.awaiting_deposit ||
              booking.needsRemainingPayment,
        )
        .toList();
    final pending = bookings
        .where((booking) => booking.flowStatus == BookingStatus.pending)
        .toList();
    final completed = bookings
        .where(
          (booking) =>
              booking.flowStatus == BookingStatus.released ||
              (booking.backendStatus == null &&
                  booking.status == BookingStatus.completed),
        )
        .toList();
    final visible = switch (_filter) {
      OverviewFilter.all => upcoming,
      OverviewFilter.payment =>
        upcoming
            .where(
              (b) =>
                  b.flowStatus == BookingStatus.awaiting_deposit ||
                  b.needsRemainingPayment,
            )
            .toList(),
      OverviewFilter.pending =>
        upcoming.where((b) => b.flowStatus == BookingStatus.pending).toList(),
      OverviewFilter.completed => completed,
    };
    final unread =
        ref
            .watch(customerConversationsProvider)
            .asData
            ?.value
            .fold<int>(
              0,
              (total, conversation) => total + conversation.unreadCount,
            ) ??
        0;
    final firstName = (user?.name ?? 'bạn').split(' ').first;

    return LensPage(
      appBar: LensTabAppBar(
        title: 'Không gian của bạn',
        subtitle: '${_greeting()}, $firstName',
        trailing: _buildProfileButton(context, firstName),
      ),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: () => ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: OverviewMetricsRow(
                bookings: bookings,
                needsPayment: needsPayment,
                pending: pending,
                completed: completed,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageHorizontal,
                  26,
                  AppTokens.pageHorizontal,
                  0,
                ),
                child: OverviewSectionHeading(
                  title: 'Lịch chụp của bạn',
                  subtitle: 'Theo dõi tiến độ và các khoản thanh toán',
                  onSeeAll: () => context.go('/customer_home/bookings'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: OverviewFilterTabs(
                selectedFilter: _filter,
                onFilterSelected: (f) => setState(() => _filter = f),
              ),
            ),
            if (bookingState.isLoading && bookings.isEmpty)
              const SliverToBoxAdapter(child: OverviewLoadingCards())
            else if (visible.isEmpty)
              SliverToBoxAdapter(child: OverviewEmptyBookings(filter: _filter))
            else
              SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTokens.pageHorizontal,
                    index == 0 ? 8 : 10,
                    AppTokens.pageHorizontal,
                    index == visible.length - 1 ? 4 : 0,
                  ),
                  child: OverviewBookingCard(booking: visible[index]),
                ),
              ),
            SliverToBoxAdapter(
              child: OverviewTodoSection(
                needsPayment: needsPayment,
                pending: pending,
                unread: unread,
              ),
            ),
            SliverToBoxAdapter(
              child: OverviewNearestSection(
                nearest: upcoming.isEmpty ? null : upcoming.first,
              ),
            ),
            SliverToBoxAdapter(
              child: OverviewDiscoverySection(
                recommendations: recommendationsState,
                onRetry: () => ref.invalidate(customerRecommendationsProvider),
                onSeeAll: () => context.go('/customer_home/discovery'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context, String firstName) {
    return Semantics(
      button: true,
      label: 'Mở tài khoản',
      child: InkWell(
        onTap: () => context.go('/customer_home/more'),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pebble),
            boxShadow: const [AppTokens.surfaceShadow],
            color: AppColors.snow,
          ),
          child: Text(
            firstName.isNotEmpty
                ? firstName.substring(0, 1).toUpperCase()
                : 'L',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
        ),
      ),
    );
  }

  bool _isUpcoming(Booking booking) =>
      ![
        BookingStatus.released,
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.rejected,
        BookingStatus.expired,
      ].contains(booking.status) &&
      booking.date.compareTo(_todayIso()) >= 0;

  String _todayIso() => DateFormat('yyyy-MM-dd').format(VietnamTime.today());

  String _greeting() {
    final hour = VietnamTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}
