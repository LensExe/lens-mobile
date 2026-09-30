import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
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
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Đánh giá của tôi',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.ember,
        onRefresh: () => ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings(),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            8,
            AppTokens.pageHorizontal,
            40,
          ),
          children: [
            Text(
              'Chia sẻ trải nghiệm khách quan sau mỗi buổi chụp đã hoàn thành để giúp cộng đồng.',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            _Tabs(
              selected: _tab,
              pendingCount: reviewable.length,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ember.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.gift, size: 18, color: AppColors.ember),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhận Lens Xu tri ân',
                          style: AppTypography.titleMd(
                            fontSize: 13.5,
                            color: AppColors.obsidian,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mỗi đánh giá hợp lệ sẽ được tặng ngay Xu vào ví Lens của bạn.',
                          style: AppTypography.bodySm(
                            fontSize: 12,
                            color: AppColors.steel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.isLoading && state.allBookings.isEmpty)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _ReviewSkeleton(),
                ),
              )
            else if (_tab == _ReviewTab.completed)
              const _ReviewEmpty(
                title: 'Chưa có đánh giá nào đã gửi',
                message: 'Những đánh giá bạn đã viết sẽ được lưu trữ và hiển thị tại đây.',
              )
            else if (reviewable.isEmpty)
              const _ReviewEmpty(
                title: 'Chưa có buổi chụp nào để đánh giá',
                message: 'Sau khi hoàn thành và nghiệm thu buổi chụp, bạn có thể viết đánh giá cho nhiếp ảnh gia.',
              )
            else
              ...reviewable.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewRow(
                    booking: booking,
                    onReview: () => _showComingSoon(booking),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const _ReviewTips(),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(Booking booking) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Đang mở cổng đánh giá cho ${booking.photographerName}.',
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabPill(
          label: 'Chờ đánh giá',
          count: pendingCount,
          selected: selected == _ReviewTab.pending,
          onTap: () => onChanged(_ReviewTab.pending),
        ),
        const SizedBox(width: 8),
        _TabPill(
          label: 'Đã đánh giá',
          count: 0,
          selected: selected == _ReviewTab.completed,
          onTap: () => onChanged(_ReviewTab.completed),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: AppTokens.filterChipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.obsidian : AppColors.fog,
          borderRadius: BorderRadius.circular(9999),
          border: selected
              ? null
              : Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMd(
                color: selected ? AppColors.snow : AppColors.steel,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.ember : AppColors.mist,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: AppTypography.numeric(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.steel,
                  ),
                ),
              ),
            ],
          ],
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Row(
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
            child: booking.photographerAvatar != null && booking.photographerAvatar!.isNotEmpty
                ? Image.network(
                    booking.photographerAvatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        _initials(booking.photographerName),
                        style: AppTypography.titleMd(),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _initials(booking.photographerName),
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
                  fontSize: 14.5,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${booking.style} · ${_dateLabel(booking.date)}',
                style: AppTypography.bodySm(color: AppColors.steel, fontSize: 11.5),
              ),
              const SizedBox(height: 2),
              Text(
                booking.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(color: AppColors.steel, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.ember,
              borderRadius: BorderRadius.circular(9999),
            ),
            alignment: Alignment.center,
            child: Text(
              'Đánh giá',
              style: AppTypography.labelMd(fontSize: 12, color: AppColors.snow),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewTips extends StatelessWidget {
  const _ReviewTips();

  @override
  Widget build(BuildContext context) => Container(
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
            const Icon(LucideIcons.star, size: 16, color: AppColors.ember),
            const SizedBox(width: 8),
            Text(
              'Tiêu chí đánh giá chất lượng tại Lens',
              style: AppTypography.titleMd(fontSize: 14, color: AppColors.obsidian),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Đánh giá công tâm giúp cộng đồng chọn được nhiếp ảnh gia ưng ý nhất.',
          style: AppTypography.bodySm(color: AppColors.steel, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Tip(
                icon: LucideIcons.clock3,
                title: 'Đúng giờ',
                color: AppColors.ember,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Tip(
                icon: LucideIcons.handshake,
                title: 'Tận tâm',
                color: AppColors.lagoon,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Tip(
                icon: LucideIcons.image,
                title: 'Chất lượng',
                color: AppColors.emerald,
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTypography.labelMd(fontSize: 12, color: AppColors.obsidian),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: AppColors.fog,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.star, size: 24, color: AppColors.steel),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySm(color: AppColors.steel),
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
