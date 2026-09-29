import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
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
                  'Lịch chụp sắp tới',
                  'Theo dõi tiến độ và các khoản cần xử lý',
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
                    index == 0 ? 4 : 8,
                    AppTokens.pageHorizontal,
                    index == visible.length - 1 ? 0 : 0,
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
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        22,
        AppTokens.pageHorizontal,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $firstName ✦',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.steel),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng quan lịch chụp',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'Theo dõi lịch đặt, thanh toán và những khoảnh khắc sắp tới của bạn.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.steel),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () => context.go('/customer_home/more'),
            icon: const Icon(
              LucideIcons.circleUserRound,
              color: AppColors.obsidian,
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
      ),
      _MetricData(
        LucideIcons.walletCards,
        'Cần thanh toán',
        needsPayment.length,
        AppColors.ember.withValues(alpha: .1),
      ),
      _MetricData(
        LucideIcons.calendarClock,
        'Chờ xác nhận',
        pending.length,
        const Color(0xFFE6F4F2),
      ),
      _MetricData(
        LucideIcons.checkCircle2,
        'Đã hoàn thành',
        completed.length,
        const Color(0xFFD1FAE5),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        22,
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
          childAspectRatio: 1.32,
        ),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return LensSectionCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: metric.background,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(metric.icon, size: 17, color: metric.iconColor),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metric.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppColors.ink),
                    ),
                  ],
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
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.steel),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('Xem tất cả')),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final items = const [
      (_OverviewFilter.all, 'Tất cả'),
      (_OverviewFilter.payment, 'Cần thanh toán'),
      (_OverviewFilter.pending, 'Chờ xác nhận'),
      (_OverviewFilter.completed, 'Đã hoàn thành'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        12,
        AppTokens.pageHorizontal,
        4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(item.$2),
                    selected: _filter == item.$1,
                    onSelected: (_) => setState(() => _filter = item.$1),
                  ),
                ),
              )
              .toList(),
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
      child: LensSectionCard(
        child: Column(
          children: [
            const Icon(
              LucideIcons.calendarDays,
              size: 28,
              color: AppColors.steel,
            ),
            const SizedBox(height: 12),
            Text(
              filter == _OverviewFilter.completed
                  ? 'Chưa có buổi chụp hoàn thành'
                  : 'Chưa có buổi chụp phù hợp',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tìm một nhiếp ảnh gia phù hợp để bắt đầu lưu giữ khoảnh khắc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.steel, fontSize: 13),
            ),
            const SizedBox(height: 14),
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
          onTap: () => context.push(
            '/customer_home/bookings/${booking.id}/${booking.status == BookingStatus.awaiting_deposit ? 'deposit' : 'pay'}',
          ),
        ),
      );
    }
    if (pending.isNotEmpty) {
      items.add(
        _TodoItem(
          icon: LucideIcons.calendarClock,
          title: 'Chờ nhiếp ảnh gia xác nhận',
          hint: '${pending.first.photographerName} đang xem yêu cầu của bạn.',
          onTap: () =>
              context.push('/customer_home/bookings/${pending.first.id}'),
          lagoon: true,
        ),
      );
    }
    if (unread > 0) {
      items.add(
        _TodoItem(
          icon: LucideIcons.messageSquare,
          title: 'Bạn có tin nhắn mới',
          hint: '$unread tin nhắn chưa đọc từ nhiếp ảnh gia.',
          onTap: () => context.go('/customer_home/messages'),
          lagoon: true,
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const _TodoItem(
          icon: LucideIcons.checkCircle2,
          title: 'Mọi thứ đang được cập nhật',
          hint: 'Bạn chưa có việc cần xử lý.',
          lagoon: true,
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
      child: LensSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(icon: LucideIcons.clock3, title: 'Việc cần làm'),
            const SizedBox(height: 12),
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
        12,
        AppTokens.pageHorizontal,
        0,
      ),
      child: LensSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(
              icon: LucideIcons.sunMedium,
              title: 'Ngày chụp gần nhất',
            ),
            const SizedBox(height: 10),
            if (nearest == null)
              const Text(
                'Bạn chưa có lịch chụp sắp tới.',
                style: TextStyle(color: AppColors.steel, fontSize: 13),
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    context.push('/customer_home/bookings/${nearest.id}'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nearest.timeSlot ?? '--:--',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nearest.style,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(nearest.date)} · ${nearest.location}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.steel,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'với ${nearest.photographerName}',
                        style: const TextStyle(
                          color: AppColors.steel,
                          fontSize: 12,
                        ),
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
              'Sẵn sàng cho buổi chụp tiếp theo?',
              'Khám phá theo phong cách bạn yêu thích.',
              onSeeAll: () => context.go('/customer_home/discovery'),
            ),
          ),
          const SizedBox(height: 12),
          if (photographers.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
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
  const _MetricData(this.icon, this.label, this.value, this.background);
  Color get iconColor => background == AppColors.fog
      ? AppColors.steel
      : background == const Color(0xFFE6F4F2)
      ? AppColors.lagoon
      : background == const Color(0xFFD1FAE5)
      ? AppColors.success
      : AppColors.ember;
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.ember),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _TodoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback? onTap;
  final bool lagoon;
  const _TodoItem({
    required this.icon,
    required this.title,
    required this.hint,
    this.onTap,
    this.lagoon = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = lagoon ? AppColors.lagoon : AppColors.ember;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
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
    return LensSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.fog,
                backgroundImage: booking.photographerAvatar == null
                    ? null
                    : NetworkImage(booking.photographerAvatar!),
                child: booking.photographerAvatar == null
                    ? Text(
                        booking.photographerName.isEmpty
                            ? '?'
                            : booking.photographerName.substring(0, 1),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.photographerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BookingStatusPill(
                          status: booking.status,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.style,
                      style: const TextStyle(
                        color: AppColors.steel,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: '₫',
                  decimalDigits: 0,
                ).format(booking.price),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                LucideIcons.calendarDays,
                size: 14,
                color: AppColors.steel,
              ),
              const SizedBox(width: 6),
              Text(
                _dateLabel(booking.date),
                style: const TextStyle(fontSize: 12, color: AppColors.steel),
              ),
              if (booking.timeSlot != null)
                Text(
                  ' · ${booking.timeSlot}${end == null ? '' : '–$end'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.steel),
                ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.mapPin, size: 14, color: AppColors.steel),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  booking.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.steel),
                ),
              ),
            ],
          ),
          if (featured && booking.status != BookingStatus.cancelled) ...[
            const SizedBox(height: 12),
            _BookingProgress(status: booking.status),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hint(booking),
                  style: const TextStyle(fontSize: 11, color: AppColors.steel),
                ),
              ),
              TextButton(
                onPressed: () =>
                    GoRouter.of(context)
                        .push('/customer_home/bookings/${booking.id}'),
                child: const Text('Chi tiết'),
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

  static String _hint(Booking booking) => switch (booking.status) {
    BookingStatus.awaiting_deposit => 'Giữ lịch sau khi thanh toán cọc',
    BookingStatus.pending => 'Đang chờ nhiếp ảnh gia xác nhận',
    BookingStatus.confirmed =>
      'Còn lại ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(booking.remainingAmount)}',
    BookingStatus.held => 'Lens đang giữ tiền an toàn',
    BookingStatus.released => 'Buổi chụp đã hoàn tất',
    BookingStatus.cancelled => 'Lịch đặt đã huỷ',
  };
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
    const labels = ['Đã đặt cọc', 'Xác nhận lịch', 'Thanh toán', 'Hoàn thành'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < active
                        ? AppColors.lagoon
                        : i == active
                        ? AppColors.ember
                        : AppColors.fog,
                  ),
                  child: i < active
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: i == active ? Colors.white : AppColors.steel,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: i <= active ? AppColors.ink : AppColors.steel,
                    fontWeight: i <= active
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 1,
                color: i < active ? AppColors.lagoon : AppColors.pebble,
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
      width: 175,
      child: InkWell(
        onTap: () =>
            context.push('/customer_home/photographer/${photographer.id}'),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            color: AppColors.slate,
            image: DecorationImage(
              image: NetworkImage(photographer.coverImageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.star,
                      color: AppColors.ember,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      photographer.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (photographer.isFeatured)
                      const Icon(
                        LucideIcons.badgeCheck,
                        color: Colors.white,
                        size: 16,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  photographer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${photographer.city} · ${photographer.styles.take(1).join()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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
