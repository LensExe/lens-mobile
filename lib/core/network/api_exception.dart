import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final body = error.response?.data;
    final backendMessage = body is Map ? body['message'] : null;
    if (backendMessage is String && backendMessage.trim().isNotEmpty) {
      final sanitized = _sanitizeMessage(backendMessage.trim(), statusCode);
      return ApiException(sanitized, statusCode: statusCode);
    }
    if (backendMessage is List && backendMessage.isNotEmpty) {
      final combined =
          backendMessage.map((item) => item.toString()).join('\n');
      final sanitized = _sanitizeMessage(combined, statusCode);
      return ApiException(sanitized, statusCode: statusCode);
    }
    if (statusCode == 401) {
      return const ApiException(
        'Email hoặc mật khẩu không chính xác.',
        statusCode: 401,
      );
    }
    if (statusCode == 409) {
      return const ApiException(
        'Email hoặc tài khoản này đã được sử dụng.',
        statusCode: 409,
      );
    }
    if (statusCode != null) {
      if (statusCode >= 500) {
        return ApiException(
          'Hệ thống đang bảo trì hoặc gặp sự cố tạm thời (HTTP $statusCode). Vui lòng thử lại sau.',
          statusCode: statusCode,
        );
      }
      return ApiException(
        'Yêu cầu thất bại (HTTP $statusCode).',
        statusCode: statusCode,
      );
    }
    return const ApiException(
      'Không thể kết nối Backend. Kiểm tra mạng và API_BASE_URL.',
    );
  }

  static String _sanitizeMessage(String raw, int? statusCode) {
    if (raw.contains('Keycloak request failed with status 401') ||
        raw.contains('Keycloak request failed with status 409') ||
        raw.toLowerCase().contains('user already exists') ||
        raw.toLowerCase().contains('user exists')) {
      return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.';
    }
    if (raw.contains('Keycloak request failed with status 400') ||
        statusCode == 400 ||
        statusCode == 422) {
      return 'Thông tin đăng ký không hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (raw.contains('Keycloak request failed') ||
        (statusCode != null && statusCode >= 500)) {
      return 'Hệ thống đang bảo trì hoặc gặp sự cố tạm thời. Vui lòng thử lại sau.';
    }
    if (statusCode == 403 || raw.contains('Required role missing')) {
      return 'Tài khoản chưa được cập nhật quyền khách hàng. Vui lòng đăng xuất và đăng nhập lại.';
    }
    return raw;
  }

  @override
  String toString() => message;
}
