import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/core/network/auth_session_store.dart';
import 'package:lens_app/data/repositories/api_auth_repository.dart';
import 'package:lens_app/data/repositories/api_customer_notification_preferences_repository.dart';
import 'package:lens_app/data/repositories/api_customer_reviews_repository.dart';
import 'package:lens_app/features/customer/discovery/models/filter_criteria.dart';
import 'package:lens_app/features/customer/discovery/repositories/api_photographer_repository.dart';
import 'package:lens_app/features/customer/discovery/repositories/customer_recommendations_repository.dart';
import 'package:lens_app/features/customer/bookings/repositories/api_booking_repository.dart';

const _baseUrl = 'https://api.example.test/api/v1/';

void main() {
  test('authenticates a customer from the Backend response envelope', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((options) async {
      request = options;
      return _jsonResponse(200, {
        'success': true,
        'statusCode': 200,
        'data': {
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'expires_in': 900,
          'user': {
            'id': 'customer-1',
            'fullname': 'Khách Lens',
            'email': 'customer@example.test',
            'role': 'customer',
          },
        },
        'timestamp': '2026-10-23T00:00:00.000Z',
      });
    });

    final user = await ApiAuthRepository(
      dio,
      store,
    ).login(email: ' customer@example.test ', password: 'password-1');

    expect(request?.uri.path, '/api/v1/auth/login');
    expect(request?.data, {
      'email': 'customer@example.test',
      'password': 'password-1',
    });
    expect(user.id, 'customer-1');
    expect(store.accessToken, 'access-1');
    expect(store.refreshToken, 'refresh-1');
  });

  test(
    'applies discovery search, location, and rating filters over Backend pages',
    () async {
      RequestOptions? request;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((options) async {
        request = options;
        return _jsonResponse(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'items': [
              {
                'id': 'photographer-1',
                'fullname': 'Nguyễn An',
                'location': 'Hà Nội',
                'styles': ['portrait'],
                'starting_price': 950000,
                'started_career_at': 2020,
                'rating': {'average_rating': 4.8, 'total_feedbacks': 12},
                'cover_image_url': 'https://cdn.example.test/an.jpg',
              },
            ],
            'total': 1,
            'limit': 100,
            'offset': 0,
          },
          'timestamp': '2026-10-23T00:00:00.000Z',
        });
      });

      final page = await ApiPhotographerRepository(dio).getPhotographersPage(
        criteria: FilterCriteria(
          city: 'Hà Nội',
          minRating: 4.5,
          searchQuery: 'An',
        ),
        limit: 9,
        offset: 0,
      );

      expect(request?.method, 'GET');
      expect(request?.uri.path, '/api/v1/photographers');
      expect(request?.queryParameters, {
        'limit': 100,
        'offset': 0,
        'location': 'Hà Nội',
        'min_rating': 4.5,
      });
      expect(page.total, 1);
      expect(page.offset, 0);
      expect(page.items.single.name, 'Nguyễn An');
      expect(page.items.single.pricePerSession, 950000);
      expect(page.items.single.styles, ['Chân dung']);
    },
  );

  test(
    'applies multi-style, price, experience, and sort filters locally',
    () async {
      RequestOptions? request;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((options) async {
        request = options;
        return _jsonResponse(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'items': [
              {
                'id': 'portrait-1',
                'fullname': 'An Studio',
                'location': 'Hà Nội',
                'styles': ['portrait'],
                'starting_price': 900000,
                'started_career_at': 2018,
                'rating': {'average_rating': 4.7, 'total_feedbacks': 12},
                'cover_image_url': 'https://cdn.example.test/an.jpg',
              },
              {
                'id': 'wedding-1',
                'fullname': 'Mai Studio',
                'location': 'Đà Nẵng',
                'styles': ['wedding'],
                'starting_price': 700000,
                'started_career_at': 2019,
                'rating': {'average_rating': 4.9, 'total_feedbacks': 18},
                'cover_image_url': 'https://cdn.example.test/mai.jpg',
              },
              {
                'id': 'new-portrait',
                'fullname': 'New Studio',
                'location': 'Hà Nội',
                'styles': ['portrait'],
                'starting_price': 350000,
                'started_career_at': 2024,
                'rating': {'average_rating': 4.6, 'total_feedbacks': 2},
                'cover_image_url': 'https://cdn.example.test/new.jpg',
              },
            ],
            'total': 3,
            'limit': 100,
            'offset': 0,
          },
          'timestamp': '2026-10-23T00:00:00.000Z',
        });
      });

      final page = await ApiPhotographerRepository(dio).getPhotographersPage(
        criteria: FilterCriteria(
          styles: ['Chân dung', 'Cưới'],
          priceMin: 100000,
          priceMax: 1000000,
          experienceBucket: '5+',
          sort: 'price-asc',
        ),
        limit: 9,
        offset: 0,
      );

      expect(request?.queryParameters, {'limit': 100, 'offset': 0});
      expect(page.total, 2);
      expect(page.items.map((item) => item.id), ['wedding-1', 'portrait-1']);
    },
  );

  test('loads customer recommendations from the Backend envelope', () async {
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((options) async {
      request = options;
      return _jsonResponse(200, {
        'success': true,
        'statusCode': 200,
        'data': {
          'items': [
            {
              'id': 'photographer-2',
              'fullname': 'Mai Studio',
              'location': 'Đà Nẵng',
              'styles': ['wedding'],
              'rating': {'average_rating': 4.9, 'total_feedbacks': 8},
              'cover_image_url': 'https://cdn.example.test/mai.jpg',
            },
          ],
          'total': 1,
          'limit': 6,
          'offset': 0,
        },
        'timestamp': '2026-10-23T00:00:00.000Z',
      });
    });

    final recommendations = await CustomerRecommendationsRepository(dio)
        .getRecommendations();

    expect(request?.uri.path, '/api/v1/customers/me/recommendations');
    expect(request?.queryParameters, {'limit': 6, 'offset': 0});
    expect(recommendations.single.id, 'photographer-2');
    expect(recommendations.single.name, 'Mai Studio');
    expect(recommendations.single.rating, 4.9);
  });

  test('loads a booking cancellation preview from the Backend', () async {
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((options) async {
      request = options;
      return _jsonResponse(200, {
        'success': true,
        'statusCode': 200,
        'data': {
          'booking_id': 'booking-1',
          'refundable_amount_vnd': 250000,
          'refund_requires_admin_review': true,
        },
        'timestamp': '2026-10-23T00:00:00.000Z',
      });
    });

    final preview = await ApiBookingRepository(dio)
        .getCancellationPreview('booking-1');

    expect(request?.method, 'GET');
    expect(
      request?.uri.path,
      '/api/v1/bookings/booking-1/cancellation-preview',
    );
    expect(preview.bookingId, 'booking-1');
    expect(preview.refundableAmountVnd, 250000);
    expect(preview.refundRequiresAdminReview, isTrue);
  });

  test(
    'loads the persisted customer review history with Backend pagination',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((options) async {
        requests.add(options);
        return _jsonResponse(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'items': [
              {
                'id': 'review-1',
                'booking_id': 'booking-1',
                'photographer_id': 'photographer-1',
                'rating': 5,
                'punctuality_rating': 4,
                'attitude_rating': 5,
                'comment': 'Buổi chụp rất tốt.',
                'created_at': '2026-10-20T05:00:00.000Z',
                'status': 'visible',
              },
            ],
            'total': 1,
            'limit': 100,
            'offset': 0,
          },
        });
      });

      final reviews = await ApiCustomerReviewsRepository(dio).getMyReviews();

      expect(requests.single.uri.path, '/api/v1/customers/me/reviews');
      expect(requests.single.queryParameters, {'limit': 100, 'offset': 0});
      expect(reviews, hasLength(1));
      expect(reviews.single.bookingId, 'booking-1');
      expect(reviews.single.photographerId, 'photographer-1');
      expect(reviews.single.punctualityRating, 4);
      expect(reviews.single.comment, 'Buổi chụp rất tốt.');
    },
  );

  test(
    'reads and updates persisted customer notification preferences',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((options) async {
        requests.add(options);
        if (options.method == 'GET') {
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'id': 'customer-1',
              'notification_preferences': {
                'booking_updates': false,
                'messages': true,
                'promotions': true,
                'email_digest': false,
              },
            },
          });
        }
        return _jsonResponse(200, {'success': true, 'data': {}});
      });
      final repository = ApiCustomerNotificationPreferencesRepository(dio);

      final current = await repository.getPreferences();
      final updated = current.copyWith(emailDigest: true, promotions: false);
      await repository.updatePreferences(updated);

      expect(current.bookingUpdates, isFalse);
      expect(current.messages, isTrue);
      expect(requests.last.method, 'PATCH');
      expect(requests.last.uri.path, '/api/v1/users/me');
      expect(requests.last.data, {
        'notification_preferences': {
          'booking_updates': false,
          'messages': true,
          'promotions': false,
          'email_digest': true,
        },
      });
    },
  );

  test(
    'uploads and saves a customer avatar through Backend media APIs',
    () async {
      final directory = await Directory.systemTemp.createTemp('lens-avatar-');
      final image = File('${directory.path}/profile.jpg');
      await image.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);

      final sessionStorage = _MemorySessionStorage();
      final sessionStore = AuthSessionStore(storage: sessionStorage);
      await sessionStore.save(_customerSession());
      final requests = <RequestOptions>[];
      final apiDio = Dio(BaseOptions(baseUrl: _baseUrl));
      apiDio.httpClientAdapter = _Adapter((options) async {
        requests.add(options);
        if (options.uri.path.endsWith('/media/upload-url')) {
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'media': {'id': 'media-1'},
              'upload_url': 'https://storage.example.test/signed-upload',
              'expires_in': 900,
            },
          });
        }
        if (options.uri.path.endsWith('/media/complete-upload')) {
          return _jsonResponse(200, {'success': true, 'data': {}});
        }
        if (options.uri.path.endsWith('/media/media-1')) {
          return _jsonResponse(200, {
            'success': true,
            'data': {
              'id': 'media-1',
              'status': 'ready',
              'preview_url': 'https://cdn.example.test/customer.jpg',
            },
          });
        }
        if (options.uri.path.endsWith('/users/me')) {
          expect(options.method, 'PATCH');
          expect(options.data, {
            'avatar_url': 'https://cdn.example.test/customer.jpg',
          });
          return _jsonResponse(200, {'success': true, 'data': {}});
        }
        throw StateError('Unexpected API request ${options.uri}');
      });
      final storageDio = Dio();
      storageDio.httpClientAdapter = _Adapter((options) async {
        expect(options.method, 'PUT');
        expect(
          options.uri.toString(),
          'https://storage.example.test/signed-upload',
        );
        expect(options.headers['Content-Type'], 'image/jpeg');
        expect(options.data, Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]));
        return ResponseBody.fromString('', 200);
      });

      try {
        final repository = ApiAuthRepository(
          apiDio,
          sessionStore,
          uploadDio: storageDio,
        );
        final updatedUser = await repository.updateAvatar(image.path);

        expect(updatedUser.avatarUrl, 'https://cdn.example.test/customer.jpg');
        expect(sessionStore.session?.user.avatarUrl, updatedUser.avatarUrl);
        expect(requests.map((request) => request.method), [
          'POST',
          'POST',
          'GET',
          'PATCH',
        ]);
        expect(requests.first.data, {
          'content_type': 'image/jpeg',
          'file_size': 4,
          'visibility': 'public',
        });
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

AuthSessionData _customerSession() => AuthSessionData.fromApiJson({
  'access_token': 'access-token',
  'refresh_token': 'refresh-token',
  'expires_in': 900,
  'user': {
    'id': 'customer-1',
    'fullname': 'Khách Lens',
    'email': 'customer@example.test',
    'role': 'customer',
  },
});

ResponseBody _jsonResponse(int status, Object payload) =>
    ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions request) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}
