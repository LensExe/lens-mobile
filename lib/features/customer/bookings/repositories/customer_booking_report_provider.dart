import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../domain/models/customer_booking_report_model.dart';
import 'api_booking_report_repository.dart';

final customerBookingReportRepositoryProvider =
    Provider<ApiBookingReportRepository>(
      (ref) => ApiBookingReportRepository(ref.watch(dioProvider)),
    );

final customerBookingReportProvider =
    FutureProvider.family<CustomerBookingReport?, String>(
      (ref, bookingId) => ref
          .watch(customerBookingReportRepositoryProvider)
          .getLatestForBooking(bookingId),
    );
