import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/models.dart';
import '../data/mock_database.dart';
import '../data/mock_api_service.dart';

import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_customer_wallet_repository.dart';
import '../data/repositories/mock_customer_reviews_repository.dart';
import '../data/repositories/mock_customer_messages_repository.dart';
import '../data/repositories/mock_notification_preferences_repository.dart';
import '../domain/models/customer_wallet_model.dart';
import '../domain/models/customer_review_model.dart';
import '../features/customer/discovery/repositories/discovery_repository_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

class AuthUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return MockDatabase.currentUser;
  }

  void setUser(User? user) {
    state = user;
    MockDatabase.currentUser = user;
    ref.invalidate(asyncBookingsProvider);
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

  Future<User> updateAvatar(String localPath) async {
    final user = await ref.read(authRepositoryProvider).updateAvatar(localPath);
    setUser(user);
    return user;
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
    await repo.logout();
    setUser(null);
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, User?>(
  () => AuthUserNotifier(),
);

// --- Active Sessions ---
class ActiveSessionsNotifier extends AsyncNotifier<List<ActiveSession>> {
  @override
  Future<List<ActiveSession>> build() async {
    ref.watch(authUserProvider.select((user) => user?.id));
    if (ref.read(authUserProvider) == null) return [];
    final repo = ref.read(authRepositoryProvider);
    return repo.getActiveSessions();
  }

  Future<void> revokeSession(String sessionId) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.revokeSession(sessionId);
    state = AsyncData(await repo.getActiveSessions());
  }

  Future<void> revokeAllOther() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.revokeAllOtherSessions();
    state = AsyncData(await repo.getActiveSessions());
  }
}

final activeSessionsProvider =
    AsyncNotifierProvider<ActiveSessionsNotifier, List<ActiveSession>>(
      () => ActiveSessionsNotifier(),
    );

// --- Notification Preferences ---
final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>(
      (ref) => MockNotificationPreferencesRepository(),
    );

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    final id = ref.watch(authUserProvider.select((user) => user?.id));
    return id == null
        ? const NotificationPreferences()
        : ref.read(notificationPreferencesRepositoryProvider).getForAccount(id);
  }

  void update({
    bool? emailBooking,
    bool? emailMessage,
    bool? smsReminder,
    bool? promoCashback,
  }) {
    final id = ref.read(authUserProvider)?.id;
    if (id == null) return;
    state = state.copyWith(
      emailBooking: emailBooking,
      emailMessage: emailMessage,
      smsReminder: smsReminder,
      promoCashback: promoCashback,
    );
    ref
        .read(notificationPreferencesRepositoryProvider)
        .saveForAccount(id, state);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      () => NotificationPreferencesNotifier(),
    );

// --- Customer Wallet ---
final customerWalletRepositoryProvider = Provider<CustomerWalletRepository>((
  ref,
) {
  final userId = ref.watch(authUserProvider.select((user) => user?.id));
  return MockCustomerWalletRepository(
    accountId: userId ?? 'guest',
    demo: userId == MockDatabase.customerUser.id,
  );
});

class CustomerWalletNotifier extends AsyncNotifier<CustomerWallet> {
  @override
  Future<CustomerWallet> build() async {
    final repo = ref.watch(customerWalletRepositoryProvider);
    return repo.getWallet();
  }

  Future<void> addRefund({
    required int amount,
    required String bookingId,
    required String photographerName,
  }) async {
    final repo = ref.read(customerWalletRepositoryProvider);
    final updated = await repo.addRefund(
      amount: amount,
      bookingId: bookingId,
      photographerName: photographerName,
    );
    state = AsyncData(updated);
  }

  Future<void> addCashback({
    required int coins,
    required String bookingId,
  }) async {
    final repo = ref.read(customerWalletRepositoryProvider);
    final updated = await repo.addCashback(coins: coins, bookingId: bookingId);
    state = AsyncData(updated);
  }

  Future<void> redeemCoins({
    required int coins,
    required String bookingId,
  }) async {
    final repo = ref.read(customerWalletRepositoryProvider);
    final updated = await repo.redeemCoins(coins: coins, bookingId: bookingId);
    state = AsyncData(updated);
  }

  Future<void> restoreCoins({
    required int coins,
    required String bookingId,
  }) async {
    final repo = ref.read(customerWalletRepositoryProvider);
    state = AsyncData(
      await repo.restoreCoins(coins: coins, bookingId: bookingId),
    );
  }

  Future<void> addReviewReward({
    required int coins,
    required String photographerName,
  }) async {
    final repo = ref.read(customerWalletRepositoryProvider);
    final updated = await repo.addReviewReward(
      coins: coins,
      photographerName: photographerName,
    );
    state = AsyncData(updated);
  }
}

final customerWalletProvider =
    AsyncNotifierProvider<CustomerWalletNotifier, CustomerWallet>(
      () => CustomerWalletNotifier(),
    );

// --- Customer Reviews ---
final customerReviewsRepositoryProvider = Provider<CustomerReviewsRepository>((
  ref,
) {
  final userId = ref.watch(authUserProvider.select((user) => user?.id));
  return MockCustomerReviewsRepository(
    accountId: userId ?? 'guest',
    photographers: ref.read(discoveryRepositoryProvider),
    demo: userId == MockDatabase.customerUser.id,
  );
});

