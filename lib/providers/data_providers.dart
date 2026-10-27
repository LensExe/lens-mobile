import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_auth_flow_repository.dart';
import '../data/repositories/api_customer_reviews_repository.dart';
import '../data/repositories/api_customer_wallet_repository.dart';
import '../data/repositories/api_customer_notification_preferences_repository.dart';
import '../core/network/auth_session_store.dart';
import '../core/network/dio_client.dart';
import '../domain/models/customer_wallet_model.dart';
import '../domain/models/customer_review_model.dart';
import '../domain/models/customer_notification_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    ref.watch(dioProvider),
    ref.watch(authSessionStoreProvider),
  );
});

final authFlowRepositoryProvider = Provider<ApiAuthFlowRepository>(
  (ref) => ApiAuthFlowRepository(
    ref.watch(dioProvider),
    ref.watch(authSessionStoreProvider),
    expectedRole: 'client',
  ),
);

class AuthUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    ref.read(authSessionStoreProvider).onSessionExpired = () => setUser(null);
    return ref.read(initialAuthUserProvider);
  }

  void setUser(User? user) {
    state = user;
    ref.invalidate(customerWalletProvider);
    ref.invalidate(customerReviewsProvider);
  }

  Future<User> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.login(email: email, password: password);
    setUser(user);
    return user;
  }

  Future<User> loginWithGoogleCode(String code) async {
    final user = await ref
        .read(authFlowRepositoryProvider)
        .exchangeGoogleCode(code);
    setUser(user);
    return user;
  }

  Future<User> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signup(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    setUser(user);
    return user;
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
    required String city,
    required String address,
    bool? saveAsDefault,
    String? gender,
    String? dateOfBirth,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.updateProfile(
      name: name,
      phone: phone,
      city: city,
      address: address,
      saveAsDefault: saveAsDefault,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
    setUser(updated);
    return updated;
  }

  Future<User> refreshProfile() async {
    final updated = await ref.read(authRepositoryProvider).readCurrentProfile();
    setUser(updated);
    return updated;
  }

  Future<User> updateAvatar(String localPath) async {
    final updated = await ref
        .read(authRepositoryProvider)
        .updateAvatar(localPath);
    setUser(updated);
    return updated;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.logout();
    } finally {
      setUser(null);
    }
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, User?>(
  () => AuthUserNotifier(),
);

// --- Customer Wallet ---
final customerWalletRepositoryProvider = Provider<CustomerWalletDataSource>((
  ref,
) {
  return ApiCustomerWalletRepository(ref.watch(dioProvider));
});

class CustomerWalletNotifier extends AsyncNotifier<CustomerWallet> {
  @override
  Future<CustomerWallet> build() async {
    final repo = ref.watch(customerWalletRepositoryProvider);
    return repo.getWallet();
  }
}

final customerWalletProvider =
    AsyncNotifierProvider<CustomerWalletNotifier, CustomerWallet>(
      () => CustomerWalletNotifier(),
    );

// --- Customer Reviews ---
final customerReviewsRepositoryProvider = Provider<CustomerReviewsDataSource>((
  ref,
) {
  return ApiCustomerReviewsRepository(ref.watch(dioProvider));
});

class CustomerReviewsNotifier
    extends AsyncNotifier<List<SubmittedCustomerReview>> {
  final Set<String> _submittingBookings = {};

  @override
  Future<List<SubmittedCustomerReview>> build() async {
    return ref.watch(customerReviewsRepositoryProvider).getMyReviews();
  }

  Future<void> submitReview({
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required String photographerAvatar,
    required String style,
    required String date,
    required int rating,
    required int punctualityRating,
    required int attitudeRating,
    required String comment,
  }) async {
    if (!_submittingBookings.add(bookingId)) {
      throw StateError('Đang gửi đánh giá cho booking này.');
    }
    try {
      final current = state.value ?? [];
      if (current.any((review) => review.bookingId == bookingId)) {
        throw StateError('Booking này đã được đánh giá trong phiên hiện tại.');
      }
      final review = await ref
          .read(customerReviewsRepositoryProvider)
          .submitReview(
            bookingId: bookingId,
            photographerId: photographerId,
            photographerName: photographerName,
            photographerAvatar: photographerAvatar,
            style: style,
            date: date,
            rating: rating,
            punctualityRating: punctualityRating,
            attitudeRating: attitudeRating,
            comment: comment,
          );
      state = AsyncData([review, ...current]);
    } finally {
      _submittingBookings.remove(bookingId);
    }
  }
}

final customerReviewsProvider =
    AsyncNotifierProvider<
      CustomerReviewsNotifier,
      List<SubmittedCustomerReview>
    >(() => CustomerReviewsNotifier());

final customerNotificationPreferencesRepositoryProvider =
    Provider<ApiCustomerNotificationPreferencesRepository>(
      (ref) =>
          ApiCustomerNotificationPreferencesRepository(ref.watch(dioProvider)),
    );

class CustomerNotificationPreferencesNotifier
    extends AsyncNotifier<CustomerNotificationPreferences> {
  @override
  Future<CustomerNotificationPreferences> build() {
    ref.watch(authUserProvider.select((user) => user?.id));
    return ref
        .watch(customerNotificationPreferencesRepositoryProvider)
        .getPreferences();
  }

  Future<void> updatePreferences(
    CustomerNotificationPreferences preferences,
  ) async {
    final previous = state.value;
    if (previous == null) return;
    try {
      final updated = await ref
          .read(customerNotificationPreferencesRepositoryProvider)
          .updatePreferences(preferences);
      state = AsyncData(updated);
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final customerNotificationPreferencesProvider =
    AsyncNotifierProvider<
      CustomerNotificationPreferencesNotifier,
      CustomerNotificationPreferences
    >(() => CustomerNotificationPreferencesNotifier());

// Legacy marketing preview has no Backend directory contract to load from.
final photographersProvider = Provider<List<Photographer>>((ref) => const []);
