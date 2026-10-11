import '../../domain/models/models.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> readCurrentProfile();
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

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
