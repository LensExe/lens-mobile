import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lens_page.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../controllers/customer_reviews_controller.dart';
import '../models/customer_review_model.dart';
import '../widgets/booking_review_dialog.dart';
import '../widgets/review_cards.dart';
import '../widgets/review_tabs.dart';
import '../widgets/review_tips_section.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});
  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  ReviewTab _tab = ReviewTab.pending;

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
            ReviewTabs(
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
                  child: ReviewSkeleton(),
                ),
              )
            else if (_tab == ReviewTab.pending) ...[
              if (reviewable.isEmpty)
                const ReviewEmptyState(
                  title: 'Chưa có buổi chụp nào cần đánh giá',
                  message: 'Sau khi Backend chuyển booking sang completed, bạn có thể gửi đánh giá cho nhiếp ảnh gia.',
                )
              else
                ...reviewable.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PendingReviewRow(
                      booking: booking,
                      onReview: () => _openReviewDialog(booking),
                    ),
                  ),
                ),
            ] else ...[
              if (reviews.isEmpty)
                const ReviewEmptyState(
                  title: 'Bạn chưa có đánh giá đã gửi',
                  message: 'Những đánh giá đã được Backend lưu sẽ xuất hiện tại đây.',
                )
              else
                ...reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CompletedReviewCard(
                      review: review,
                      onTap: () => _openReadOnlyReviewDialog(review),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),
            const ReviewTips(),
          ],
        ),
      ),
    );
  }

  void _openReviewDialog(Booking booking) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BookingReviewDialog(booking: booking),
    );
  }

  void _openReadOnlyReviewDialog(SubmittedCustomerReview review) {
    showDialog<void>(
      context: context,
      builder: (context) => BookingReviewDialog.readOnly(review: review),
    );
  }
}
