import '../../domain/models/models.dart';
import '../mock_database.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  Future<void> logout();
  Future<User> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    bool? saveAsDefault,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<User> updateAvatar(String localPath);
  Future<List<ActiveSession>> getActiveSessions();
  Future<void> revokeSession(String sessionId);
  Future<void> revokeAllOtherSessions();
}

class MockAuthRepository implements AuthRepository {
  static final Map<String, List<ActiveSession>> _sessionsByUser = {};

  List<ActiveSession> _sessionsForCurrentUser() {
    final user = MockDatabase.currentUser;
    if (user == null) throw const AuthException('Vui lòng đăng nhập.');
    return _sessionsByUser.putIfAbsent(
      user.id,
      () => user.id == MockDatabase.customerUser.id
          ? List.from(MockDatabase.activeSessions)
          : [
              ActiveSession(
                id: 'sess-${user.id}',
                deviceName: 'Thiết bị hiện tại',
                location: 'Việt Nam',
                lastActive: 'Đang hoạt động',
                isCurrent: true,
              ),
            ],
    );
  }

  static final Map<String, User> _users = {
    'customer@lens.com': MockDatabase.customerUser,
    'tran@lens.com': MockDatabase.customerUser,
    'photo@lens.com': MockDatabase.photographerUser,
  };
  static final Map<String, String> _passwords = {
    'customer@lens.com': '123456',
    'tran@lens.com': '123456',
    'photo@lens.com': '123456',
  };

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final trimmedEmail = email.trim().toLowerCase();
    final user = _users[trimmedEmail];
    if (user == null || _passwords[trimmedEmail] != password) {
      throw const AuthException('Email hoặc mật khẩu không chính xác.');
    }
    MockDatabase.currentUser = user;
    return user;
  }

  @override
  Future<User> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final trimmedEmail = email.trim().toLowerCase();

    // 409 Conflict check: Email already exists
    if (_users.containsKey(trimmedEmail)) {
      throw const AuthException(
        'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
      );
    }

    if (password.length < 8) {
      throw const AuthException('Mật khẩu phải có tối thiểu 8 ký tự.');
    }

    final newUser = User(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: trimmedEmail,
      role: role,
    );
    _users[trimmedEmail] = newUser;
    _passwords[trimmedEmail] = password;
    MockDatabase.currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    MockDatabase.currentUser = null;
  }

  @override
  Future<User> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    bool? saveAsDefault,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final current = MockDatabase.currentUser;
    if (current == null) throw const AuthException('Vui lòng đăng nhập.');
    final updated = current.copyWith(
      name: name,
      phone: phone,
      city: city,
      address: address,
      saveAsDefault: saveAsDefault,
    );
    MockDatabase.currentUser = updated;
    _users[current.email.toLowerCase()] = updated;
    return updated;
  }

  @override
  Future<User> updateAvatar(String localPath) async {
    final current = MockDatabase.currentUser;
    if (current == null) throw const AuthException('Vui lòng đăng nhập.');
    if (localPath.isEmpty) {
      throw const AuthException('Ảnh đại diện không hợp lệ.');
    }
    final updated = current.copyWith(avatarUrl: localPath);
    MockDatabase.currentUser = updated;
    _users[current.email.toLowerCase()] = updated;
    return updated;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = MockDatabase.currentUser;
    if (user == null) throw const AuthException('Vui lòng đăng nhập.');
    if (_passwords[user.email.toLowerCase()] != currentPassword) {
      throw const AuthException('Mật khẩu hiện tại không chính xác.');
    }
    if (newPassword.length < 8) {
      throw const AuthException('Mật khẩu mới phải có tối thiểu 8 ký tự.');
    }
    _passwords[user.email.toLowerCase()] = newPassword;
  }

  @override
  Future<List<ActiveSession>> getActiveSessions() async {
    return List.unmodifiable(_sessionsForCurrentUser());
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessionsForCurrentUser().removeWhere(
      (s) => s.id == sessionId && !s.isCurrent,
    );
  }

  @override
  Future<void> revokeAllOtherSessions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessionsForCurrentUser().removeWhere((s) => !s.isCurrent);
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
