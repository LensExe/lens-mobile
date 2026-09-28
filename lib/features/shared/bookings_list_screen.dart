import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/data_providers.dart';
import '../../domain/models/models.dart';
import '../../data/mock_database.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = [
    'Tất cả',
    'Chờ duyệt',
    'Đã xác nhận',
    'Đang thực hiện',
    'Hoàn thành',
    'Đã hủy'
  ];

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final filteredBookings = _getFilteredBookings(bookings, _selectedFilter);

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch đặt của tôi',
              style: TextStyle(
                color: AppColors.obsidian,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${filteredBookings.length} buổi chụp',
              style: const TextStyle(color: AppColors.steel, fontSize: 14),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterChips(),
          Expanded(
            child: filteredBookings.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final b = filteredBookings[index];
                      return _buildBookingCard(b);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.obsidian : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppColors.obsidian : AppColors.pebble,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? AppColors.snow : AppColors.obsidian,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_selectedFilter == 'Tất cả') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.calendarX2, size: 64, color: AppColors.ash),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa có lịch đặt nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.obsidian),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                text: 'Tìm nhiếp ảnh gia',
                onPressed: () => context.go('/customer_home'),
              ),
            ),
          ],
        ),
      ).animate().fade();
    } else {
      return Center(
        child: Text(
          'Không có lịch đặt ở trạng thái này',
          style: const TextStyle(color: AppColors.steel, fontSize: 16),
        ).animate().fade(),
      );
    }
  }

  Widget _buildBookingCard(Booking b) {
    // Note: To display avatar properly, we look up photographer in MockDatabase (as a workaround for now)
    final photographer = MockDatabase.photographers.firstWhere(
      (p) => p.id == b.photographerId,
      orElse: () => MockDatabase.photographers.first,
    );

    return InkWell(
      onTap: () => context.push('/customer_home/bookings/${b.id}'),
      borderRadius: BorderRadius.circular(16),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(photographer.avatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.photographerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.obsidian,
                    ),
                  ),
                ),
                _buildBadge(b.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Gói chụp ${b.style}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              '${b.date} • ${b.location}',
              style: const TextStyle(color: AppColors.steel, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.pebble),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền', style: TextStyle(color: AppColors.steel, fontSize: 14)),
                Text(
                  '${_formatCurrency(b.price)} đ',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.obsidian),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildBadge(BookingStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.confirmed:
        bgColor = AppColors.warning.withAlpha(30);
        textColor = AppColors.warning;
        text = status == BookingStatus.pending ? 'Chờ duyệt' : 'Đã xác nhận';
        break;
      case BookingStatus.held:
      case BookingStatus.released:
        bgColor = AppColors.success.withAlpha(30);
        textColor = AppColors.success;
        text = status == BookingStatus.held ? 'Đang thực hiện' : 'Hoàn thành';
        break;
      case BookingStatus.cancelled:
        bgColor = AppColors.destructive.withAlpha(30);
        textColor = AppColors.destructive;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Booking> _getFilteredBookings(List<Booking> all, String filter) {
    if (filter == 'Tất cả') return all;
    return all.where((b) {
      switch (filter) {
        case 'Chờ duyệt': return b.status == BookingStatus.pending;
        case 'Đã xác nhận': return b.status == BookingStatus.confirmed;
        case 'Đang thực hiện': return b.status == BookingStatus.held;
        case 'Hoàn thành': return b.status == BookingStatus.released;
        case 'Đã hủy': return b.status == BookingStatus.cancelled;
        default: return true;
      }
    }).toList();
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
