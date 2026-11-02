import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/features/customer/discovery/repositories/api_photographer_repository.dart';
import 'package:lens_app/features/customer/discovery/utils/photographer_cover_resolver.dart';

const _baseUrl = 'https://api.example.test/api/v1/';

void main() {
  setUp(() {
    PhotographerCoverResolver.clearCache();
  });

  test(
    'resolves portfolio cover URL for photographers in discovery feed',
    () async {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        return switch (request.uri.path) {
          '/api/v1/photographers/top-rated' ||
          '/api/v1/photographers' => _response(200, {
            'items': [
              {
                'id': 'p-1',
                'fullname': 'Nguyễn Minh Khôi',
                'avatar_url': 'https://example.com/avatar1.jpg',
                'location': 'Hà Nội',
                'rating': {'average_rating': 4.8, 'total_feedbacks': 10},
                'is_verified': true,
                'styles': ['portrait'],
              },
              {
                'id': 'p-2',
                'fullname': 'Trần Ngọc Anh',
                'avatar_url': 'https://example.com/avatar2.jpg',
                'location': 'TP. Hồ Chí Minh',
                'rating': {'average_rating': 4.9, 'total_feedbacks': 15},
                'is_verified': true,
                'styles': ['wedding'],
              },
            ],
            'total': 2,
            'limit': 9,
            'offset': 0,
          }),
          '/api/v1/photographers/p-1/portfolios' => _response(200, {
            'items': [
              {'id': 'port-1', 'photographer_id': 'p-1', 'name': 'Album 1'},
            ],
            'total': 1,
          }),
          '/api/v1/portfolios/port-1' => _response(200, {
            'id': 'port-1',
            'cover_url': 'https://example.com/portfolio-cover1.jpg',
            'items': [],
          }),
          '/api/v1/photographers/p-2/portfolios' => _response(200, {
            'items': [],
            'total': 0,
          }),
          _ => throw StateError('Unexpected request ${request.uri}'),
        };
      });

      final repository = ApiPhotographerRepository(dio);
      final page = await repository.getPhotographersPage(limit: 9, offset: 0);

      expect(page.items.length, 2);

      // p-1 has portfolio, so coverImageUrl should be the portfolio cover
      expect(page.items[0].id, 'p-1');
      expect(
        page.items[0].coverImageUrl,
        'https://example.com/portfolio-cover1.jpg',
      );
      expect(page.items[0].avatarUrl, 'https://example.com/avatar1.jpg');

      // p-2 has no portfolio, so coverImageUrl falls back to avatarUrl
      expect(page.items[1].id, 'p-2');
      expect(page.items[1].coverImageUrl, 'https://example.com/avatar2.jpg');
      expect(page.items[1].avatarUrl, 'https://example.com/avatar2.jpg');

      // Check that p-1's cover was cached
      expect(
        PhotographerCoverResolver.getCachedCover('p-1'),
        'https://example.com/portfolio-cover1.jpg',
      );
    },
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);
  final Future<ResponseBody> Function(RequestOptions) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handler(options);
}

ResponseBody _response(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
