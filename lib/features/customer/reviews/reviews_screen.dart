import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/models/customer_review_model.dart';
import '../../../providers/data_providers.dart';
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
    final bookingsState = ref.watch(customerBookingsControllerProvider);
    final reviewsState = ref.watch(customerReviewsProvider);
    final reviews = (reviewsState.value ?? [])
        .map((review) {
          Booking? booking;
          for (final item in bookingsState.allBookings) {
            if (item.id == review.bookingId) {
              booking = item;
              break;
            }
          }
          if (booking == null) return review;
          return review.copyWith(
            photographerName: booking.photographerName.isEmpty
                ? review.photographerName
                : booking.photographerName,
            photographerAvatar:
                booking.photographerAvatar ?? review.photographerAvatar,
            style: booking.style.isEmpty ? review.style : booking.style,
            date: booking.date.isEmpty ? review.date : booking.date,
          );
        })
        .toList(growable: false);

    // Backend permits review creation only after the booking is completed.
    final reviewedBookingIds = reviews.map((r) => r.bookingId).toSet();
    final reviewable = bookingsState.allBookings
        .where(
          (booking) =>
              booking.status == BookingStatus.completed &&
              !reviewedBookingIds.contains(booking.id),
        )
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
        onRefresh: () async {
          ref.invalidate(customerReviewsProvider);
          await Future.wait([
            ref
                .read(customerBookingsControllerProvider.notifier)
                .loadBookings(),
            ref.read(customerReviewsProvider.future),
          ]);
        },
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
              'Chia sẻ trải nghiệm sau buổi chụp đã hoàn thành để giúp khách hàng khác tham khảo.',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            _Tabs(
              selected: _tab,
              pendingCount: reviewable.length,
              completedCount: reviews.length,
              onChanged: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pebble),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 19,
                    color: AppColors.ember,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chỉ booking ở trạng thái completed mới đủ điều kiện. Backend lưu đánh giá tổng thể, đúng giờ và thái độ để đồng bộ lịch sử trên các thiết bị.',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (bookingsState.errorMessage != null || reviewsState.hasError)
              Center(
                child: Column(
                  children: [
                    const Text('Không thể tải đánh giá. Vui lòng thử lại.'),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(customerReviewsProvider);
                        ref
                            .read(customerBookingsControllerProvider.notifier)
                            .loadBookings();
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            else if ((bookingsState.isLoading &&
                    bookingsState.allBookings.isEmpty) ||
                reviewsState.isLoading)
              ...List.generate(
                3,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: _ReviewSkeleton(),
                ),
              )
            else if (_tab == _ReviewTab.pending) ...[
              if (reviewable.isEmpty)
                const _ReviewEmpty(
                  title: 'Chưa có buổi chụp nào cần đánh giá',
                  message: 'Sau khi Backend chuyển booking sang completed, bạn có thể gửi đánh giá cho nhiếp ảnh gia.',
                )
              else
                ...reviewable.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewRow(
                      booking: booking,
                      onReview: () => _openReviewDialog(booking),
                    ),
                  ),
                ),
            ] else ...[
              if (reviews.isEmpty)
                const _ReviewEmpty(
                  title: 'Bạn chưa có đánh giá đã gửi',
                  message: 'Những đánh giá đã được Backend lưu sẽ xuất hiện tại đây.',
                )
              else
                ...reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CompletedReviewCard(
                      review: review,
                      onTap: () => _openReadOnlyReviewDialog(review),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),
            const _ReviewTips(),
          ],
        ),
      ),
    );
  }

  void _openReviewDialog(Booking booking) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BookingReviewDialog(booking: booking),
    );
  }

  void _openReadOnlyReviewDialog(SubmittedCustomerReview review) {
    showDialog<void>(
      context: context,
      builder: (context) => _BookingReviewDialog.readOnly(review: review),
    );
  }
}

class _BookingReviewDialog extends ConsumerStatefulWidget {
  final Booking? booking;
  final SubmittedCustomerReview? review;
  final bool isReadOnly;

  const _BookingReviewDialog({required this.booking})
    : review = null,
      isReadOnly = false;

  const _BookingReviewDialog.readOnly({required this.review})
    : booking = null,
      isReadOnly = true;

  @override
  ConsumerState<_BookingReviewDialog> createState() =>
      _BookingReviewDialogState();
}

