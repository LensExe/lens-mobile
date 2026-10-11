import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lens_app/core/network/api_exception.dart';
import 'package:lens_app/core/widgets/primary_button.dart';
import 'package:lens_app/data/repositories/auth_repository.dart';
import 'package:lens_app/domain/models/models.dart';
import 'package:lens_app/features/auth/signup_screen.dart';
import 'package:lens_app/providers/data_providers.dart';

class _MockAuthRepository implements AuthRepository {
  _MockAuthRepository({this.errorToThrow, this.onSignup});

  final Object? errorToThrow;
  final void Function({
    required String name,
    required String email,
    required String password,
    required String role,
  })? onSignup;

  @override
  Future<User> login({required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<User> readCurrentProfile() async {
    throw UnimplementedError();
  }

  @override
  Future<User> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    onSignup?.call(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    return User(
      id: 'customer-new-1',
      name: name,
      email: email,
      role: role,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    bool? saveAsDefault,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<User> updateAvatar(String localPath) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ActiveSession>> getActiveSessions() async => [];

  @override
  Future<void> revokeSession(String sessionId) async {}

  @override
  Future<void> revokeAllOtherSessions() async {}
}

Widget _createTestApp(AuthRepository repository) {
  final router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/customer_home/overview',
        builder: (context, state) => const Scaffold(
          body: Text('Overview Screen'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets(
    'does not display role selection cards or questions for customer app',
    (tester) async {
      await tester.pumpWidget(_createTestApp(_MockAuthRepository()));
      await tester.pumpAndSettle();

      // Verify no role selection elements exist
      expect(find.text('Mục đích của bạn là gì?'), findsNothing);
      expect(find.text('Thuê thợ ảnh'), findsNothing);
      expect(find.text('Nhận lịch chụp'), findsNothing);
      expect(find.text('Tôi là Khách hàng'), findsNothing);
      expect(find.text('Tôi là Nhiếp ảnh gia'), findsNothing);

      // Verify input fields for customer registration are present
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu (tối thiểu 8 ký tự)'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Tạo tài khoản'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'submits signup with role client automatically and shows success SnackBar',
    (tester) async {
      String? submittedName;
      String? submittedEmail;
      String? submittedPassword;
      String? submittedRole;

      final repo = _MockAuthRepository(
        onSignup: ({
          required String name,
          required String email,
          required String password,
          required String role,
        }) {
          submittedName = name;
          submittedEmail = email;
          submittedPassword = password;
          submittedRole = role;
        },
      );

      await tester.pumpWidget(_createTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Nguyễn Văn A',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'nguyenvana@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Password123!',
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'Tạo tài khoản'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify role client was sent
      expect(submittedName, 'Nguyễn Văn A');
      expect(submittedEmail, 'nguyenvana@example.com');
      expect(submittedPassword, 'Password123!');
      expect(submittedRole, 'client');

      // Verify success SnackBar and navigation
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Tạo tài khoản thành công! Chào mừng bạn đến với Lens.'),
        findsOneWidget,
      );
      expect(find.text('Overview Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'shows friendly SnackBar and no raw inline error banner when email already exists',
    (tester) async {
      final repo = _MockAuthRepository(
        errorToThrow: const ApiException(
          'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.',
          statusCode: 409,
        ),
      );

      await tester.pumpWidget(_createTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Đã Tồn Tại',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'existing@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Password123!',
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'Tạo tài khoản'));
      await tester.pump();

      // Verify friendly SnackBar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Email này đã được sử dụng. Vui lòng đăng nhập hoặc sử dụng email khác.',
        ),
        findsOneWidget,
      );

      // Verify no raw technical error banner on form UI
      expect(find.textContaining('Exception:'), findsNothing);
      expect(find.textContaining('HTTP 409'), findsNothing);
    },
  );

  testWidgets(
    'handles Keycloak upstream errors by showing friendly message and no raw banner',
    (tester) async {
      final repo = _MockAuthRepository(
        errorToThrow: const ApiException(
          'Keycloak request failed with status 401',
          statusCode: 502,
        ),
      );

      await tester.pumpWidget(_createTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Trần B',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'tranb@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Password123!',
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'Tạo tài khoản'));
      await tester.pump();

      // Verify friendly SnackBar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Email này đã được sử dụng. Vui lòng đăng nhập hoặc sử dụng email khác.',
        ),
        findsOneWidget,
      );

      // Verify no raw Keycloak text or 502 bad gateway on form UI
      expect(find.textContaining('Keycloak'), findsNothing);
      expect(find.textContaining('502'), findsNothing);
      expect(find.textContaining('Bad Gateway'), findsNothing);
    },
  );

  testWidgets(
    'masks unexpected internal exceptions into friendly user message without crashing UI',
    (tester) async {
      final repo = _MockAuthRepository(
        errorToThrow: Exception(
          'ProviderException: Unhandled error in backend connection.\n#0 stack trace',
        ),
      );

      await tester.pumpWidget(_createTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Error User',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'error@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Password123!',
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'Tạo tài khoản'));
      await tester.pump();

      // Verify friendly SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Không thể kết nối đến hệ thống máy chủ. Vui lòng thử lại sau.'),
        findsOneWidget,
      );

      // Verify no raw stack trace or provider exception on UI
      expect(find.textContaining('ProviderException'), findsNothing);
      expect(find.textContaining('stack trace'), findsNothing);
    },
  );
}
