import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/auth_session_store.dart';
import '../../domain/models/models.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio, this._sessionStore);

  final Dio _dio;
  final AuthSessionStore _sessionStore;

  @override
  Future<User> login({required String email, required String password}) =>
      _authenticate('auth/login', {
        'email': email.trim(),
        'password': password,
      });

  @override
  Future<User> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    final backendRole = switch (role) {
      'client' || 'customer' => 'customer',
      'photographer' => 'photographer',
      _ => throw const ApiException('Role đăng ký không được Backend hỗ trợ.'),
    };
    return _authenticate('auth/register', {
      'role': backendRole,
      'fullname': name.trim(),
      'email': email.trim(),
      'password': password,
    }, fallbackRole: backendRole);
  }

  Future<User> _authenticate(
    String path,
    Map<String, Object?> body, {
    String? fallbackRole,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: body);
      final data = _asMap(response.data);
      final session = AuthSessionData.fromApiJson(
        data,
        fallbackRole: fallbackRole,
      );
      await _sessionStore.save(session);
      return session.user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = _sessionStore.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post<dynamic>(
          'auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } finally {
      await _sessionStore.clear();
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        'auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<User> readCurrentProfile() async {
    final current = _sessionStore.session?.user;
    if (current == null) throw const ApiException('Vui lòng đăng nhập.');
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('users/me'),
        _dio.get<dynamic>('customers/me'),
      ]);
      final userJson = _asMap(_unwrap(responses[0].data));
      final customerJson = _asMap(_unwrap(responses[1].data));
      final userId = userJson['id']?.toString();
      final customerUserId = customerJson['user_id']?.toString();
      if ((userId != null && userId != current.id) ||
          (customerUserId != null && customerUserId != current.id)) {
        throw const ApiException(
          'Backend trả về hồ sơ không thuộc tài khoản đang đăng nhập.',
        );
      }
      final updated = current.copyWith(
        name: userJson['fullname']?.toString() ?? current.name,
        email: userJson['email']?.toString() ?? current.email,
        phone: userJson['phone_number']?.toString() ?? '',
        avatarUrl: userJson['avatar_url']?.toString() ?? '',
        city: customerJson['location']?.toString() ?? '',
      );
      await _sessionStore.updateUser(updated);
      return updated;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<User> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    bool? saveAsDefault,
  }) async {
    final current = _sessionStore.session?.user;
    if (current == null) throw const ApiException('Vui lòng đăng nhập.');
    if (address.trim() != current.address.trim()) {
      throw const ApiException(
        'Backend chưa có trường địa chỉ chi tiết trong hồ sơ Customer.',
      );
    }
    if (saveAsDefault != null && saveAsDefault != current.saveAsDefault) {
      throw const ApiException(
        'Backend chưa có chức năng lưu địa chỉ mặc định.',
      );
    }

    final userBody = <String, String>{};
    if (name.trim().isNotEmpty && name.trim() != current.name) {
      userBody['fullname'] = name.trim();
    }
    if (phone.trim().isNotEmpty && phone.trim() != current.phone) {
      userBody['phone_number'] = phone.trim();
    }
    try {
      if (userBody.isNotEmpty) {
        await _dio.patch<dynamic>('users/me', data: userBody);
      }
      if (city.trim().isNotEmpty && city.trim() != current.city) {
        await _dio.patch<dynamic>(
          'customers/me',
          data: {'location': city.trim()},
        );
      }
      final updated = current.copyWith(
        name: name.trim().isEmpty ? current.name : name.trim(),
        phone: phone.trim().isEmpty ? current.phone : phone.trim(),
        city: city.trim().isEmpty ? current.city : city.trim(),
      );
      await _sessionStore.updateUser(updated);
      return updated;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<User> updateAvatar(String localPath) async => throw const ApiException(
    'Cập nhật avatar cần hoàn tất luồng upload media của Backend trước.',
  );

  @override
  Future<List<ActiveSession>> getActiveSessions() async =>
      throw const ApiException(
        'Backend hiện chưa có endpoint quản lý các phiên đăng nhập.',
      );

  @override
  Future<void> revokeSession(String sessionId) async =>
      throw const ApiException(
        'Backend hiện chưa có endpoint thu hồi từng phiên đăng nhập.',
      );

  @override
  Future<void> revokeAllOtherSessions() async => throw const ApiException(
    'Backend hiện chưa có endpoint thu hồi các phiên đăng nhập khác.',
  );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
}

Object? _unwrap(Object? value) {
  var result = value;
  while (result is Map && result.containsKey('data')) {
    result = result['data'];
  }
  return result;
}
