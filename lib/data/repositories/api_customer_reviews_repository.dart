import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../domain/models/customer_review_model.dart';

abstract class CustomerReviewsDataSource {
  Future<List<SubmittedCustomerReview>> getMyReviews();

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
  Future<List<SubmittedCustomerReview>> getMyReviews() async {
    const limit = 100;
    var offset = 0;
    var total = 0;
    final reviews = <SubmittedCustomerReview>[];
    try {
      do {
        final response = await _dio.get<dynamic>(
          'customers/me/reviews',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _responseMap(response.data);
        final items = page['items'];
        if (items is! List) {
          throw const ApiException(
            'Backend trả về lịch sử đánh giá không hợp lệ.',
          );
        }
        reviews.addAll(items.map((item) => _reviewFromApi(_asMap(item))));
        total = _integer(page['total'], reviews.length);
        if (items.isEmpty) break;
        offset += items.length;
      } while (offset < total);
      return reviews;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

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
      final result = _responseMap(response.data);
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

  SubmittedCustomerReview _reviewFromApi(Map<String, dynamic> result) {
    final createdAt = DateTime.tryParse(_string(result['created_at']));
    if (createdAt == null) {
      throw const ApiException(
        'Backend không trả về thời điểm đánh giá hợp lệ.',
      );
    }
    return SubmittedCustomerReview(
      bookingId: _requiredString(result['booking_id'], 'booking_id'),
      photographerId: _string(result['photographer_id']),
      photographerName: 'Nhiếp ảnh gia',
      photographerAvatar: '',
      style: '',
      date: '',
      rating: _number(result['rating'], 0),
      punctualityRating: _integer(result['punctuality_rating'], 0),
      attitudeRating: _integer(result['attitude_rating'], 0),
      comment: _string(result['comment']),
      createdAt: createdAt,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu đánh giá không hợp lệ.');
}

String _string(Object? value) => value is String ? value : '';

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

int _integer(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _number(Object? value, int fallback) => value is num
    ? value.toDouble()
    : double.tryParse('$value') ?? fallback.toDouble();

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _asMap(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException('Backend không xác nhận lịch sử đánh giá.');
    }
    payload = _asMap(payload['data']);
  }
  return payload;
}
