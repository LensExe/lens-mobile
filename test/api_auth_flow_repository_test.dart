import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/core/network/auth_session_store.dart';
import 'package:lens_app/core/network/session_interceptor.dart';
import 'package:lens_app/data/repositories/api_auth_flow_repository.dart';

const _baseUrl = 'https://api.example.test/v1/';

void main() {
  test('uses the exact password recovery routes and payloads', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      return switch (request.uri.path) {
        '/v1/auth/forgot-password/send-otp' => _response(200, {
          'success': true,
          'message': 'OTP queued',
        }),
        '/v1/auth/forgot-password/verify' => _response(200, {
          'success': true,
          'data': {'reset_token': 'one-time-reset-token'},
        }),
        '/v1/auth/forgot-password/reset' => _response(200, {
          'success': true,
          'message': 'Password changed',
        }),
        _ => throw StateError('Unexpected request ${request.uri}'),
      };
    });
    final repository = ApiAuthFlowRepository(
      dio,
      AuthSessionStore(storage: _MemorySessionStorage()),
      expectedRole: 'client',
    );

    expect(
      await repository.sendForgotPasswordOtp(' customer@example.test '),
      'OTP queued',
    );
    final resetToken = await repository.verifyForgotPasswordOtp(
      email: 'customer@example.test',
      otp: '123456',
    );
    expect(resetToken, 'one-time-reset-token');
    expect(
      await repository.resetPassword(
        resetToken: resetToken,
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      ),
      'Password changed',
    );

    expect(requests.map((request) => request.method), ['POST', 'POST', 'POST']);
    expect(requests.map((request) => request.uri.path), [
      '/v1/auth/forgot-password/send-otp',
      '/v1/auth/forgot-password/verify',
      '/v1/auth/forgot-password/reset',
    ]);
    expect(requests[0].data, {'email': 'customer@example.test'});
    expect(requests[1].data, {
      'email': 'customer@example.test',
      'otp': '123456',
    });
    expect(requests[2].data, {
      'reset_token': 'one-time-reset-token',
      'new_password': 'newpass1',
      'confirm_password': 'newpass1',
    });
  });

  test(
    'email verification uses the authenticated session email and bearer',
    () async {
      final store = AuthSessionStore(storage: _MemorySessionStorage());
      await store.save(_clientSession());
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer access-client');
        return _response(200, {'success': true, 'message': 'Verified'});
      });
      dio.interceptors.add(
        SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
      );
      final repository = ApiAuthFlowRepository(
        dio,
        store,
        expectedRole: 'client',
      );

      expect(await repository.sendEmailVerificationOtp(), 'Verified');
      expect(await repository.verifyEmail('654321'), 'Verified');

      expect(requests.map((request) => request.uri.path), [
        '/v1/auth/email/send-otp',
        '/v1/auth/email/verify',
      ]);
      expect(requests.first.data, isNull);
      expect(requests.last.data, {
        'email': 'customer@example.test',
        'otp': '654321',
      });
    },
  );

  test('keeps a saved session off public password recovery requests', () async {
    final store = AuthSessionStore(storage: _MemorySessionStorage());
    await store.save(_clientSession());
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    dio.httpClientAdapter = _Adapter((request) async {
      expect(request.headers['Authorization'], isNull);
      return _response(200, {'success': true, 'message': 'OTP queued'});
    });
    dio.interceptors.add(
      SessionInterceptor(dio: dio, baseUrl: _baseUrl, sessionStore: store),
    );

    await ApiAuthFlowRepository(
      dio,
      store,
      expectedRole: 'client',
    ).sendForgotPasswordOtp('customer@example.test');
  });

  test(
    'maps Google login URL and exchange code to secure session storage',
    () async {
      final store = AuthSessionStore(storage: _MemorySessionStorage());
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.httpClientAdapter = _Adapter((request) async {
        requests.add(request);
        if (request.uri.path.endsWith('/keycloak/google/login')) {
          return _response(200, {
            'data': {
              'authorization_url': 'https://identity.example.test/authorize',
            },
          });
        }
        return _response(200, _clientSessionJson());
      });
      final repository = ApiAuthFlowRepository(
        dio,
        store,
        expectedRole: 'client',
      );

      expect(
        await repository.getGoogleAuthorizationUrl(),
        Uri.parse('https://identity.example.test/authorize'),
      );
      final user = await repository.exchangeGoogleCode('single-use-code');

      expect(requests.map((request) => request.uri.path), [
        '/v1/keycloak/google/login',
        '/v1/keycloak/google/exchange',
      ]);
      expect(requests.last.queryParameters, {'code': 'single-use-code'});
      expect(user.email, 'customer@example.test');
      expect(store.accessToken, 'access-client');
    },
  );
}

Map<String, Object?> _clientSessionJson() => {
  'access_token': 'access-client',
  'refresh_token': 'refresh-client',
  'expires_in': 900,
  'user': {
    'id': 'customer-1',
    'fullname': 'Khách Lens',
    'email': 'customer@example.test',
    'role': 'customer',
  },
};

AuthSessionData _clientSession() =>
    AuthSessionData.fromApiJson(_clientSessionJson());

ResponseBody _response(int statusCode, Object payload) =>
    ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _MemorySessionStorage implements SessionStorage {
  final values = <String, String>{};

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
