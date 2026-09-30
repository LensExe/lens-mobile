import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/lens_page.dart';
import '../../core/widgets/primary_button.dart';
import '../../features/customer/bookings/controllers/customer_bookings_controller.dart';
import '../../features/customer/bookings/models/booking_model.dart';
import '../../features/customer/bookings/widgets/booking_status_pill.dart';
import '../../features/customer/discovery/controllers/discovery_controller.dart';
import '../../features/customer/discovery/models/photographer_model.dart';
import '../../providers/data_providers.dart';

enum _OverviewFilter { all, payment, pending, completed }

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  _OverviewFilter _filter = _OverviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final bookingState = ref.watch(customerBookingsControllerProvider);
    final discoveryState = ref.watch(discoveryControllerProvider);
    final bookings = bookingState.allBookings;
    final upcoming = bookings.where((booking) => _isUpcoming(booking)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final needsPayment = bookings
        .where(
          (booking) =>
              booking.status == BookingStatus.awaiting_deposit ||
              booking.status == BookingStatus.confirmed,
        )
        .toList();
    final pending = bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .toList();
    final completed = bookings
        .where((booking) => booking.status == BookingStatus.released)
        .toList();
    final visible = switch (_filter) {
      _OverviewFilter.all => upcoming,
      _OverviewFilter.payment =>
        upcoming
            .where(
              (b) =>
                  b.status == BookingStatus.awaiting_deposit ||
                  b.status == BookingStatus.confirmed,
            )
            .toList(),
      _OverviewFilter.pending =>
        upcoming.where((b) => b.status == BookingStatus.pending).toList(),
      _OverviewFilter.completed => completed,
    };
    final unread = ref
        .watch(conversationsProvider)
        .fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        );
    final firstName = (user?.name ?? 'bạn').split(' ').first;
    final recommendations = [...discoveryState.photographers]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return LensPage(
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
            SliverToBoxAdapter(child: _buildHeader(context, firstName)),
            SliverToBoxAdapter(
              child: _buildMetrics(
                context,
                bookings,
                needsPayment,
                pending,
                completed,
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
                child: _buildSectionHeading(
                  'Lịch chụp của bạn',
                  'Theo dõi tiến độ và các khoản thanh toán',
                  onSeeAll: () => context.go('/customer_home/bookings'),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFilterTabs()),
            if (bookingState.isLoading && bookings.isEmpty)
              const SliverToBoxAdapter(child: _LoadingCards())
            else if (visible.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyBookings(context, _filter))
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
                  child: _OverviewBookingCard(
                    booking: visible[index],
                    featured: index == 0,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _buildTodoSection(context, needsPayment, pending, unread),
            ),
            SliverToBoxAdapter(
              child: _buildNearestSection(
                context,
                upcoming.isEmpty ? null : upcoming.first,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildDiscoverySection(context, recommendations),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        18,
        AppTokens.pageHorizontal,
        6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_greeting()}, $firstName',
                      style: AppTypography.bodySm(color: AppColors.steel),
                    ),
                    const SizedBox(width: 4),
                    const Text('✦', style: TextStyle(color: AppColors.ember, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng quan studio',
                  style: AppTypography.headlineMd(color: AppColors.obsidian),
                ),
              ],
            ),
          ),
          InkWell(
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
                firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'L',
                style: AppTypography.titleMd(color: AppColors.obsidian),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    List<Booking> bookings,
    List<Booking> needsPayment,
    List<Booking> pending,
    List<Booking> completed,
  ) {
    final metrics = [
      _MetricData(
        LucideIcons.calendarCheck,
        'Tổng buổi chụp',
        bookings.length,
        AppColors.fog,
        AppColors.obsidian,
      ),
      _MetricData(
        LucideIcons.walletCards,
        'Cần thanh toán',
        needsPayment.length,
        AppColors.ember.withValues(alpha: .12),
        AppColors.ember,
      ),
      _MetricData(
        LucideIcons.clock4,
        'Chờ xác nhận',
        pending.length,
        AppColors.lagoon.withValues(alpha: .12),
        AppColors.lagoon,
      ),
      _MetricData(
        LucideIcons.checkCircle2,
        'Đã hoàn thành',
        completed.length,
        AppColors.emerald.withValues(alpha: .12),
        AppColors.emerald,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        18,
        AppTokens.pageHorizontal,
        0,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: metric.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(metric.icon, size: 17, color: metric.iconColor),
                    ),
                    Text(
                      '${metric.value}',
                      style: AppTypography.numeric(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ],
                ),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(color: AppColors.steel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headlineSm(color: AppColors.obsidian),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem tất cả',
                  style: AppTypography.labelMd(color: AppColors.ember),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppColors.ember,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final items = const [
      (_OverviewFilter.all, 'Tất cả'),
      (_OverviewFilter.payment, 'Cần thanh toán'),
      (_OverviewFilter.pending, 'Chờ duyệt'),
      (_OverviewFilter.completed, 'Đã hoàn tất'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        14,
        AppTokens.pageHorizontal,
        6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: items.map((item) {
            final isSelected = _filter == item.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _filter = item.$1),
                borderRadius: BorderRadius.circular(9999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: AppTokens.filterChipHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.obsidian : AppColors.fog,
                    borderRadius: BorderRadius.circular(9999),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    item.$2,
                    style: AppTypography.labelMd(
                      color: isSelected ? AppColors.snow : AppColors.steel,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyBookings(BuildContext context, _OverviewFilter filter) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        12,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.fog,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.calendarDays,
                size: 24,
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              filter == _OverviewFilter.completed
                  ? 'Chưa có buổi chụp hoàn thành'
                  : 'Chưa có buổi chụp phù hợp',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 6),
            Text(
              'Khám phá nhiếp ảnh gia hàng đầu và đặt lịch chụp cho bạn.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Tìm nhiếp ảnh gia',
              expand: false,
              onPressed: () => context.go('/customer_home/discovery'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoSection(
    BuildContext context,
    List<Booking> needsPayment,
    List<Booking> pending,
    int unread,
  ) {
    final items = <Widget>[];
    if (needsPayment.isNotEmpty) {
      final booking = needsPayment.first;
      items.add(
        _TodoItem(
          icon: LucideIcons.creditCard,
          title: booking.status == BookingStatus.awaiting_deposit
              ? 'Thanh toán tiền cọc'
              : 'Thanh toán phần còn lại',
          hint: 'Hoàn tất để giữ lịch chụp của bạn.',
          color: AppColors.ember,
          onTap: () => context.push(
            '/customer_home/bookings/${booking.id}/${booking.status == BookingStatus.awaiting_deposit ? 'deposit' : 'pay'}',
          ),
        ),
      );
    }
    if (pending.isNotEmpty) {
      items.add(
        _TodoItem(
          icon: LucideIcons.clock4,
          title: 'Chờ nhiếp ảnh gia xác nhận',
          hint: '${pending.first.photographerName} đang xem yêu cầu của bạn.',
          color: AppColors.lagoon,
          onTap: () =>
              context.push('/customer_home/bookings/${pending.first.id}'),
        ),
      );
    }
    if (unread > 0) {
      items.add(
        _TodoItem(
          icon: LucideIcons.messageSquare,
          title: 'Bạn có tin nhắn mới',
          hint: '$unread tin nhắn chưa đọc từ nhiếp ảnh gia.',
          color: AppColors.obsidian,
          onTap: () => context.go('/customer_home/messages'),
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const _TodoItem(
          icon: LucideIcons.checkCircle2,
          title: 'Mọi việc đã sẵn sàng',
          hint: 'Hiện tại bạn không có khoản nào cần xử lý.',
          color: AppColors.emerald,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        28,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkles, size: 16, color: AppColors.ember),
                const SizedBox(width: 8),
                Text(
                  'Việc cần làm',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: item,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearestSection(BuildContext context, Booking? nearest) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        14,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.calendarClock, size: 16, color: AppColors.ember),
                const SizedBox(width: 8),
                Text(
                  'Lịch chụp gần nhất',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (nearest == null)
              Text(
                'Bạn chưa có lịch chụp nào sắp tới.',
                style: AppTypography.bodySm(color: AppColors.steel),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    context.push('/customer_home/bookings/${nearest.id}'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fog,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nearest.timeSlot ?? '--:--',
                            style: AppTypography.numeric(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.obsidian,
                            ),
                          ),
                          BookingStatusPill(status: nearest.status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nearest.style,
                        style: AppTypography.titleMd(color: AppColors.obsidian),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 13, color: AppColors.steel),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(nearest.date),
                            style: AppTypography.numeric(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.steel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.mapPin, size: 13, color: AppColors.steel),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nearest.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(color: AppColors.steel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'với nhiếp ảnh gia ${nearest.photographerName}',
                        style: AppTypography.labelSm(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySection(
    BuildContext context,
    List<PhotographerModel> photographers,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.pageHorizontal, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.pageHorizontal),
            child: _buildSectionHeading(
              'Gợi ý dành cho bạn',
              'Khám phá theo phong cách nghệ thuật yêu thích',
              onSeeAll: () => context.go('/customer_home/discovery'),
            ),
          ),
          const SizedBox(height: 14),
          if (photographers.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: AppTokens.pageHorizontal),
                itemCount: photographers.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _RecommendationCard(photographer: photographers[index]),
              ),
            ),
        ],
      ),
    );
  }

  bool _isUpcoming(Booking booking) =>
      booking.status != BookingStatus.released &&
      booking.status != BookingStatus.cancelled &&
      booking.date.compareTo(_todayIso()) >= 0;

  String _todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _formatDate(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final int value;
  final Color background;
  final Color iconColor;
  const _MetricData(
    this.icon,
    this.label,
    this.value,
    this.background,
    this.iconColor,
  );
}

class _TodoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Color color;
  final VoidCallback? onTap;
  const _TodoItem({
    required this.icon,
    required this.title,
    required this.hint,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMd(
                      fontSize: 13,
                      color: AppColors.obsidian,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: AppTypography.bodySm(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.steel,
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBookingCard extends StatelessWidget {
  final Booking booking;
  final bool featured;
  const _OverviewBookingCard({required this.booking, required this.featured});

  @override
  Widget build(BuildContext context) {
    final end = booking.timeSlot == null || booking.packageSnapshot == null
        ? null
        : _addMinutes(
            booking.timeSlot!,
            booking.packageSnapshot!.durationHours * 60,
          );

    final isAwaitingDeposit = booking.status == BookingStatus.awaiting_deposit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  color: AppColors.fog,
                ),
                child: ClipOval(
                  child: booking.photographerAvatar != null &&
                          booking.photographerAvatar!.isNotEmpty
                      ? Image.network(
                          booking.photographerAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              booking.photographerName.isNotEmpty
                                  ? booking.photographerName.substring(0, 1)
                                  : '?',
                              style: AppTypography.titleMd(),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            booking.photographerName.isNotEmpty
                                ? booking.photographerName.substring(0, 1)
                                : '?',
                            style: AppTypography.titleMd(),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.photographerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd(
                        fontSize: 15,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.style,
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusPill(status: booking.status, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendarDays,
                  size: 14,
                  color: AppColors.steel,
                ),
                const SizedBox(width: 6),
                Text(
                  _dateLabel(booking.date),
                  style: AppTypography.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.obsidian,
                  ),
                ),
                if (booking.timeSlot != null)
                  Text(
                    ' · ${booking.timeSlot}${end == null ? '' : '–$end'}',
                    style: AppTypography.numeric(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.steel,
                    ),
                  ),
                const SizedBox(width: 12),
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.steel),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm(
                      fontSize: 12,
                      color: AppColors.steel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (featured && booking.status != BookingStatus.cancelled) ...[
            const SizedBox(height: 14),
            _BookingProgress(status: booking.status),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng chi phí',
                    style: AppTypography.labelSm(
                      fontSize: 10,
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    AppTypography.formatCurrency(booking.price),
                    style: AppTypography.priceDisplay(
                      fontSize: 15,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isAwaitingDeposit)
                FilledButton(
                  onPressed: () => GoRouter.of(context).push(
                    '/customer_home/bookings/${booking.id}/deposit',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ember,
                    foregroundColor: AppColors.snow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Đặt cọc ngay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => GoRouter.of(context)
                      .push('/customer_home/bookings/${booking.id}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.obsidian,
                    side: const BorderSide(color: AppColors.pebble),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chi tiết',
                        style: AppTypography.labelMd(
                          fontSize: 12,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppColors.steel,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateLabel(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }

  static String _addMinutes(String value, double minutes) {
    final parts = value.split(':');
    if (parts.length != 2) return value;
    final date = DateTime(
      2000,
      1,
      1,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    ).add(Duration(minutes: minutes.round()));
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _BookingProgress extends StatelessWidget {
  final BookingStatus status;
  const _BookingProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = switch (status) {
      BookingStatus.awaiting_deposit => 0,
      BookingStatus.pending => 1,
      BookingStatus.confirmed => 2,
      BookingStatus.held => 3,
      BookingStatus.released => 4,
      BookingStatus.cancelled => 0,
    };
    const labels = ['Đặt cọc', 'Xác nhận', 'Thanh toán', 'Hoàn tất'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < active
                        ? AppColors.emerald
                        : i == active
                            ? AppColors.ember
                            : AppColors.fog,
                    border: Border.all(
                      color: i <= active ? Colors.transparent : AppColors.pebble,
                      width: 1,
                    ),
                  ),
                  child: i < active
                      ? const Icon(
                          LucideIcons.check,
                          size: 13,
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: i == active ? Colors.white : AppColors.steel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: i <= active ? AppColors.obsidian : AppColors.steel,
                    fontWeight: i <= active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: i < active ? AppColors.emerald : AppColors.pebble,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final PhotographerModel photographer;
  const _RecommendationCard({required this.photographer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: () =>
            context.push('/customer_home/photographer/${photographer.id}'),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            color: AppColors.slate,
            border: Border.all(color: AppColors.pebble),
            image: DecorationImage(
              image: NetworkImage(photographer.coverImageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassContainer.mediaBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            color: AppColors.ember,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            photographer.rating.toStringAsFixed(1),
                            style: AppTypography.numeric(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (photographer.isFeatured)
                      const Icon(
                        LucideIcons.badgeCheck,
                        color: AppColors.emerald,
                        size: 18,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  photographer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${photographer.city} · ${photographer.styles.take(1).join()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTypography.formatCurrency(photographer.pricePerSession),
                  style: AppTypography.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        12,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 142,
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                border: Border.all(color: AppColors.pebble),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
