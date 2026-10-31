import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/core/network/api_config.dart';
import 'package:lens_app/core/network/auth_session_store.dart';
import 'package:lens_app/core/network/session_interceptor.dart';
import 'package:lens_app/data/repositories/api_auth_repository.dart';
import 'package:lens_app/data/repositories/api_customer_reviews_repository.dart';
import 'package:lens_app/data/repositories/api_customer_wallet_repository.dart';

const _baseUrl = 'https://api.example.test/v1/';

void main() {
  group('API runtime configuration', () {
    test('uses the deployed API base URL by default', () {
      expect(
        const ApiConfig().requireBaseUrl(),
        'https://api.lens.id.vn/api/v1/',
      );
    });

    test('preserves a configured API prefix and appends a trailing slash', () {
      expect(
        ApiConfig(baseUrl: 'https://api.example.test/v1').requireBaseUrl(),
        _baseUrl,
      );
    });

    test('rejects missing, insecure remote, and credential-bearing URLs', () {
      expect(
        () => const ApiConfig(baseUrl: '').requireBaseUrl(),
        throwsA(isA<ApiConfigurationException>()),
      );
      expect(
        () => ApiConfig(baseUrl: 'http://api.example.test').requireBaseUrl(),
        throwsA(isA<ApiConfigurationException>()),
      );
      expect(
        () =>
            ApiConfig(baseUrl: 'https://user:secret@api.example.test')
                .requireBaseUrl(),
        throwsA(isA<ApiConfigurationException>()),
      );
    });
  });

  test('restores and deletes the persisted session', () async {
    final storage = _MemorySessionStorage();
    final firstStore = AuthSessionStore(storage: storage);
    await firstStore.save(_customerSession());

    final restoredStore = AuthSessionStore(storage: storage);
    await restoredStore.restore();
    expect(restoredStore.accessToken, 'access-1');
    expect(restoredStore.refreshToken, 'refresh-1');
    expect(restoredStore.session?.user.name, 'Khách Lens');
    expect(restoredStore.session?.user.gender, 'female');
    expect(restoredStore.session?.user.dateOfBirth, '1990-01-02');

    await restoredStore.clear();
    expect(AuthSessionStore(storage: storage).session, isNull);
    expect(storage.values, isEmpty);
  });

  test(
    'reads the authenticated customer profile from both profile APIs',
    () async {
      final storage = _MemorySessionStorage();
      final store = AuthSessionStore(storage: storage);
      await store.save(_customerSession());
      final paths = <String>{};
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        paths.add(request.uri.path);
        expect(request.headers['Authorization'], 'Bearer access-1');
        if (request.uri.path == '/v1/users/me') {
          return _response(200, {
            'id': 'customer-1',
            'fullname': 'Nguyễn An',
            'email': 'an@example.test',
            'phone_number': '0901234567',
            'gender': 'female',
            'dob': '1990-01-02',
            'avatar_url': 'https://cdn.example.test/an.jpg',
          });
        }
        if (request.uri.path == '/v1/customers/me') {
          return _response(200, {
            'id': 'customer-profile-1',
            'user_id': 'customer-1',
            'location': 'Đà Nẵng',
          });
        }
        throw StateError('Unexpected request ${request.uri}');
      });
      dio.interceptors.add(
        SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
      );

      final user = await ApiAuthRepository(dio, store).readCurrentProfile();

      expect(paths, {'/v1/users/me', '/v1/customers/me'});
      expect(user.name, 'Nguyễn An');
      expect(user.email, 'an@example.test');
      expect(user.phone, '0901234567');
      expect(user.gender, 'female');
      expect(user.dateOfBirth, '1990-01-02');
      expect(user.avatarUrl, 'https://cdn.example.test/an.jpg');
      expect(user.city, 'Đà Nẵng');
      expect(store.session?.user.city, 'Đà Nẵng');
    },
  );

  test('updates only Backend-supported customer profile fields', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_customerSession());
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer access-1');
      if (request.uri.path == '/v1/users/me') {
        expect(request.data, {
          'fullname': 'Nguyễn An',
          'phone_number': '0901234567',
          'gender': 'male',
          'dob': '1991-02-03',
        });
      } else if (request.uri.path == '/v1/customers/me') {
        expect(request.data, {'location': 'Hà Nội'});
      } else {
        throw StateError('Unexpected request ${request.uri}');
      }
      return _response(200, {'success': true});
    });
    dio.interceptors.add(
      SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
    );

    final user = await ApiAuthRepository(dio, store).updateProfile(
      name: ' Nguyễn An ',
      phone: '0901234567',
      city: 'Hà Nội',
      address: '',
      gender: 'male',
      dateOfBirth: '1991-02-03',
    );

    expect(user.name, 'Nguyễn An');
    expect(user.phone, '0901234567');
    expect(user.city, 'Hà Nội');
    expect(user.gender, 'male');
    expect(user.dateOfBirth, '1991-02-03');
    expect(requests.map((request) => request.uri.path), [
      '/v1/users/me',
      '/v1/customers/me',
    ]);
  });

  test('loads wallet balance and paginated ledger from Backend', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      if (request.uri.path == '/v1/wallet') {
        return _response(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'id': 'wallet-1',
            'balance': '125000.00',
            'frozen_balance': 35000,
          },
          'timestamp': '2026-10-10T01:00:00.000Z',
        });
      }
      if (request.uri.path == '/v1/wallet/ledger') {
        return _response(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'items': [
              {
                'id': 'ledger-1',
                'entry_type': 'booking_escrow_hold',
                'available_delta': 0,
                'frozen_delta': 35000,
                'description': 'Giữ tiền booking',
                'created_at': '2026-10-10T01:00:00.000Z',
                'transaction': {
                  'transaction_code': 'txn-booking-1',
                  'status': 'paid',
                  'payment_gateway': 'payos',
                },
                'booking': {
                  'id': '123e4567-e89b-42d3-a456-426614174000',
                  'status': 'accepted',
                  'from': '2026-10-20T02:00:00.000Z',
                  'to': '2026-10-20T04:00:00.000Z',
                  'package_name': 'Gói chân dung',
                },
              },
            ],
            'total': 1,
            'limit': 100,
            'offset': 0,
          },
          'timestamp': '2026-10-10T01:00:00.000Z',
        });
      }
      throw StateError('Unexpected request ${request.uri}');
    });

    final wallet = await ApiCustomerWalletRepository(dio).getWallet();

    expect(wallet.availableBalance, 125000);
    expect(wallet.frozenBalance, 35000);
    expect(wallet.transactions, hasLength(1));
    expect(wallet.transactions.single.availableDelta, 0);
    expect(wallet.transactions.single.frozenDelta, 35000);
    expect(
      wallet.transactions.single.bookingId,
      '123e4567-e89b-42d3-a456-426614174000',
    );
    expect(wallet.transactions.single.transactionCode, 'txn-booking-1');
    expect(wallet.transactions.single.paymentGateway, 'payos');
    expect(wallet.transactions.single.bookingPackageName, 'Gói chân dung');
    expect(requests.map((request) => request.uri.path), [
      '/v1/wallet',
      '/v1/wallet/ledger',
    ]);
    expect(requests.last.queryParameters, {'limit': 100, 'offset': 0});
  });

  test(
    'requests a wallet withdrawal using the saved payout destination',
    () async {
      RequestOptions? request;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((options) async {
        request = options;
        return _response(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'id': 'withdrawal-1',
            'amount': 50000,
            'status': 'requested',
          },
          'timestamp': '2026-10-10T01:00:00.000Z',
        });
      });

      final result = await ApiCustomerWalletRepository(dio).requestWithdrawal(
        amount: 50000,
        reason: '  Cần rút tiền  ',
        idempotencyKey: 'withdrawal-attempt-1',
      );

      expect(request?.method, 'POST');
      expect(request?.uri.path, '/v1/wallet/withdrawals');
      expect(request?.data, {
        'amount': 50000,
        'reason': 'Cần rút tiền',
        'idempotency_key': 'withdrawal-attempt-1',
      });
      expect(result.id, 'withdrawal-1');
      expect(result.amount, 50000);
      expect(result.status, 'requested');
    },
  );

  test('loads and saves the masked wallet payout destination', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((options) async {
      requests.add(options);
      return _response(200, {
        'success': true,
        'statusCode': 200,
        'data': {
          'is_configured': true,
          'bank_code': '970422',
          'account_name': 'Nguyễn An',
          'account_number_masked': '••••6789',
          'updated_at': '2026-10-10T01:00:00.000Z',
        },
        'timestamp': '2026-10-10T01:00:00.000Z',
      });
    });

    final repository = ApiCustomerWalletRepository(dio);
    final existing = await repository.getPayoutDestination();
    final saved = await repository.savePayoutDestination(
      bankCode: ' 970422 ',
      accountNumber: ' 0123456789 ',
      accountName: ' Nguyễn An ',
    );

    expect(existing.isConfigured, isTrue);
    expect(existing.accountNumberMasked, '••••6789');
    expect(saved.accountName, 'Nguyễn An');
    expect(requests.map((request) => request.method), ['GET', 'PUT']);
    expect(requests.map((request) => request.uri.path), [
      '/v1/wallet/payout-destination',
      '/v1/wallet/payout-destination',
    ]);
    expect(requests.last.data, {
      'bank_code': '970422',
      'account_number': '0123456789',
      'account_name': 'Nguyễn An',
    });
  });

  test('creates a review with the exact Backend request fields', () async {
    final bookingId = '123e4567-e89b-42d3-a456-426614174000';
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      return _response(200, {
        'id': 'review-uuid',
        'booking_id': bookingId,
        'photographer_id': 'photographer-uuid',
        'rating': 4,
        'punctuality_rating': 5,
        'attitude_rating': 3,
        'comment': null,
        'created_at': '2026-10-10T01:00:00.000Z',
      });
    });

    final review = await ApiCustomerReviewsRepository(dio).submitReview(
      bookingId: bookingId,
      photographerId: 'photographer-uuid',
      photographerName: 'Nhiếp ảnh gia',
      photographerAvatar: '',
      style: '',
      date: '2026-10-09',
      rating: 4,
      punctualityRating: 5,
      attitudeRating: 3,
      comment: '',
    );

    expect(requests.single.method, 'POST');
    expect(requests.single.uri.path, '/v1/bookings/$bookingId/reviews');
    expect(requests.single.data, {
      'rating': 4,
      'punctuality_rating': 5,
      'attitude_rating': 3,
    });
    expect(review.bookingId, bookingId);
    expect(review.rating, 4);
    expect(review.comment, isEmpty);
  });

  test(
    'serializes concurrent GET refreshes and retries with rotated token',
    () async {
      final store = AuthSessionStore(storage: _MemorySessionStorage());
      await store.save(_customerSession());
      var refreshCalls = 0;
      var resourceCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        resourceCalls++;
        if (request.headers['Authorization'] == 'Bearer access-1') {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _response(401, {'message': 'expired'});
        }
        if (request.headers['Authorization'] == 'Bearer access-2') {
          return _response(200, {'ok': true});
        }
        return _response(401, {'message': 'missing token'});
      });

      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      refreshDio.httpClientAdapter = _Adapter((request) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _response(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 1200,
            'scope': 'api',
            'token_type': 'Bearer',
          },
          'timestamp': '2026-10-10T01:00:00.000Z',
        });
      });
      dio.interceptors.add(
        SessionInterceptor(
          dio: dio,
          baseUrl: _baseUrl,
          sessionStore: store,
          refreshDio: refreshDio,
        ),
      );

      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>('private'),
        dio.get<Map<String, dynamic>>('private'),
      ]);

      expect(responses.map((response) => response.data?['ok']), [true, true]);
      expect(resourceCalls, 4);
      expect(refreshCalls, 1);
      expect(store.accessToken, 'access-2');
      expect(store.refreshToken, 'refresh-2');
    },
  );

  test(
    'reuses the rotated token for a late 401 without refreshing again',
    () async {
      final store = AuthSessionStore(storage: _MemorySessionStorage());
      await store.save(_customerSession());
      var refreshCalls = 0;
      var resourceCalls = 0;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        resourceCalls++;
        if (request.headers['Authorization'] == 'Bearer access-1') {
          if (resourceCalls == 2) {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          return _response(401, {'message': 'expired'});
        }
        if (request.headers['Authorization'] == 'Bearer access-2') {
          return _response(200, {'ok': true});
        }
        return _response(401, {'message': 'missing token'});
      });
      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      refreshDio.httpClientAdapter = _Adapter((request) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _response(200, {
          'success': true,
          'statusCode': 200,
          'data': {
            'access_token': 'access-2',
            'refresh_token': 'refresh-2',
            'expires_in': 1200,
          },
          'timestamp': '2026-10-10T01:00:00.000Z',
        });
      });
      dio.interceptors.add(
        SessionInterceptor(
          dio: dio,
          baseUrl: _baseUrl,
          sessionStore: store,
          refreshDio: refreshDio,
        ),
      );

      final responses = await Future.wait([
        dio.get<Map<String, dynamic>>('private'),
        dio.get<Map<String, dynamic>>('private'),
      ]);

      expect(responses.map((response) => response.data?['ok']), [true, true]);
      expect(resourceCalls, 4);
      expect(refreshCalls, 1);
      expect(store.accessToken, 'access-2');
    },
  );

  test('refreshes a 401 write but never replays the write', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_customerSession());
    var refreshCalls = 0;
    var writeCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      writeCalls++;
      return _response(401, {'message': 'expired'});
    });
    final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
    refreshDio.httpClientAdapter = _Adapter((request) async {
      refreshCalls++;
      return _response(200, {
        'success': true,
        'statusCode': 200,
        'data': {
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'expires_in': 1200,
        },
        'timestamp': '2026-10-10T01:00:00.000Z',
      });
    });
    dio.interceptors.add(
      SessionInterceptor(
        dio: dio,
        baseUrl: _baseUrl,
        sessionStore: store,
        refreshDio: refreshDio,
      ),
    );

    await expectLater(
      dio.post<void>('private', data: {'value': 1}),
      throwsA(isA<DioException>()),
    );
    expect(writeCalls, 1);
    expect(refreshCalls, 1);
    expect(store.accessToken, 'access-2');
  });

  test('does not refresh or clear a session for 403', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_customerSession());
    var refreshCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter(
      (_) async => _response(403, {'message': 'forbidden'}),
    );
    final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
    refreshDio.httpClientAdapter = _Adapter((_) async {
      refreshCalls++;
      return _response(500, {});
    });
    dio.interceptors.add(
      SessionInterceptor(
        dio: dio,
        baseUrl: _baseUrl,
        sessionStore: store,
        refreshDio: refreshDio,
      ),
    );

    await expectLater(dio.get<void>('private'), throwsA(isA<DioException>()));
    expect(refreshCalls, 0);
    expect(store.accessToken, 'access-1');
  });

  test('keeps a session when refresh fails temporarily', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_customerSession());
    var expirationEvents = 0;
    store.onSessionExpired = () => expirationEvents++;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter(
      (_) async => _response(401, {'message': 'expired'}),
    );
    final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
    refreshDio.httpClientAdapter = _Adapter(
      (_) async => _response(503, {'message': 'temporarily unavailable'}),
    );
    dio.interceptors.add(
      SessionInterceptor(
        dio: dio,
        baseUrl: _baseUrl,
        sessionStore: store,
        refreshDio: refreshDio,
      ),
    );

    await expectLater(dio.get<void>('private'), throwsA(isA<DioException>()));
    expect(store.accessToken, 'access-1');
    expect(expirationEvents, 0);
  });

  test('clears a session when refresh is rejected with 401 or 403', () async {
    for (final statusCode in [401, 403]) {
      final store = AuthSessionStore(storage: _MemorySessionStorage());
      await store.save(_customerSession());
      var expirationEvents = 0;
      store.onSessionExpired = () => expirationEvents++;
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter(
        (_) async => _response(401, {'message': 'expired'}),
      );
      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      refreshDio.httpClientAdapter = _Adapter(
        (_) async => _response(statusCode, {'message': 'invalid refresh'}),
      );
      dio.interceptors.add(
        SessionInterceptor(
          dio: dio,
          baseUrl: _baseUrl,
          sessionStore: store,
          refreshDio: refreshDio,
        ),
      );

      await expectLater(dio.get<void>('private'), throwsA(isA<DioException>()));
      expect(store.session, isNull);
      expect(expirationEvents, 1);
    }
  });

  test('notifies auth state when a 401 has no refresh token', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    var expirationEvents = 0;
    store.onSessionExpired = () => expirationEvents++;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter(
      (_) async => _response(401, {'message': 'unauthorized'}),
    );
    dio.interceptors.add(
      SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
    );

    await expectLater(dio.get<void>('private'), throwsA(isA<DioException>()));
    expect(expirationEvents, 1);
    expect(store.session, isNull);
  });

  test('does not attach a stale bearer token to login requests', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_customerSession());
    String? sentAuthorization;
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      sentAuthorization = request.headers['Authorization'] as String?;
      return _response(401, {'message': 'bad credentials'});
    });
    dio.interceptors.add(
      SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
    );

    await expectLater(
      dio.post<void>('auth/login', data: {'email': 'x'}),
      throwsA(isA<DioException>()),
    );
    expect(sentAuthorization, isNull);
    expect(store.accessToken, 'access-1');
  });
}

AuthSessionData _customerSession() => AuthSessionData.fromApiJson({
  'access_token': 'access-1',
  'refresh_token': 'refresh-1',
  'expires_in': 900,
  'user': {
    'id': 'customer-1',
    'fullname': 'Khách Lens',
    'email': 'customer@example.test',
    'phone_number': '0900000000',
    'role': 'customer',
    'gender': 'female',
    'dob': '1990-01-02',
  },
});

ResponseBody _response(int statusCode, Object payload) =>
    ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
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