class CustomerReviewsNotifier
    extends AsyncNotifier<List<SubmittedCustomerReview>> {
  @override
  Future<List<SubmittedCustomerReview>> build() async {
    final repo = ref.watch(customerReviewsRepositoryProvider);
    return repo.getMyReviews();
  }

  Future<void> submitReview({
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required String photographerAvatar,
    required String style,
    required String date,
    required double rating,
    required String comment,
  }) async {
    final repo = ref.read(customerReviewsRepositoryProvider);
    final review = await repo.submitReview(
      bookingId: bookingId,
      photographerId: photographerId,
      photographerName: photographerName,
      photographerAvatar: photographerAvatar,
      style: style,
      date: date,
      rating: rating,
      comment: comment,
    );
    final current = state.value ?? [];
    state = AsyncData([review, ...current]);

    // Also reward 10.000 Lens Xu to wallet
    await ref
        .read(customerWalletProvider.notifier)
        .addReviewReward(coins: 10000, photographerName: photographerName);
  }
}

final customerReviewsProvider =
    AsyncNotifierProvider<
      CustomerReviewsNotifier,
      List<SubmittedCustomerReview>
    >(() => CustomerReviewsNotifier());

final photographersProvider = Provider<List<Photographer>>((ref) {
  return MockDatabase.photographers;
});

// Using AsyncNotifier to handle API loading states
class AsyncBookingsNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    final user = ref.watch(authUserProvider);
    if (user == null) return [];

    return await mockApiService.getMyBookings(user.id, user.role);
  }

  Future<void> createBooking(Booking booking) async {
    // Keep old state
    final previousState = state.value ?? [];

    // Set loading
    state = const AsyncLoading();

    try {
      final newBooking = await mockApiService.createBooking(booking);
      state = AsyncData([...previousState, newBooking]);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    final previousState = state.value ?? [];

    try {
      await mockApiService.updateBookingStatus(bookingId, newStatus);

      // Update local state without re-fetching everything
      final updatedList = previousState.map((b) {
        if (b.id == bookingId) {
          return Booking(
            id: b.id,
            clientId: b.clientId,
            clientName: b.clientName,
            photographerId: b.photographerId,
            photographerName: b.photographerName,
            style: b.style,
            date: b.date,
            location: b.location,
            price: b.price,
            status: newStatus, // updated
          );
        }
        return b;
      }).toList();

      state = AsyncData(updatedList);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final asyncBookingsProvider =
    AsyncNotifierProvider<AsyncBookingsNotifier, List<Booking>>(
      () => AsyncBookingsNotifier(),
    );

// We can still provide a synchronous snapshot for simple screens,
// but they won't show loading states properly unless they use asyncBookingsProvider directly.
final myBookingsProvider = Provider<List<Booking>>((ref) {
  return ref.watch(asyncBookingsProvider).value ?? [];
});

final customerMessagesRepositoryProvider = Provider<CustomerMessagesRepository>(
  (ref) => MockCustomerMessagesRepository(),
);

class ConversationsNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() {
    final user = ref.watch(authUserProvider);
    return user?.role == 'client'
        ? ref
              .read(customerMessagesRepositoryProvider)
              .getConversations(user!.id)
        : [];
  }

  Conversation ensureForPhotographer({
    required String photographerId,
    required String name,
    required String avatar,
    required String clientId,
  }) {
    final conversation = ref
        .read(customerMessagesRepositoryProvider)
        .ensureForPhotographer(
          accountId: clientId,
          photographerId: photographerId,
          name: name,
          avatar: avatar,
        );
    state = ref
        .read(customerMessagesRepositoryProvider)
        .getConversations(clientId);
    return conversation;
  }

  void markRead(String conversationId) {
    final accountId = ref.read(authUserProvider)?.id;
    if (accountId == null) return;
    ref
        .read(customerMessagesRepositoryProvider)
        .markRead(accountId, conversationId);
    state = ref
        .read(customerMessagesRepositoryProvider)
        .getConversations(accountId);
  }

  void updatePreview({
    required String conversationId,
    required String message,
    required DateTime updatedAt,
  }) {
    final accountId = ref.read(authUserProvider)?.id;
    if (accountId == null) return;
    ref
        .read(customerMessagesRepositoryProvider)
        .updatePreview(
          accountId: accountId,
          conversationId: conversationId,
          message: message,
          updatedAt: updatedAt,
        );
    state = ref
        .read(customerMessagesRepositoryProvider)
        .getConversations(accountId);
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, List<Conversation>>(() {
      return ConversationsNotifier();
    });

class MessagesNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() {
    final user = ref.watch(authUserProvider);
    return user?.role == 'client'
        ? ref.read(customerMessagesRepositoryProvider).getMessages(user!.id)
        : [];
  }

  void addMessage(Message msg) {
    final accountId = ref.read(authUserProvider)?.id;
    if (accountId == null) throw StateError('Bạn cần đăng nhập.');
    ref.read(customerMessagesRepositoryProvider).addMessage(accountId, msg);
    state = ref.read(customerMessagesRepositoryProvider).getMessages(accountId);
  }
}

final messagesProvider = NotifierProvider<MessagesNotifier, List<Message>>(() {
  return MessagesNotifier();
});
