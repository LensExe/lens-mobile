import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/customer_review_model.dart';
import '../repositories/api_customer_reviews_repository.dart';

final customerReviewsRepositoryProvider = Provider<CustomerReviewsDataSource>((
  ref,
) {
  return ApiCustomerReviewsRepository(ref.watch(dioProvider));
});

class CustomerReviewsNotifier
    extends AsyncNotifier<List<SubmittedCustomerReview>> {
  final Set<String> _submittingBookings = {};

  @override
  Future<List<SubmittedCustomerReview>> build() async {
    return ref.watch(customerReviewsRepositoryProvider).getMyReviews();
  }

  Future<void> submitReview({
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required String photographerAvatar,
    required String style,
    required String date,
    required int rating,
    required int punctualityRating,
    required int attitudeRating,
    required String comment,
  }) async {
    if (!_submittingBookings.add(bookingId)) {
      throw StateError('Đang gửi đánh giá cho booking này.');
    }
    try {
      final current = state.value ?? [];
      if (current.any((review) => review.bookingId == bookingId)) {
        throw StateError('Booking này đã được đánh giá trong phiên hiện tại.');
      }
      final review = await ref
          .read(customerReviewsRepositoryProvider)
          .submitReview(
            bookingId: bookingId,
            photographerId: photographerId,
            photographerName: photographerName,
            photographerAvatar: photographerAvatar,
            style: style,
            date: date,
            rating: rating,
            punctualityRating: punctualityRating,
            attitudeRating: attitudeRating,
            comment: comment,
          );
      state = AsyncData([review, ...current]);
    } finally {
      _submittingBookings.remove(bookingId);
    }
  }
}

final customerReviewsProvider =
    AsyncNotifierProvider<
      CustomerReviewsNotifier,
      List<SubmittedCustomerReview>
    >(() => CustomerReviewsNotifier());

