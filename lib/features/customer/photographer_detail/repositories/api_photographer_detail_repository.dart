import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/vietnam_time.dart';
import '../../discovery/utils/photographer_cover_resolver.dart';
import '../models/photographer_detail_model.dart';
import 'photographer_detail_repository.dart';

class ApiPhotographerDetailRepository implements PhotographerDetailRepository {
  const ApiPhotographerDetailRepository(this._dio);

  final Dio _dio;

  @override
  Future<PhotographerProfile> getPhotographerProfile(
    String photographerId,
  ) async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('photographers/$photographerId'),
        _dio.get<dynamic>('photographers/$photographerId/booking-plans'),
        _dio.get<dynamic>(
          'photographers/$photographerId/portfolios',
          queryParameters: const {'limit': 100, 'offset': 0},
        ),
        _dio.get<dynamic>(
          'photographers/$photographerId/reviews',
          queryParameters: const {'limit': 100, 'offset': 0},
        ),
        _dio.get<dynamic>('photographers/$photographerId/rating-summary'),
      ]);
      final profileJson = _responseMap(responses[0].data);
      final planData = _responseMap(responses[1].data);
      final portfolioPage = _responseMap(responses[2].data);
      final reviewPage = _responseMap(responses[3].data);
      final summary = _responseMap(responses[4].data);

      final packages = _items(planData)
          .where((item) => item['is_active'] != false)
          .map(_package)
          .toList();
      final portfolios = <PortfolioItem>[];
      var coverUrl = '';
      for (final portfolioJson in _items(portfolioPage)) {
        final id = _string(portfolioJson['id']);
        if (id.isEmpty) continue;
        final detail = _responseMap(
          (await _dio.get<dynamic>('portfolios/$id')).data,
        );
        coverUrl = coverUrl.isEmpty ? _string(detail['cover_url']) : coverUrl;
        if (coverUrl.isNotEmpty) {
          PhotographerCoverResolver.setCachedCover(photographerId, coverUrl);
        }
        for (final item in _list(detail['items'])) {
          final json = _asMap(item);
          final url = _string(json['download_url']);
          if (url.isEmpty) continue;
          portfolios.add(
            PortfolioItem(
              id: _string(json['id']),
              imageUrl: url,
              title: _string(detail['name']),
              style: _string(detail['category']),
              subtitle: _string(detail['description']),
              cameraGear: '',
            ),
          );
        }
      }

      final profileRating = _asMap(profileJson['rating']);
      final reviews = _items(reviewPage).map(_review).toList();
      final startedAt = profileJson['started_career_at'];
      final startedYear = startedAt is num ? startedAt.toInt() : null;
      final rank = _asMap(profileJson['rank']);
      final rating =
          summary['average_rating'] ?? profileRating['average_rating'];
      final reviewCount =
          summary['total_feedbacks'] ?? profileRating['total_feedbacks'];
      final startingPrice = packages.isEmpty
          ? 0
          : packages
                .map((package) => package.price)
                .reduce((a, b) => a < b ? a : b);

      return PhotographerProfile(
        id: _string(profileJson['id']),
        name: _string(profileJson['fullname']),
        avatarUrl: _string(profileJson['avatar_url']),
        coverImageUrl: coverUrl.isNotEmpty
            ? coverUrl
            : _string(profileJson['avatar_url']),
        city: _string(profileJson['location']),
        rank: _string(rank['name']),
        rating: _decimal(rating),
        reviewCount: _number(reviewCount),
        startingPrice: startingPrice,
        bio: _string(profileJson['description']),
        experienceYears: startedYear == null
            ? null
            : (DateTime.now().year - startedYear).clamp(0, 200),
        completedShoots: null,
        completionRate: null,
        isVerified: profileJson['is_verified'] == true,
        isInsured: null,
        verificationBadge: profileJson['is_verified'] == true
            ? 'Đã xác minh'
            : null,
        styles: _strings(profileJson['styles']),
        portfolio: portfolios,
        packages: packages,
        reviews: reviews,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<AvailabilityRange>> getAvailability({
    required String photographerId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'photographers/$photographerId/availability',
        queryParameters: {
          'from': _withVietnamOffset(from),
          'to': _withVietnamOffset(to),
        },
      );
      return _items(_responseMap(response.data)).map((item) {
        final json = _asMap(item);
        return AvailabilityRange(
          from: DateTime.parse(_requiredString(json['from'], 'from')),
          to: DateTime.parse(_requiredString(json['to'], 'to')),
        );
      }).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

ProfilePackage _package(Map<String, dynamic> json) {
  final minutes = _number(json['duration_minutes']);
  final duration = minutes % 60 == 0
      ? '${minutes ~/ 60} giờ'
      : '${(minutes / 60).toStringAsFixed(1)} giờ';
  final featureTexts = _strings(json['features']);
  return ProfilePackage(
    id: _requiredString(json['id'], 'booking_plan.id'),
    name: _requiredString(json['name'], 'booking_plan.name'),
    subtitle: _string(json['description']),
    price: _number(json['price']),
    duration: duration,
    durationMinutes: minutes,
    deliverables: featureTexts,
    photoCount: _number(json['photo_count']),
    highlightBadge: '',
  );
}

ClientReview _review(Map<String, dynamic> json) {
  final customer = _asMap(json['customer']);
  final name = _string(customer['name']);
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.substring(0, 1).toUpperCase())
      .join();
  final createdAt = DateTime.tryParse(_string(json['created_at']));
  return ClientReview(
    id: _string(json['id']),
    clientName: name,
    clientInitials: initials,
    rating: _decimal(json['rating']),
    timeAgo: createdAt == null ? '' : _relativeTime(createdAt),
    content: _string(json['comment']),
  );
}

String _relativeTime(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'Hôm nay';
  if (days == 1) return '1 ngày trước';
  if (days < 7) return '$days ngày trước';
  final weeks = days ~/ 7;
  if (weeks == 1) return '1 tuần trước';
  if (weeks < 5) return '$weeks tuần trước';
  return '${date.day}/${date.month}/${date.year}';
}

String _withVietnamOffset(DateTime date) {
  return VietnamTime.toApiIso(date);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _asMap(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException(
        'Backend không xác nhận yêu cầu hồ sơ nhiếp ảnh gia thành công.',
      );
    }
    payload = _asMap(payload['data']);
  }
  return payload;
}

List<Map<String, dynamic>> _items(Map<String, dynamic> json) =>
    _list(json['items']).map(_asMap).toList();
List<Object?> _list(Object? value) =>
    value is List ? value.cast<Object?>() : const [];
List<String> _strings(Object? value) =>
    _list(value)
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
String _string(Object? value) => value is String ? value.trim() : '';
String _requiredString(Object? value, String field) {
  final result = _string(value);
  if (result.isEmpty) {
    throw ApiException('Backend không trả về trường $field hợp lệ.');
  }
  return result;
}

int _number(Object? value) => value is num ? value.toInt() : 0;
double _decimal(Object? value) => value is num ? value.toDouble() : 0;
