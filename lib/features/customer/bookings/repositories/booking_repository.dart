import '../models/booking_model.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(String id);
  Future<BookingCancellationPreview> getCancellationPreview(String bookingId);
  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus);
  Future<void> payRemaining(String bookingId, int coinsRedeemed);
  Future<void> createBooking(Booking booking);

  Future<Booking> createBookingFromInput(BookingCreateInput input);
  Future<Booking> cancelBooking(String bookingId, String reason);
  Future<Booking> confirmReceipt(String bookingId);
}

class BookingCancellationPreview {
  const BookingCancellationPreview({
    required this.bookingId,
    required this.refundableAmountVnd,
    required this.refundRequiresAdminReview,
  });

  final String bookingId;
  final int refundableAmountVnd;
  final bool refundRequiresAdminReview;
}

class BookingCreateInput {
  const BookingCreateInput({
    required this.photographerId,
    required this.bookingPlanId,
    required this.location,
    required this.from,
    required this.to,
    this.photographerName = '',
    this.photographerAvatar = '',
  });

  final String photographerId;
  final String bookingPlanId;
  final String location;
  final DateTime from;
  final DateTime to;
  final String photographerName;
  final String photographerAvatar;
}
