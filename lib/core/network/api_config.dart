import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiConfig {
  const ApiConfig({
    String? baseUrl,
    String? notificationSocketUrl,
    String? chatApiUrl,
    String? notificationApiUrl,
  }) : _baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_BASE_URL',
             defaultValue: 'https://api.lens.id.vn/api/v1',
           ),
       _notificationSocketUrl =
           notificationSocketUrl ??
           const String.fromEnvironment('NOTIFICATION_SOCKET_URL'),
       _chatApiUrl = chatApiUrl ?? const String.fromEnvironment('CHAT_API_URL'),
       _notificationApiUrl =
           notificationApiUrl ??
           const String.fromEnvironment('NOTIFICATION_API_URL');

  final String _baseUrl;
  final String _notificationSocketUrl;
  final String _chatApiUrl;
  final String _notificationApiUrl;

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
      '10.0.2.2',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && isLoopback)) {
      throw const ApiConfigurationException(
        'Backend phải dùng HTTPS; HTTP chỉ được phép cho localhost.',
      );
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: '$path/').toString();
  }

  String requireChatApiBaseUrl() {
    final configured = _chatApiUrl.trim();
    final value = configured.isEmpty ? requireBaseUrl() : configured;
    final uri = _validateServiceUrl(value, 'CHAT_API_URL');
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/api/v1/chat')) {
      // The configured URL already includes the Chat Service path.
    } else if (path.endsWith('/api/v1')) {
      path = '$path/chat';
    } else if (path.endsWith('/api')) {
      path = '$path/v1/chat';
    } else {
      path = '$path/api/v1/chat';
    }
    return uri.replace(path: '$path/').toString();
  }

  String requireNotificationApiBaseUrl() {
    final configured = _notificationApiUrl.trim();
    final value = configured.isEmpty ? requireBaseUrl() : configured;
    final uri = _validateServiceUrl(value, 'NOTIFICATION_API_URL');
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/api/v1/notifications')) {
      path = path.substring(0, path.length - '/notifications'.length);
    } else if (path.endsWith('/api/v1')) {
      // The configured URL already points to the API root.
    } else if (path.endsWith('/api')) {
      path = '$path/v1';
    } else {
      path = '$path/api/v1';
    }
    return uri.replace(path: '$path/').toString();
  }

  String requireNotificationSocketNamespace() {
    final configured = _notificationSocketUrl.trim();
    final notificationApi = _notificationApiUrl.trim();
    final uri = Uri.tryParse(
      configured.isNotEmpty
          ? configured
          : notificationApi.isNotEmpty
          ? notificationApi
          : requireBaseUrl(),
    );
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw const ApiConfigurationException(
        'NOTIFICATION_SOCKET_URL phải là URL tuyệt đối có host.',
      );
    }
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const ApiConfigurationException(
        'NOTIFICATION_SOCKET_URL không được chứa credentials, query hoặc fragment.',
      );
    }
    final isLoopback = const {
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && isLoopback)) {
      throw const ApiConfigurationException(
        'Notification Socket.IO phải dùng HTTPS; HTTP chỉ được phép cho localhost.',
      );
    }
    return uri.replace(path: '/notification').toString();
  }

  Uri _validateServiceUrl(String value, String setting) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw ApiConfigurationException(
        '$setting phải là URL tuyệt đối có host.',
      );
    }
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw ApiConfigurationException(
        '$setting không được chứa credentials, query hoặc fragment.',
      );
    }
    final isLoopback = const {
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && !(uri.scheme == 'http' && isLoopback)) {
      throw ApiConfigurationException(
        '$setting phải dùng HTTPS; HTTP chỉ được phép cho localhost.',
      );
    }
    return uri;
  }
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException(this.message);
  final String message;

  @override
  String toString() => message;
}

final apiConfigProvider = Provider<ApiConfig>((ref) => const ApiConfig());
