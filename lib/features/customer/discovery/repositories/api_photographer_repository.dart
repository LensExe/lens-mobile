import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import 'photographer_repository.dart';

class ApiPhotographerRepository implements PhotographerRepository {
  const ApiPhotographerRepository(this._dio);

  final Dio _dio;

  @override
  Future<PhotographerPage> getPhotographersPage({
    FilterCriteria? criteria,
    required int limit,
    required int offset,
    bool topRated = false,
  }) async {
    final query = <String, Object>{'limit': limit, 'offset': offset};
    final location = criteria?.city?.trim();
    final keyword = criteria?.searchQuery?.trim();
    final minRating = criteria?.minRating;
    if (location != null && location.isNotEmpty && location != 'Tất cả') {
      query['location'] = location;
    }
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    if (minRating != null) query['min_rating'] = minRating;

    final useTopRated = topRated && query.length == 2;
    try {
      final response = await _dio.get<dynamic>(
        useTopRated ? 'photographers/top-rated' : 'photographers',
        queryParameters: query,
      );
      final page = _map(response.data);
      final rawItems = page['items'];
      if (rawItems is! List) {
        throw const ApiException(
          'Backend trả về danh sách photographer không hợp lệ.',
        );
      }
      return PhotographerPage(
        items: rawItems
            .map(
              (item) => photographerFromApi(_map(item), topRated: useTopRated),
            )
            .toList(),
        total: _number(page['total']),
        limit: _number(page['limit'], fallback: limit),
        offset: _number(page['offset'], fallback: offset),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<PhotographerModel>> getPhotographers({
    FilterCriteria? criteria,
  }) async => (await getPhotographersPage(
    criteria: criteria,
    limit: 100,
    offset: 0,
    topRated: true,
  )).items;

  @override
  Future<void> recordReview(String photographerId, double rating) async {
    throw const ApiException(
      'Đánh giá cần booking UUID và dữ liệu đánh giá hợp lệ; không thể cập nhật rating cục bộ.',
    );
  }
}

PhotographerModel photographerFromApi(
  Map<String, dynamic> json, {
  bool topRated = false,
}) {
  final rating = _map(json['rating']);
  final startedAt = json['started_career_at'];
  final experienceYears = startedAt is num
      ? DateTime.now().year - startedAt.toInt()
      : null;
  return PhotographerModel(
    id: _requiredString(json['id'], 'id'),
    name: _requiredString(json['fullname'], 'fullname'),
    avatarUrl: json['avatar_url']?.toString() ?? '',
    // PHO-005/006 do not contain a cover image or a booking-plan price.
    coverImageUrl: '',
    city: json['location']?.toString() ?? '',
    rating: _decimal(rating['average_rating']),
    reviewCount: _number(rating['total_feedbacks']),
    pricePerSession: 0,
    isFeatured: topRated,
    isVerified: json['is_verified'] == true,
    experience: experienceYears == null
        ? null
        : experienceYears < 1
        ? Experience.under1Year
        : experienceYears < 3
        ? Experience.from1To3Years
        : experienceYears < 5
        ? Experience.from3To5Years
        : Experience.over5Years,
    styles: (json['styles'] is List ? json['styles'] as List : const [])
        .map((item) => item.toString())
        .toList(),
    availableDates: const [],
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

int _number(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;
double _decimal(Object? value) => value is num ? value.toDouble() : 0;
