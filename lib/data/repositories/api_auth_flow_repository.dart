import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_session_store.dart';
import '../../domain/models/models.dart';

/// Auth endpoints that are not part of the normal sign-in/session lifecycle.
class ApiAuthFlowRepository {
  ApiAuthFlowRepository(
    this._dio,
    this._sessionStore, {
    required this.expectedRole,
  });

  final Dio _dio;
  final AuthSessionStore _sessionStore;
  final String expectedRole;

  Future<String> sendForgotPasswordOtp(String email) async =>
      _postMessage('auth/forgot-password/send-otp', {'email': email.trim()});

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _post('auth/forgot-password/verify', {
      'email': email.trim(),
      'otp': otp.trim(),
    });
    final token = response['reset_token'];
    if (token is! String || token.trim().isEmpty) {
      throw const ApiException('Backend không trả về reset_token hợp lệ.');
    }
    return token.trim();
  }

  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) => _postMessage('auth/forgot-password/reset', {
    'reset_token': resetToken,
    'new_password': newPassword,
    'confirm_password': confirmPassword,
  });

  Future<String> sendEmailVerificationOtp() async {
    try {
      final response = await _dio.post<dynamic>('auth/email/send-otp');
      return _message(_payload(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> verifyEmail(String otp) async {
    final email = _sessionStore.session?.user.email.trim();
    if (email == null || email.isEmpty) {
      throw const ApiException('Vui lòng đăng nhập lại để xác minh email.');
    }
    return _postMessage('auth/email/verify', {
      'email': email,
      'otp': otp.trim(),
    });
  }

  /// Starts the Backend OAuth flow. The server uses one configured frontend
  /// callback URI, so mobile cannot finish the handoff without app-specific
  /// callback routing.
  Future<Uri> getGoogleAuthorizationUrl() async {
    try {
      final response = await _dio.get<dynamic>('keycloak/google/login');
      final payload = _payload(response.data);
      final value = payload['authorization_url'];
      final uri = value is String ? Uri.tryParse(value) : null;
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const ApiException(
          'Backend không trả về authorization_url Google hợp lệ.',
        );
      }
      return uri;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Exchanges the one-time code produced by /keycloak/google/callback.
  /// Mobile can call this after receiving the handoff code. The current
  /// Backend contract does not select a callback URI per app.
  Future<User> exchangeGoogleCode(String code) async {
    try {
      final response = await _dio.get<dynamic>(
        'keycloak/google/exchange',
        queryParameters: {'code': code},
      );
      final session = AuthSessionData.fromApiJson(
        _payload(response.data),
        fallbackRole: expectedRole,
      );
      if (session.user.role != expectedRole) {
        throw ApiException(
          'Tài khoản Google này không thuộc ứng dụng ${expectedRole == 'client' ? 'khách hàng' : 'Creator'}.',
        );
      }
      await _sessionStore.save(session);
      return session.user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> _postMessage(String path, Map<String, Object?> body) async =>
      _message(await _post(path, body));

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      return _payload(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Map<String, dynamic> _payload(Object? value) {
    var result = value;
    while (result is Map && result.containsKey('data')) {
      result = result['data'];
    }
    if (result is Map<String, dynamic>) return result;
    if (result is Map) {
      return result.map((key, value) => MapEntry('$key', value));
    }
    throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
  }

  static String _message(Map<String, dynamic> payload) {
    if (payload['success'] == false) {
      final message = payload['message'];
      throw ApiException(
        message is String && message.trim().isNotEmpty
            ? message.trim()
            : 'Backend không hoàn tất yêu cầu.',
      );
    }
    final message = payload['message'];
    return message is String && message.trim().isNotEmpty
        ? message.trim()
        : 'Yêu cầu đã được Backend tiếp nhận.';
  }
}
