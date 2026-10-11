import 'dart:async';

import 'package:dio/dio.dart';

import 'auth_session_store.dart';

class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required this.dio,
    required String baseUrl,
    required this.sessionStore,
    Dio? refreshDio,
  }) : _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               sendTimeout: const Duration(seconds: 10),
               headers: const {'Accept': 'application/json'},
             ),
           );

  final Dio dio;
  final Dio _refreshDio;
  final AuthSessionStore sessionStore;
  Future<String?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _isPublicAuthRoute(options) ? null : sessionStore.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || _isPublicAuthRoute(request)) {
      handler.next(err);
      return;
    }

    final currentAccessToken = sessionStore.accessToken;
    final sentAccessToken = _accessTokenFrom(request);
    final requestTokenIsStale =
        currentAccessToken != null &&
        sentAccessToken != null &&
        sentAccessToken != currentAccessToken;

    if (request.extra['authRetried'] == true) {
      if (!requestTokenIsStale) await _clearSession();
      handler.next(err);
      return;
    }

    if (requestTokenIsStale) {
      if (request.method.toUpperCase() == 'GET') {
        request
          ..headers['Authorization'] = 'Bearer $currentAccessToken'
          ..extra['authRetried'] = true;
        handler.resolve(await dio.fetch<dynamic>(request));
        return;
      }
      handler.next(err);
      return;
    }

    if (sessionStore.refreshToken == null) {
      await _clearSession();
      handler.next(err);
      return;
    }

    try {
      final token = await (_refreshing ??= _refreshAccessToken().whenComplete(
        () => _refreshing = null,
      ));
      if (token == null) {
        await _clearSession();
        handler.next(err);
        return;
      }
      if (request.method.toUpperCase() == 'GET') {
        request
          ..headers['Authorization'] = 'Bearer $token'
          ..extra['authRetried'] = true;
        handler.resolve(await dio.fetch<dynamic>(request));
        return;
      }
      // The token is refreshed for the next user action, but writes are never replayed.
      handler.next(err);
    } on DioException catch (refreshError) {
      final refreshStatus = refreshError.response?.statusCode;
      if (refreshStatus == 401 || refreshStatus == 403) {
        await _clearSession();
      }
      handler.next(err);
    } on Object {
      await _clearSession();
      handler.next(err);
    }
  }

  Future<void> _clearSession() async {
    try {
      await sessionStore.expire();
    } on Object {
      // AuthSessionStore clears its in-memory value and notifies the auth state
      // before secure deletion can fail. Preserve the original 401.
    }
  }

  bool _isPublicAuthRoute(RequestOptions request) {
    final path = request.uri.path;
    return const [
      'login',
      'register',
      'refresh',
      'logout',
    ].any((route) => path.endsWith('/auth/$route'));
  }

  String? _accessTokenFrom(RequestOptions request) {
    final authorization = request.headers['Authorization'];
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return authorization.substring('Bearer '.length);
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = sessionStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await _refreshDio.post<dynamic>(
      'auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data;
    if (data is! Map) return null;
    final tokenData = data.map((key, value) => MapEntry('$key', value));
    await sessionStore.updateTokens(tokenData);
    return sessionStore.accessToken;
  }
}
