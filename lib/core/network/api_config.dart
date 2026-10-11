import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiConfig {
  const ApiConfig({String? baseUrl})
    : _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  final String _baseUrl;

  String requireBaseUrl() {
    final value = _baseUrl.trim();
    if (value.isEmpty) {
      throw const ApiConfigurationException(
        'Thiếu API_BASE_URL. Hãy chạy app với --dart-define=API_BASE_URL=<Backend URL>.',
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw const ApiConfigurationException(
        'API_BASE_URL phải là URL tuyệt đối có host.',
      );
    }
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const ApiConfigurationException(
        'API_BASE_URL không được chứa credentials, query hoặc fragment.',
      );
    }
    final isLoopback = const {
      'localhost',
      '127.0.0.1',
      '::1',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && isLoopback)) {
      throw const ApiConfigurationException(
        'Backend phải dùng HTTPS; HTTP chỉ được phép cho localhost.',
      );
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: '$path/').toString();
  }
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException(this.message);
  final String message;

  @override
  String toString() => message;
}

final apiConfigProvider = Provider<ApiConfig>((ref) => const ApiConfig());
