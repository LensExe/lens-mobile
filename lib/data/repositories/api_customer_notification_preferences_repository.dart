import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../domain/models/customer_notification_preferences.dart';

class ApiCustomerNotificationPreferencesRepository {
  const ApiCustomerNotificationPreferencesRepository(this._dio);

  final Dio _dio;

  Future<CustomerNotificationPreferences> getPreferences() async {
    try {
      final response = await _dio.get<dynamic>('users/me');
      final user = _responseMap(response.data);
      return CustomerNotificationPreferences.fromApiJson(
        user['notification_preferences'],
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerNotificationPreferences> updatePreferences(
    CustomerNotificationPreferences preferences,
  ) async {
    try {
      await _dio.patch<dynamic>(
        'users/me',
        data: {'notification_preferences': preferences.toApiJson()},
      );
      return preferences;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  throw const ApiException('Backend trả về hồ sơ thông báo không hợp lệ.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _asMap(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException('Backend không xác nhận yêu cầu thông báo.');
    }
    payload = _asMap(payload['data']);
  }
  return payload;
}
