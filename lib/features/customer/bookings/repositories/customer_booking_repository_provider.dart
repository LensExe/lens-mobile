import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import 'booking_repository.dart';
import 'api_booking_repository.dart';

final customerBookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return ApiBookingRepository(ref.watch(dioProvider));
});
