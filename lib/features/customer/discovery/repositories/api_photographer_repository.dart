import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_cover_resolver.dart';
import 'photographer_repository.dart';

const _styleLabels = <String, String>{
  'portrait': 'Chân dung',
  'vintage': 'Đường phố',
  'korean': 'Chân dung',
  'wedding': 'Cưới',
  'concept': 'Thời trang',
  'pre-wedding': 'Cưới',
  'beach': 'Du lịch',
  'lifestyle': 'Gia đình',
  'event': 'Sự kiện',
  'corporate': 'Sản phẩm',
  'family': 'Gia đình',
  'outdoor': 'Du lịch',
  'kids': 'Gia đình',
  'streetwear': 'Đường phố',
  'fashion': 'Thời trang',
  'film': 'Đường phố',
  'maternity': 'Gia đình',
  'commercial': 'Sản phẩm',
};

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
    final minRating = criteria?.minRating;

    final hasLocation =
        location != null && location.isNotEmpty && location != 'Tất cả';
    final hasRating = minRating != null;
    final hasKeyword = rawKeyword != null && rawKeyword.isNotEmpty;
    final hasFilters =
        hasLocation ||
        hasRating ||
        hasKeyword ||
        (criteria?.styles.isNotEmpty ?? false) ||
        (criteria?.hasNarrowedPriceRange ?? false) ||
        (criteria?.experienceBucket != null) ||
        (criteria?.sort != null && criteria!.sort != 'featured');

    // Fast path: Default browse without active search or filter
    if (!hasFilters) {
      final query = <String, Object>{'limit': limit, 'offset': offset};
      try {
        final response = await _dio.get<dynamic>(
          topRated ? 'photographers/top-rated' : 'photographers',
          queryParameters: query,
        );
        return await _pageFromResponse(
          response.data,
          topRated: topRated,
          fallbackLimit: limit,
          fallbackOffset: offset,
        );
      } on DioException catch (error) {
        throw ApiException.fromDio(error);
      }
    }

    // The Web directory loads the full photographer list and applies its
    // filters/sort locally. Mirror that behavior so combined filters and
    // result counts remain correct even though the list API has no style,
    // price, experience, or sort parameters.
    try {
      final serverFilters = <String, Object>{
        if (hasLocation) 'location': location,
        if (hasRating) 'min_rating': minRating,
      };

      final photographers = await _fetchAllPhotographers(serverFilters);
      final filtered = _applyLocalFilters(photographers, criteria);
      final total = filtered.length;
      final start = offset.clamp(0, total);
      final end = (offset + limit).clamp(0, total);
      final items = await _resolveCovers(filtered.sublist(start, end));
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

  List<PhotographerModel> _applyLocalFilters(
    List<PhotographerModel> photographers,
    FilterCriteria? criteria,
  ) {
    if (criteria == null) return photographers;
    final query = foldVietnamese(
      criteria.searchQuery?.trim().toLowerCase() ?? '',
    );
    final selectedStyles = criteria.styles
        .map((style) => foldVietnamese(style.trim().toLowerCase()))
        .toSet();
    final minPrice = criteria.priceMin;
    final maxPrice = criteria.priceMax;

    final filtered = photographers
        .where((photographer) {
          if (criteria.city != null &&
              criteria.city != 'Tất cả' &&
              photographer.city != criteria.city) {
            return false;
          }
          if (criteria.minRating != null &&
              photographer.rating < criteria.minRating!) {
            return false;
          }
          if (query.isNotEmpty) {
            final searchable = foldVietnamese(
              '${photographer.name} ${photographer.city} ${photographer.styles.join(' ')}'
                  .toLowerCase(),
            );
            if (!searchable.contains(query)) return false;
          }
          if (selectedStyles.isNotEmpty &&
              !photographer.styles.any(
                (style) => selectedStyles.contains(
                  foldVietnamese(style.trim().toLowerCase()),
                ),
              )) {
            return false;
          }
          if (criteria.hasNarrowedPriceRange &&
              (photographer.pricePerSession < minPrice ||
                  photographer.pricePerSession > maxPrice)) {
            return false;
          }
          if (criteria.experienceBucket != null &&
              !_matchesExperience(
                photographer.experience,
                criteria.experienceBucket!,
              )) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    final indexed = filtered.asMap().entries.toList();
    indexed.sort((left, right) {
      final a = left.value;
      final b = right.value;
      final comparison = switch (criteria.sort) {
        'rating' => b.rating.compareTo(a.rating),
        'price-asc' => a.pricePerSession.compareTo(b.pricePerSession),
        'price-desc' => b.pricePerSession.compareTo(a.pricePerSession),
        _ =>
          (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0) != 0
              ? (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0)
              : b.rating.compareTo(a.rating),
      };
      return comparison == 0 ? left.key.compareTo(right.key) : comparison;
    });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  bool _matchesExperience(Experience? experience, String bucket) {
    if (experience == null) return false;
    return switch (bucket) {
      'lt1' => experience == Experience.under1Year,
      '1-3' => experience == Experience.from1To3Years,
      '3-5' => experience == Experience.from3To5Years,
      '5+' => experience == Experience.over5Years,
      _ => true,
    };
  }

  Future<List<PhotographerModel>> _fetchAllPhotographers(
    Map<String, Object> filters,
  ) async {
    const pageSize = 100;
    final all = <PhotographerModel>[];
    var offset = 0;
    var total = 0;
    do {
      final response = await _dio.get<dynamic>(
        'photographers',
        queryParameters: {'limit': pageSize, 'offset': offset, ...filters},
      );
      final page = _mapResponse(response.data);
      final rawItems = page['items'];
      if (rawItems is! List) {
        throw const ApiException(
          'Backend trả về danh sách photographer không hợp lệ.',
        );
      }
      final items = rawItems
          .map((item) => photographerFromApi(_map(item)))
          .toList(growable: false);
      all.addAll(items);
      total = _number(page['total']);
      if (items.isEmpty) break;
      offset += items.length;
    } while (offset < total);
    return all;
  }

  Future<List<PhotographerModel>> _resolveCovers(
    List<PhotographerModel> photographers,
  ) => Future.wait(
    photographers.map(
      (photographer) =>
          PhotographerCoverResolver.resolveWithCover(_dio, photographer),
    ),
  );

  Future<PhotographerPage> _pageFromResponse(
    Object? response, {
    bool topRated = false,
    required int fallbackLimit,
    required int fallbackOffset,
  }) async {
    final page = _mapResponse(response);
    final rawItems = page['items'];
    if (rawItems is! List) {
      throw const ApiException(
        'Backend trả về danh sách photographer không hợp lệ.',
      );
    }
    final basePhotographers = rawItems
        .map((item) => photographerFromApi(_map(item), topRated: topRated))
        .toList(growable: false);
    final items = await _resolveCovers(basePhotographers);
    return PhotographerPage(
      items: items,
      total: _number(page['total']),
      limit: _number(page['limit'], fallback: fallbackLimit),
      offset: _number(page['offset'], fallback: fallbackOffset),
    );
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
  final startingPlan = json['starting_plan'] is Map
      ? _map(json['starting_plan'])
      : const <String, dynamic>{};
  final rawStartingPrice = startingPlan['price'] ?? json['starting_price'];
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
    pricePerSession: _decimal(rawStartingPrice),
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
        .map(
          (item) =>
              _styleLabels[item.toString().trim().toLowerCase()] ??
              item.toString().trim(),
        )
        .where((style) => style.isNotEmpty)
        .toSet()
        .toList(),
    availableDates: const [],
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
}

Map<String, dynamic> _mapResponse(Object? value) {
  var payload = value;
  while (payload is Map && payload.containsKey('data')) {
    if (payload['success'] == false) {
      throw const ApiException(
        'Backend không xác nhận danh sách photographer.',
      );
    }
    payload = payload['data'];
  }
  return _map(payload);
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

int _number(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : fallback;
double _decimal(Object? value) => value is num ? value.toDouble() : 0;
