import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';

class LensNotification {
  const LensNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  factory LensNotification.fromJson(Map<String, dynamic> json) =>
      LensNotification(
        id: _string(json['id']),
        title: _string(json['title']),
        message: _string(json['content'] ?? json['message']),
        type: _string(json['type']),
        isRead: json['is_read'] == true,
        createdAt: DateTime.tryParse(_string(json['created_at']))?.toLocal(),
      );
}

class NotificationRepository {
  const NotificationRepository(this._dio, this._baseUrl);

  final Dio _dio;
  final String _baseUrl;

  String _url(String path) => '$_baseUrl$path';

  Future<List<LensNotification>> getNotifications() async {
    try {
      final response = await _dio.get<dynamic>(
        _url('notifications'),
        queryParameters: const {'skip': 0, 'limit': 100},
      );
      final rows = _list(_unwrap(response.data));
      return rows
          .map((row) => LensNotification.fromJson(_map(row)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post<dynamic>(_url('notifications/mark-read'));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(
    ref.watch(dioProvider),
    ref.watch(apiConfigProvider).requireNotificationApiBaseUrl(),
  ),
);

final notificationInboxProvider = FutureProvider<List<LensNotification>>(
  (ref) => ref.watch(notificationRepositoryProvider).getNotifications(),
);

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  throw const ApiException('Notification Service trả dữ liệu không hợp lệ.');
}

List<dynamic> _list(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final items = _map(value)['items'];
    if (items is List) return items;
  }
  throw const ApiException('Notification Service trả danh sách không hợp lệ.');
}

Object? _unwrap(Object? value) {
  var payload = value;
  while (payload is Map) {
    final map = _map(payload);
    if (map.containsKey('success') && map.containsKey('data')) {
      if (map['success'] != true) {
        throw const ApiException(
          'Notification Service không xác nhận thành công.',
        );
      }
      payload = map['data'];
      continue;
    }
    if (map.length == 1 && map.containsKey('data')) {
      payload = map['data'];
      continue;
    }
    return map;
  }
  return payload;
}

String _string(Object? value) => value?.toString() ?? '';
