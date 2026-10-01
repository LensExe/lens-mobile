import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'booking_repository.dart';
import 'mock_booking_repository.dart';

final customerBookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository();
});
