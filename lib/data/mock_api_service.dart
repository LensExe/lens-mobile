import 'dart:math';

import '../domain/models/models.dart';
import 'mock_database.dart';

class MockApiService {
  static const _delay = Duration(seconds: 1);

  // --- BOOKINGS ---

  Future<List<Booking>> getMyBookings(String userId, String role) async {
    await Future.delayed(_delay); // Simulate network delay

    // In a real API, the BE filters this. Here we filter mock DB.
    if (role == 'photographer') {
      return MockDatabase.bookings
          .where((b) => b.photographerId == userId)
          .toList();
    } else {
      return MockDatabase.bookings.where((b) => b.clientId == userId).toList();
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(_delay);

    // Assign a new ID if needed (though UI might generate a temp one)
    final newBooking = Booking(
      id: 'b${Random().nextInt(10000)}',
      clientId: booking.clientId,
      clientName: booking.clientName,
      photographerId: booking.photographerId,
      photographerName: booking.photographerName,
      style: booking.style,
      date: booking.date,
      location: booking.location,
      price: booking.price,
      status: BookingStatus.pending,
    );

    MockDatabase.bookings.add(newBooking);
    return newBooking;
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    await Future.delayed(_delay);

    final index = MockDatabase.bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      MockDatabase.bookings[index].status = newStatus;
    } else {
      throw Exception('Booking not found');
    }
  }
}

// Global instance for simple DI
final mockApiService = MockApiService();
