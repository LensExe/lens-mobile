import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_cover_resolver.dart';
import 'photographer_repository.dart';

List<String> _mapStyleToSlugs(String style) {
  final normalized = foldVietnamese(style.trim().toLowerCase());
  if (normalized.contains('chan dung')) return ['portrait', 'concept'];
  if (normalized.contains('cuoi')) return ['wedding', 'pre-wedding'];
  if (normalized.contains('thoi trang')) {
    return ['fashion', 'streetwear', 'commercial'];
  }
  if (normalized.contains('su kien')) {
    return ['event', 'corporate', 'commercial'];
  }
  if (normalized.contains('gia dinh')) return ['family', 'kids', 'maternity'];
  if (normalized.contains('ngoai canh') || normalized.contains('bien')) {
    return ['beach', 'outdoor'];
  }
  if (normalized.contains('han quoc')) return ['korean'];
  if (normalized.contains('vintage') || normalized.contains('phim')) {
    return ['vintage', 'film'];
  }
  if (normalized.contains('duong pho')) return ['streetwear', 'fashion'];
  return [style.trim().toLowerCase()];
}

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
    final location = criteria?.city?.trim();
    final rawKeyword = criteria?.searchQuery?.trim();
    final style = criteria?.style?.trim();
    final minRating = criteria?.minRating;

    final hasLocation =
        location != null && location.isNotEmpty && location != 'Tất cả';
    final hasKeyword = rawKeyword != null && rawKeyword.isNotEmpty;
    final hasStyle = style != null && style.isNotEmpty && style != 'Tất cả';
    final hasRating = minRating != null;
    final hasFilters = hasLocation || hasKeyword || hasStyle || hasRating;

    // Fast path: Default browse without active search or filter
    if (!hasFilters) {
      final query = <String, Object>{'limit': limit, 'offset': offset};
      try {
        final response = await _dio.get<dynamic>(
          topRated ? 'photographers/top-rated' : 'photographers',
          queryParameters: query,
        );
        final page = _map(response.data);
        final rawItems = page['items'];
        if (rawItems is! List) {
          throw const ApiException(
            'Backend trả về danh sách photographer không hợp lệ.',
          );
        }
        final basePhotographers = rawItems
            .map((item) => photographerFromApi(_map(item), topRated: topRated))
            .toList();

        final items = await Future.wait(
          basePhotographers.map(
            (p) => PhotographerCoverResolver.resolveWithCover(_dio, p),
          ),
        );

        return PhotographerPage(
          items: items,
          total: _number(page['total']),
          limit: _number(page['limit'], fallback: limit),
          offset: _number(page['offset'], fallback: offset),
        );
      } on DioException catch (error) {
        throw ApiException.fromDio(error);
      }
    }

    // Filter/Search path:
    // To handle Vietnamese unaccented search ("minh khoi" vs "Minh Khôi") and style mappings accurately
    // without being blocked by backend ILIKE limitations, we fetch all photographers (limit: 100) and perform
    // comprehensive diacritic-insensitive & style-aware matching.
    try {
      final query = <String, Object>{'limit': 100, 'offset': 0};
      final response = await _dio.get<dynamic>(
        'photographers',
        queryParameters: query,
      );
      final page = _map(response.data);
      final rawItems = page['items'];
      if (rawItems is! List) {
        throw const ApiException(
          'Backend trả về danh sách photographer không hợp lệ.',
        );
      }
      final allPhotographers = rawItems
          .map((item) => photographerFromApi(_map(item), topRated: false))
          .toList();

      final filtered = allPhotographers.where((p) {
        // Location filter
        if (hasLocation) {
          if (!foldVietnamese(p.city).contains(foldVietnamese(location))) {
            return false;
          }
        }
        // Rating filter
        if (hasRating && p.rating < minRating) {
          return false;
        }
        // Style filter
        if (hasStyle) {
          final targetSlugs = _mapStyleToSlugs(style);
          final hasMatchingStyle = p.styles.any((s) {
            final sLower = s.toLowerCase();
            return targetSlugs.any((target) => sLower.contains(target));
          });
          if (!hasMatchingStyle) return false;
        }
        // Search query (keyword)
        if (hasKeyword) {
          final q = foldVietnamese(rawKeyword.toLowerCase());
          final nameMatch = foldVietnamese(p.name.toLowerCase()).contains(q);
          final cityMatch = foldVietnamese(p.city.toLowerCase()).contains(q);
          final targetSlugs = _mapStyleToSlugs(rawKeyword);
          final styleMatch = p.styles.any((s) {
            final sLower = s.toLowerCase();
            final sFolded = foldVietnamese(sLower);
            return sFolded.contains(q) ||
                targetSlugs.any((target) => sLower.contains(target));
          });
          if (!nameMatch && !cityMatch && !styleMatch) {
            return false;
          }
        }
        return true;
      }).toList();

      final total = filtered.length;
      final start = offset.clamp(0, total);
      final end = (offset + limit).clamp(0, total);
      final pageItems = filtered.sublist(start, end);

      final items = await Future.wait(
        pageItems.map(
          (p) => PhotographerCoverResolver.resolveWithCover(_dio, p),
        ),
      );

      return PhotographerPage(
        items: items,
        total: total,
        limit: limit,
        offset: offset,
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
  final id = _requiredString(json['id'], 'id');
  final directCover =
      (json['cover_image_url'] ?? json['cover_url'])?.toString().trim() ?? '';
  final cachedCover = PhotographerCoverResolver.getCachedCover(id);
  final cover = directCover.isNotEmpty
      ? directCover
      : (cachedCover != null && cachedCover.isNotEmpty ? cachedCover : '');

  return PhotographerModel(
    id: id,
    name: _requiredString(json['fullname'], 'fullname'),
    avatarUrl: json['avatar_url']?.toString() ?? '',
    coverImageUrl: cover,
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
