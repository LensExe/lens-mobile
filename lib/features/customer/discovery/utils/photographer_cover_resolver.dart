import 'package:dio/dio.dart';

import '../models/photographer_model.dart';

/// Helper to resolve and cache photographer cover/showcase images.
///
/// Because backend `GET /photographers` only returns basic user information
/// and avatar_url without cover image URLs, this resolver fetches the
/// photographer's primary portfolio cover image and caches it.
class PhotographerCoverResolver {
  static final Map<String, String> _coverCache = {};

  /// Clear the cache (e.g. for testing)
  static void clearCache() => _coverCache.clear();

  /// Manually cache a cover URL for a given photographer ID.
  static void setCachedCover(String photographerId, String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isNotEmpty) {
      _coverCache[photographerId] = cleanUrl;
    }
  }

  /// Get the cached cover URL if available.
  static String? getCachedCover(String photographerId) =>
      _coverCache[photographerId];

  /// Attempts to fetch the cover URL for a photographer from their portfolios.
  static Future<String> fetchCoverUrl(Dio dio, String photographerId) async {
    final cached = _coverCache[photographerId];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final portfolioRes = await dio.get<dynamic>(
        'photographers/$photographerId/portfolios',
        queryParameters: const {'limit': 1, 'offset': 0},
      ).timeout(const Duration(seconds: 4));

      final portfolioData = portfolioRes.data;
      if (portfolioData is Map) {
        final items = portfolioData['items'];
        if (items is List && items.isNotEmpty) {
          final firstPortfolio = items.first;
          if (firstPortfolio is Map) {
            final portfolioId = firstPortfolio['id']?.toString() ?? '';
            if (portfolioId.isNotEmpty) {
              final detailRes = await dio.get<dynamic>(
                'portfolios/$portfolioId',
              ).timeout(const Duration(seconds: 4));

              final detail = detailRes.data;
              if (detail is Map) {
                var cover = detail['cover_url']?.toString().trim() ?? '';
                if (cover.isEmpty) {
                  final mediaItems = detail['items'];
                  if (mediaItems is List && mediaItems.isNotEmpty) {
                    final firstItem = mediaItems.first;
                    if (firstItem is Map) {
                      cover = firstItem['download_url']?.toString().trim() ?? '';
                    }
                  }
                }
                if (cover.isNotEmpty) {
                  _coverCache[photographerId] = cover;
                  return cover;
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // Gracefully ignore network or timeout errors
    }
    return '';
  }

  /// Resolves the cover image for a photographer model.
  /// If [coverImageUrl] is already non-empty, returns as-is.
  /// Otherwise attempts to fetch from their portfolio, and if still empty,
  /// falls back to their [avatarUrl].
  static Future<PhotographerModel> resolveWithCover(
    Dio dio,
    PhotographerModel photographer,
  ) async {
    if (photographer.coverImageUrl.isNotEmpty) {
      setCachedCover(photographer.id, photographer.coverImageUrl);
      return photographer;
    }

    final cover = await fetchCoverUrl(dio, photographer.id);
    if (cover.isNotEmpty) {
      return photographer.copyWith(coverImageUrl: cover);
    }

    if (photographer.avatarUrl.isNotEmpty) {
      return photographer.copyWith(coverImageUrl: photographer.avatarUrl);
    }

    return photographer;
  }
}
