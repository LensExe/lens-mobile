import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/models.dart';
import '../data/mock_database.dart';
import '../data/mock_api_service.dart';

class AuthUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return MockDatabase.currentUser;
  }
  
  void setUser(User? user) {
    state = user;
    // When user changes, refresh bookings
    ref.invalidate(asyncBookingsProvider);
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, User?>(() => AuthUserNotifier());

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

  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
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

final asyncBookingsProvider = AsyncNotifierProvider<AsyncBookingsNotifier, List<Booking>>(() => AsyncBookingsNotifier());

// We can still provide a synchronous snapshot for simple screens,
// but they won't show loading states properly unless they use asyncBookingsProvider directly.
final myBookingsProvider = Provider<List<Booking>>((ref) {
  return ref.watch(asyncBookingsProvider).value ?? [];
});

class ConversationsNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() {
    return MockDatabase.conversations;
  }
}

final conversationsProvider = NotifierProvider<ConversationsNotifier, List<Conversation>>(() {
  return ConversationsNotifier();
});

class MessagesNotifier extends Notifier<List<Message>> {
  @override
  List<Message> build() {
    return MockDatabase.messages;
  }

  void addMessage(Message msg) {
    state = [...state, msg];
  }
}

final messagesProvider = NotifierProvider<MessagesNotifier, List<Message>>(() {
  return MessagesNotifier();
});
