import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_customer_reviews_repository.dart';
import '../data/repositories/api_customer_wallet_repository.dart';
import '../core/network/auth_session_store.dart';
import '../core/network/dio_client.dart';
import '../domain/models/customer_wallet_model.dart';
import '../domain/models/customer_review_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(
    ref.watch(dioProvider),
    ref.watch(authSessionStoreProvider),
  );
});

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
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final updated = await repo.updateProfile(
      name: name,
      phone: phone,
      city: city,
      address: address,
      saveAsDefault: saveAsDefault,
    );
    setUser(updated);
    return updated;
  }

  Future<User> refreshProfile() async {
    final updated = await ref.read(authRepositoryProvider).readCurrentProfile();
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
    // Backend has no customer review-history endpoint. Keep only reviews
    // confirmed by POST during this app session.
    return [];
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

// Legacy marketing preview has no Backend directory contract to load from.
final photographersProvider = Provider<List<Photographer>>((ref) => const []);

class ConversationsNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() => [];

  Conversation ensureForPhotographer({
    required String photographerId,
    required String name,
    required String avatar,
    required String clientId,
  }) => throw StateError(
    'Backend hiện chưa cung cấp API tạo hoặc tải cuộc trò chuyện.',
  );

  void markRead(String conversationId) =>
      throw StateError('Backend hiện chưa hỗ trợ cập nhật trạng thái đã đọc.');

  void updatePreview({
    required String conversationId,
    required String message,
    required DateTime updatedAt,
  }) => throw StateError('Backend hiện chưa cung cấp API gửi tin nhắn.');
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, List<Conversation>>(() {
      return ConversationsNotifier();
    });

class MessagesNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() => [];

  void addMessage(Message msg) =>
      throw StateError('Backend hiện chưa cung cấp API gửi tin nhắn.');
}

final messagesProvider = NotifierProvider<MessagesNotifier, List<Message>>(() {
  return MessagesNotifier();
});
