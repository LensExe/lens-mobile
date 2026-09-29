import '../models/booking_model.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(String id);
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus);
  Future<void> createBooking(Booking booking);
}
