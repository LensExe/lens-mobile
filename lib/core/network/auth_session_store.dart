import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/models.dart';
import 'api_exception.dart';

class AuthSessionData {
  const AuthSessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  factory AuthSessionData.fromApiJson(
    Map<String, dynamic> json, {
    String? fallbackRole,
  }) {
    final userData = _asMap(json['user']);
    final accessToken = _requiredString(json['access_token'], 'access_token');
    final refreshToken = _requiredString(
      json['refresh_token'],
      'refresh_token',
    );
    final expiresIn = _asInt(json['expires_in']);
    final role = _normalizeRole(userData['role']?.toString() ?? fallbackRole);
    if (role == null) {
      throw const ApiException(
        'Backend không trả về role hợp lệ cho tài khoản.',
      );
    }
    return AuthSessionData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      user: User(
        id: _requiredString(userData['id'], 'user.id'),
        name: _requiredString(userData['fullname'], 'user.fullname'),
        email: _requiredString(userData['email'], 'user.email'),
        role: role,
        phone: userData['phone_number']?.toString() ?? '',
        avatarUrl: userData['avatar_url']?.toString() ?? '',
      ),
    );
  }

  AuthSessionData withTokens(Map<String, dynamic> json) => AuthSessionData(
    accessToken: _requiredString(json['access_token'], 'access_token'),
    refreshToken: _requiredString(json['refresh_token'], 'refresh_token'),
    expiresIn: _asInt(json['expires_in']),
    user: user,
  );

  AuthSessionData withUser(User value) => AuthSessionData(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: expiresIn,
    user: value,
  );

  Map<String, dynamic> toStorageJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': expiresIn,
    'user': {
      'id': user.id,
      'fullname': user.name,
      'email': user.email,
      'role': user.role,
      'phone_number': user.phone,
      'location': user.city,
      'address': user.address,
      'avatar_url': user.avatarUrl,
      'save_as_default': user.saveAsDefault,
      'two_factor_enabled': user.twoFactorEnabled,
    },
  };

  factory AuthSessionData.fromStorageJson(Map<String, dynamic> json) {
    final userData = _asMap(json['user']);
    final role = _normalizeRole(userData['role']?.toString());
    if (role == null) {
      throw const ApiException(
        'Session lưu trên thiết bị có role không hợp lệ.',
      );
    }
    return AuthSessionData(
      accessToken: _requiredString(json['access_token'], 'access_token'),
      refreshToken: _requiredString(json['refresh_token'], 'refresh_token'),
      expiresIn: _asInt(json['expires_in']),
      user: User(
        id: _requiredString(userData['id'], 'user.id'),
        name: _requiredString(userData['fullname'], 'user.fullname'),
        email: _requiredString(userData['email'], 'user.email'),
        role: role,
        phone: userData['phone_number']?.toString() ?? '',
        city: userData['location']?.toString() ?? '',
        address: userData['address']?.toString() ?? '',
        avatarUrl: userData['avatar_url']?.toString() ?? '',
        saveAsDefault: userData['save_as_default'] == true,
        twoFactorEnabled: userData['two_factor_enabled'] == true,
      ),
    );
  }
}

class AuthSessionStore {
  AuthSessionStore({SessionStorage? storage})
    : _storage = storage ?? SecureSessionStorage();

  static const _storageKey = 'lens.auth_session.v1';

  final SessionStorage _storage;
  AuthSessionData? _session;
  Future<void> _writeQueue = Future<void>.value();
  void Function()? onSessionExpired;

  AuthSessionData? get session => _session;
  String? get accessToken => _session?.accessToken;
  String? get refreshToken => _session?.refreshToken;

  Future<void> restore() async {
    final encoded = await _storage.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const ApiException('Session lưu trên thiết bị không hợp lệ.');
      }
      _session = AuthSessionData.fromStorageJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
    } on FormatException {
      await _storage.delete(_storageKey);
      _session = null;
    } on ApiException {
      await _storage.delete(_storageKey);
      _session = null;
    }
  }

  Future<void> save(AuthSessionData session) => _enqueue(() async {
    await _storage.write(_storageKey, jsonEncode(session.toStorageJson()));
    _session = session;
  });

  Future<void> updateTokens(Map<String, dynamic> tokenJson) =>
      _enqueue(() async {
        final current = _session;
        if (current == null) {
          throw const ApiException('Phiên đăng nhập đã hết hạn.');
        }
        final updated = current.withTokens(tokenJson);
        await _storage.write(_storageKey, jsonEncode(updated.toStorageJson()));
        _session = updated;
      });

  Future<void> updateUser(User user) => _enqueue(() async {
    final current = _session;
    if (current == null) throw const ApiException('Vui lòng đăng nhập.');
    final updated = current.withUser(user);
    await _storage.write(_storageKey, jsonEncode(updated.toStorageJson()));
    _session = updated;
  });

  Future<void> clear() => _enqueue(() async {
    _session = null;
    await _storage.delete(_storageKey);
  });

  Future<void> expire() async {
    try {
      await clear();
    } finally {
      onSessionExpired?.call();
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _writeQueue.then((_) => operation());
    _writeQueue = next.catchError((Object _) {});
    return next;
  }
}

abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu không đúng cấu trúc.');
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường bắt buộc $field.');
}

int _asInt(Object? value) {
  if (value is int && value > 0) return value;
  if (value is num && value > 0) return value.toInt();
  throw const ApiException('Backend trả về expires_in không hợp lệ.');
}

String? _normalizeRole(String? value) => switch (value?.toLowerCase()) {
  'customer' || 'client' => 'client',
  'photographer' => 'photographer',
  _ => null,
};

final authSessionStoreProvider = Provider<AuthSessionStore>(
  (ref) => AuthSessionStore(),
);
final initialAuthUserProvider = Provider<User?>(
  (ref) => ref.watch(authSessionStoreProvider).session?.user,
);
