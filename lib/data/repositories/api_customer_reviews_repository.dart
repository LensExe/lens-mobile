import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../domain/models/customer_review_model.dart';

abstract class CustomerReviewsDataSource {
  Future<SubmittedCustomerReview> submitReview({
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
  });
}

class ApiCustomerReviewsRepository implements CustomerReviewsDataSource {
  const ApiCustomerReviewsRepository(this._dio);

  final Dio _dio;

  @override
  Future<SubmittedCustomerReview> submitReview({
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
    if (rating < 1 ||
        rating > 5 ||
        punctualityRating < 1 ||
        punctualityRating > 5 ||
        attitudeRating < 1 ||
        attitudeRating > 5) {
      throw const ApiException('Mỗi tiêu chí cần được chấm từ 1 đến 5 sao.');
    }
    final trimmedComment = comment.trim();
    if (trimmedComment.length > 10000) {
      throw const ApiException('Nhận xét không được vượt quá 10.000 ký tự.');
    }

    final body = <String, dynamic>{
      'rating': rating,
      'punctuality_rating': punctualityRating,
      'attitude_rating': attitudeRating,
      if (trimmedComment.isNotEmpty) 'comment': trimmedComment,
    };

    try {
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/reviews',
        data: body,
      );
      final result = _asMap(response.data);
      return SubmittedCustomerReview(
        bookingId: _string(result['booking_id']).isEmpty
            ? bookingId
            : _string(result['booking_id']),
        photographerId: _string(result['photographer_id']).isEmpty
            ? photographerId
            : _string(result['photographer_id']),
        photographerName: photographerName,
        photographerAvatar: photographerAvatar,
        style: style,
        date: date,
        rating: _number(result['rating'], rating),
        punctualityRating: _integer(
          result['punctuality_rating'],
          punctualityRating,
        ),
        attitudeRating: _integer(result['attitude_rating'], attitudeRating),
        comment: _string(result['comment']).isEmpty
            ? trimmedComment
            : _string(result['comment']),
        createdAt:
            DateTime.tryParse(_string(result['created_at'])) ?? DateTime.now(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        throw const ApiException(
          'Backend từ chối đánh giá vì booking chưa hoàn thành hoặc đã có đánh giá.',
          statusCode: 409,
        );
      }
      throw ApiException.fromDio(error);
    }
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu đánh giá không hợp lệ.');
}

String _string(Object? value) => value is String ? value : '';

int _integer(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _number(Object? value, int fallback) => value is num
    ? value.toDouble()
    : double.tryParse('$value') ?? fallback.toDouble();
