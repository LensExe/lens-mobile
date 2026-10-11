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
      return ApiException(backendMessage.trim(), statusCode: statusCode);
    }
    if (backendMessage is List && backendMessage.isNotEmpty) {
      return ApiException(
        backendMessage.map((item) => item.toString()).join('\n'),
        statusCode: statusCode,
      );
    }
    if (statusCode != null) {
      return ApiException(
        'Yêu cầu thất bại (HTTP $statusCode).',
        statusCode: statusCode,
      );
    }
    return const ApiException(
      'Không thể kết nối Backend. Kiểm tra mạng và API_BASE_URL.',
    );
  }

  @override
  String toString() => message;
}
