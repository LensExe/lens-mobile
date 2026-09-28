import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/models.dart';
import '../../providers/data_providers.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    final bookings = ref.watch(myBookingsProvider);
    final photographers = ref.watch(photographersProvider);

    final upcoming = bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.held).toList();
    final pendingCount = bookings.where((b) => b.status == BookingStatus.pending).length;
    final upcomingCount = upcoming.length;
    final completedCount = bookings.where((b) => b.status == BookingStatus.released).length;

    // Lấy 3 thợ chụp nổi bật hoặc đánh giá cao nhất
    final recommended = photographers.toList()..sort((a, b) => b.rating.compareTo(a.rating));

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.mist,
            pinned: true,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 60),
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(color: AppColors.steel, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Khách hàng',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.obsidian, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authUserProvider.notifier).setUser(null);
                        context.go('/');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.snow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.pebble),
                        ),
                        child: const Icon(LucideIcons.logOut, size: 20, color: AppColors.obsidian),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tổng quan (Dashboard Cards)
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildStatCard(
                          title: 'Sắp tới',
                          count: upcomingCount,
                          icon: LucideIcons.calendarCheck,
                          gradient: const LinearGradient(colors: [Color(0xFF09090B), Color(0xFF27272A)]),
                          textColor: Colors.white,
                          iconColor: AppColors.ember,
                          onTap: () => context.go('/customer_home/bookings'),
                        ).animate().fade(delay: 100.ms).slideX(begin: 0.1, end: 0),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: 'Đang chờ',
                          count: pendingCount,
                          icon: LucideIcons.clock,
                          gradient: const LinearGradient(colors: [AppColors.snow, AppColors.snow]),
                          textColor: AppColors.obsidian,
                          iconColor: Colors.amber,
                          onTap: () => context.go('/customer_home/bookings'),
                        ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          title: 'Hoàn thành',
                          count: completedCount,
                          icon: LucideIcons.checkCircle,
                          gradient: const LinearGradient(colors: [AppColors.snow, AppColors.snow]),
                          textColor: AppColors.obsidian,
                          iconColor: AppColors.success,
                          onTap: () => context.go('/customer_home/bookings'),
                        ).animate().fade(delay: 300.ms).slideX(begin: 0.1, end: 0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Lịch trình sắp tới
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Lịch trình sắp tới',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.obsidian),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/customer_home/bookings'),
                          child: const Text('Xem tất cả', style: TextStyle(color: AppColors.steel, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.snow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.pebble),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(color: AppColors.mist, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.calendarHeart, color: AppColors.steel, size: 32),
                            ),
                            const SizedBox(height: 16),
                            const Text('Chưa có lịch trình', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.obsidian)),
                            const SizedBox(height: 8),
                            const Text('Khám phá và đặt lịch ngay hôm nay', style: TextStyle(color: AppColors.steel, fontSize: 14)),
                            const SizedBox(height: 24),
                            PrimaryButton(text: 'Khám phá ngay', onPressed: () => context.go('/customer_home/search')),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: upcoming.take(3).map((b) => _buildUpcomingBooking(b, context)).toList(),
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  // Gợi ý Nhiếp ảnh gia
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Gợi ý cho bạn',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.obsidian),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: recommended.length > 5 ? 5 : recommended.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildPhotographerCard(recommended[index], context)
                              .animate()
                              .fade(delay: (500 + index * 100).ms)
                              .slideX(begin: 0.1, end: 0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Gradient gradient,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: gradient.colors.first == AppColors.snow ? Border.all(color: AppColors.pebble) : null,
          boxShadow: [
            if (gradient.colors.first != AppColors.snow)
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, height: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBooking(Booking b, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/customer_home/bookings/${b.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.camera, color: AppColors.obsidian),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${b.style} - ${b.photographerName}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.obsidian),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.steel),
                      const SizedBox(width: 6),
                      Text(b.date, style: const TextStyle(color: AppColors.steel, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.chevronRight, color: AppColors.obsidian, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotographerCard(Photographer p, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/customer_home/photographer/${p.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(p.cover), fit: BoxFit.cover),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.black45, Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.star, color: AppColors.ember, size: 12),
                    const SizedBox(width: 4),
                    Text(p.rating.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(p.pricePerSession),
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
