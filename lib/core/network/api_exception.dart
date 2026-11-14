import 'package:dio/dio.dart';

enum AuthErrorContext { login, signup }

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(
    DioException error, {
    AuthErrorContext? authContext,
  }) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final backendMessage = body is Map ? body['message'] : null;
    final rawMessage = _messageText(backendMessage);
    return ApiException.fromMessage(
      rawMessage ?? '',
      statusCode: statusCode,
      authContext: authContext,
    );
  }

  factory ApiException.fromMessage(
    String rawMessage, {
    int? statusCode,
    AuthErrorContext? authContext,
  }) {
    return ApiException(
      _mapMessage(rawMessage, statusCode, authContext),
      statusCode: statusCode,
    );
  }

  static String? _messageText(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty) {
      return value.map((item) => item.toString()).join('\n');
    }
    return null;
  }

  static String _mapMessage(
    String? rawMessage,
    int? statusCode,
    AuthErrorContext? authContext,
  ) {
    final raw = rawMessage ?? '';

    if (authContext == AuthErrorContext.login) {
      if (statusCode == 401) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      if (statusCode == 400 || statusCode == 422) {
        return 'Email hoặc mật khẩu không hợp lệ. Vui lòng kiểm tra lại.';
      }
      if (_isServiceError(raw, statusCode)) return _serviceErrorMessage;
      if (_isCredentialMismatchMessage(raw)) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      if (isExplicitAccountConflictMessage(raw)) {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      if (statusCode == 403 || raw.contains('Required role missing')) {
        return _roleErrorMessage;
      }
      return raw.isNotEmpty ? raw : _fallbackMessage(statusCode);
    }

    if (authContext == AuthErrorContext.signup) {
      if (statusCode == 409 || isExplicitAccountConflictMessage(raw)) {
        return _duplicateAccountMessage;
      }
      if (statusCode == 401) {
        return 'Email này đã có tài khoản nhưng mật khẩu không khớp. Vui lòng đăng nhập hoặc dùng chức năng quên mật khẩu.';
      }
      if (statusCode == 400 || statusCode == 422) {
        return 'Thông tin đăng ký không hợp lệ. Vui lòng kiểm tra lại.';
      }
      if (_isServiceError(raw, statusCode)) return _serviceErrorMessage;
      if (_isCredentialMismatchMessage(raw)) {
        return 'Email này đã có tài khoản nhưng mật khẩu không khớp. Vui lòng đăng nhập hoặc dùng chức năng quên mật khẩu.';
      }
      if (statusCode == 403 || raw.contains('Required role missing')) {
        return _roleErrorMessage;
      }
      return raw.isNotEmpty ? raw : _fallbackMessage(statusCode);
    }

    if (statusCode == 400 || statusCode == 422) {
      return 'Dữ liệu gửi lên không hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (_isServiceError(raw, statusCode)) return _serviceErrorMessage;
    if (statusCode == 403 || raw.contains('Required role missing')) {
      return _roleErrorMessage;
    }
    return raw.isNotEmpty ? raw : _fallbackMessage(statusCode);
  }

  static bool isExplicitAccountConflictMessage(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('email already exists') ||
        normalized.contains('email already used') ||
        normalized.contains('email or account already exists') ||
        normalized.contains('user already exists') ||
        normalized.contains('account already exists') ||
        normalized.contains('email này đã được sử dụng') ||
        normalized.contains('email hoặc tài khoản này đã được sử dụng') ||
        normalized.contains('tài khoản này đã được sử dụng') ||
        normalized.contains('email đã tồn tại') ||
        normalized.contains('tài khoản đã tồn tại');
  }

  static bool _isCredentialMismatchMessage(String raw) {
    final normalized = raw.toLowerCase();
    return normalized.contains('invalid username or password') ||
        normalized.contains('invalid email or password') ||
        normalized.contains(
          'credentials do not match the existing keycloak account',
        ) ||
        normalized.contains('email hoặc mật khẩu không chính xác');
  }

  static bool _isServiceError(String raw, int? statusCode) =>
      raw.toLowerCase().contains('keycloak request failed') ||
      (statusCode != null && statusCode >= 500);

  static String _fallbackMessage(int? statusCode) {
    if (statusCode == null) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    }
    if (statusCode == 401) return 'Yêu cầu chưa được xác thực.';
    if (statusCode == 409) return 'Yêu cầu bị xung đột với dữ liệu hiện tại.';
    return 'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại sau.';
  }

  static const _duplicateAccountMessage =
      'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.';
  static const _serviceErrorMessage =
      'Hệ thống đang bảo trì hoặc gặp sự cố tạm thời. Vui lòng thử lại sau.';
  static const _roleErrorMessage =
      'Tài khoản chưa được cập nhật quyền khách hàng. Vui lòng đăng xuất và đăng nhập lại.';

  @override
  String toString() => message;
}
