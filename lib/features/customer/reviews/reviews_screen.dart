import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lens_page.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/models/booking_model.dart';

enum _ReviewTab { pending, completed }

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  _ReviewTab _tab = _ReviewTab.pending;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingsControllerProvider);
    final reviewable = state.allBookings
        .where((booking) => booking.status == BookingStatus.released)
        .toList();
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Đánh giá của tôi'),
      ),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: () => ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            8,
            AppTokens.pageHorizontal,
            32,
          ),
          children: [
            Text(
              'Chia sẻ trải nghiệm sau những buổi chụp đã hoàn thành.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            _Tabs(
              selected: _tab,
              pendingCount: reviewable.length,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                border: Border.all(
                  color: AppColors.ember.withValues(alpha: .15),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.gift, size: 18, color: AppColors.ember),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Nhận quà tri ân sau mỗi lượt đánh giá. Gửi nhận xét khách quan để giúp cộng đồng chọn được nhiếp ảnh gia phù hợp.',
                      style: TextStyle(
                        color: AppColors.statusOrange,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (state.isLoading && state.allBookings.isEmpty)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _ReviewSkeleton(),
                ),
              )
            else if (_tab == _ReviewTab.completed)
              const _ReviewEmpty(
                title: 'Bạn chưa có đánh giá đã gửi',
                message: 'Những đánh giá bạn gửi sẽ được lưu lại tại đây.',
              )
            else if (reviewable.isEmpty)
              const _ReviewEmpty(
                title: 'Chưa có buổi chụp nào để đánh giá',
                message: 'Sau khi hoàn thành một buổi chụp, bạn có thể viết đánh giá cho nhiếp ảnh gia.',
              )
            else
              ...reviewable.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReviewRow(
                    booking: booking,
                    onReview: () => _showComingSoon(booking),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            const _ReviewTips(),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(
    Booking booking,
  ) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Tính năng viết đánh giá cho ${booking.photographerName} sẽ sớm khả dụng.',
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  final _ReviewTab selected;
  final int pendingCount;
  final ValueChanged<_ReviewTab> onChanged;
  const _Tabs({
    required this.selected,
    required this.pendingCount,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        _Tab(
          value: _ReviewTab.pending,
          selected: selected,
          label: 'Chờ đánh giá',
          count: pendingCount,
          onTap: onChanged,
        ),
        _Tab(
          value: _ReviewTab.completed,
          selected: selected,
          label: 'Đã đánh giá',
          count: 0,
          onTap: onChanged,
        ),
      ],
    ),
  );
}

class _Tab extends StatelessWidget {
  final _ReviewTab value;
  final _ReviewTab selected;
  final String label;
  final int count;
  final ValueChanged<_ReviewTab> onTap;
  const _Tab({
    required this.value,
    required this.selected,
    required this.label,
    required this.count,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.snow : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? const [AppTokens.surfaceShadow] : null,
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.ink : AppColors.steel,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final Booking booking;
  final VoidCallback onReview;
  const _ReviewRow({required this.booking, required this.onReview});
  @override
  Widget build(BuildContext context) => LensSectionCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.fog,
          backgroundImage: booking.photographerAvatar == null
              ? null
              : NetworkImage(booking.photographerAvatar!),
          child: booking.photographerAvatar == null
              ? Text(_initials(booking.photographerName))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.photographerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.style} · ${_dateLabel(booking.date)}',
                style: const TextStyle(color: AppColors.steel, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                booking.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.steel, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onReview,
          child: const Text('Viết đánh giá', style: TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );
}

class _ReviewTips extends StatelessWidget {
  const _ReviewTips();
  @override
  Widget build(BuildContext context) => LensSectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.star, size: 17, color: AppColors.ember),
            SizedBox(width: 8),
            Text(
              'Tiêu chí đánh giá chất lượng tại Lens',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Đánh giá khách quan giúp Lens có những cộng tác viên đáng tin cậy.',
          style: TextStyle(color: AppColors.steel, fontSize: 11),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Tip(
                icon: LucideIcons.clock3,
                title: 'Đúng giờ',
                color: AppColors.statusOrange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Tip(
                icon: LucideIcons.handshake,
                title: 'Tận tâm',
                color: AppColors.statusAmber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Tip(
                icon: LucideIcons.image,
                title: 'Chất lượng',
                color: AppColors.lagoon,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _Tip({required this.icon, required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.mist,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _ReviewEmpty extends StatelessWidget {
  final String title;
  final String message;
  const _ReviewEmpty({required this.title, required this.message});
  @override
  Widget build(BuildContext context) => LensSectionCard(
    child: Column(
      children: [
        const Icon(LucideIcons.star, size: 26, color: AppColors.steel),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.steel, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.pebble),
    ),
  );
}

String _dateLabel(String value) {
  final parts = value.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
}

String _initials(String value) => value
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.substring(0, 1))
    .join()
    .toUpperCase();