class _BookingReviewDialogState extends ConsumerState<_BookingReviewDialog> {
  double _rating = 5.0;
  int _punctualityRating = 5;
  int _attitudeRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly && widget.review != null) {
      _rating = widget.review!.rating;
      _punctualityRating = widget.review!.punctualityRating;
      _attitudeRating = widget.review!.attitudeRating;
      _commentController.text = widget.review!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating >= 5) return 'Tuyệt vời';
    if (_rating >= 4) return 'Rất tốt';
    if (_rating >= 3) return 'Hài lòng';
    if (_rating >= 2) return 'Cần cải thiện';
    return 'Không hài lòng';
  }

  @override
  Widget build(BuildContext context) {
    final photographerName = widget.isReadOnly
        ? widget.review!.photographerName
        : widget.booking!.photographerName;
    final style = widget.isReadOnly
        ? widget.review!.style
        : widget.booking!.style;
    final date = widget.isReadOnly ? widget.review!.date : widget.booking!.date;

    final commentLength = _commentController.text.trim().length;
    final canSubmit =
        !widget.isReadOnly &&
        _rating >= 1 &&
        _punctualityRating >= 1 &&
        _attitudeRating >= 1 &&
        commentLength <= 10000;

    return Dialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isReadOnly
                            ? 'Đánh giá đã gửi'
                            : 'Viết đánh giá buổi chụp',
                        style: AppTypography.headlineSm(
                          fontSize: 17,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$photographerName · $style',
                        style: AppTypography.bodySm(
                          fontSize: 12,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.fog,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppColors.steel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Date & Info badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.steel,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ngày chụp: ${_dateLabel(date)}',
                    style: AppTypography.bodySm(
                      fontSize: 12,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _ratingLabel,
              style: AppTypography.titleMd(
                fontSize: 15,
                color: AppColors.ember,
              ),
            ),
            const SizedBox(height: 10),
            _RatingSelector(
              label: 'Đánh giá tổng thể',
              value: _rating.round(),
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _rating = value.toDouble()),
            ),
            const SizedBox(height: 8),
            _RatingSelector(
              label: 'Đúng giờ',
              value: _punctualityRating,
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _punctualityRating = value),
            ),
            const SizedBox(height: 8),
            _RatingSelector(
              label: 'Thái độ phục vụ',
              value: _attitudeRating,
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _attitudeRating = value),
            ),
            const SizedBox(height: 20),

            // Comment Section
            Text(
              'Nhận xét của bạn',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 8),
            if (widget.isReadOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.pebble),
                ),
                child: Text(
                  widget.review!.comment.isEmpty
                      ? 'Không có nhận xét.'
                      : widget.review!.comment,
                  style: AppTypography.bodySm(
                    color: AppColors.obsidian,
                    fontSize: 13,
                  ),
                ),
              )
            else
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 10000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ về sự chuyên nghiệp, đúng giờ, nhiệt tình của thợ và chất lượng bộ ảnh nhận được...',
                  hintStyle: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: AppColors.fog,
                  counterText: '$commentLength/10.000 ký tự · Không bắt buộc',
                  counterStyle: AppTypography.bodySm(
                    fontSize: 11,
                    color: commentLength <= 10000
                        ? AppColors.steel
                        : AppColors.ember,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.pebble),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.pebble),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.obsidian,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action Button
            if (widget.isReadOnly)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.pebble),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: Text('Đóng', style: AppTypography.labelMd()),
              )
            else
              PrimaryButton(
                text: 'Gửi đánh giá',
                height: 48,
                isLoading: _isSubmitting,
                onPressed: canSubmit ? _submitReview : () {},
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final booking = widget.booking!;

    try {
      await ref
          .read(customerReviewsProvider.notifier)
          .submitReview(
            bookingId: booking.id,
            photographerId: booking.photographerId,
            photographerName: booking.photographerName,
            photographerAvatar: booking.photographerAvatar ?? '',
            style: booking.style,
            date: booking.date,
            rating: _rating.round(),
            punctualityRating: _punctualityRating,
            attitudeRating: _attitudeRating,
            comment: _commentController.text.trim(),
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backend đã ghi nhận đánh giá cho ${booking.photographerName}.',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Không thể gửi đánh giá. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool readOnly;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.labelMd(color: AppColors.obsidian),
        ),
      ),
      for (var score = 1; score <= 5; score++)
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
          onPressed: readOnly ? null : () => onChanged(score),
          icon: Icon(
            score <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 25,
            color: score <= value ? const Color(0xFFF59E0B) : AppColors.pebble,
          ),
        ),
    ],
  );
}

class _Tabs extends StatelessWidget {
  final _ReviewTab selected;
  final int pendingCount;
  final int completedCount;
  final ValueChanged<_ReviewTab> onChanged;

  const _Tabs({
    required this.selected,
    required this.pendingCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabPill(
            label: 'Chờ đánh giá',
            count: pendingCount,
            selected: selected == _ReviewTab.pending,
            onTap: () => onChanged(_ReviewTab.pending),
          ),
          const SizedBox(width: 8),
          _TabPill(
            label: 'Đã gửi phiên này',
            count: completedCount,
            selected: selected == _ReviewTab.completed,
            onTap: () => onChanged(_ReviewTab.completed),
          ),
        ],
      ),
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
            child:
                booking.photographerAvatar != null &&
                    booking.photographerAvatar!.isNotEmpty
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
                style: AppTypography.bodySm(
                  color: AppColors.steel,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(
                  color: AppColors.steel,
                  fontSize: 11.5,
                ),
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
              'Viết đánh giá',
              style: AppTypography.labelMd(fontSize: 12, color: AppColors.snow),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompletedReviewCard extends StatelessWidget {
  final SubmittedCustomerReview review;
  final VoidCallback onTap;

  const _CompletedReviewCard({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.snow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.pebble),
          boxShadow: const [AppTokens.surfaceShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pebble),
                    color: AppColors.fog,
                  ),
                  child: ClipOval(
                    child: review.photographerAvatar.isNotEmpty
                        ? Image.network(
                            review.photographerAvatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                _initials(review.photographerName),
                                style: AppTypography.titleMd(fontSize: 12),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _initials(review.photographerName),
                              style: AppTypography.titleMd(fontSize: 12),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.photographerName,
                        style: AppTypography.titleMd(
                          fontSize: 13.5,
                          color: AppColors.obsidian,
                        ),
                      ),
                      Text(
                        '${review.style} · ${_dateLabel(review.date)}',
                        style: AppTypography.bodySm(
                          fontSize: 11,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTypography.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm(
                fontSize: 12.5,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}',
                  style: AppTypography.bodySm(
                    fontSize: 11,
                    color: AppColors.steel,
                  ),
                ),
                Text(
                  'Xem chi tiết',
                  style: AppTypography.labelSm(
                    fontSize: 11,
                    color: AppColors.ember,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
            Expanded(
              child: Text(
                'Tiêu chí đánh giá chất lượng tại Lens',
                style: AppTypography.titleMd(
                  fontSize: 14,
                  color: AppColors.obsidian,
                ),
              ),
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
