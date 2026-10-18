import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/vietnam_time.dart';
import '../models/booking_model.dart';
import '../../payments/payment_repository.dart';
import 'booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  const ApiBookingRepository(this._dio);

  final Dio _dio;

  Future<Booking> _bookingWithPayment(
    Map<String, dynamic> json,
    Map<String, dynamic>? profile,
  ) async {
    final id = _requiredString(json['id'], 'id');
    final embeddedPaidAmount = json['paid_amount'];
    final paidAmount = embeddedPaidAmount == null
        ? await BookingPaymentRepository(_dio).getPaidBookingTotal(id)
        : _integer(embeddedPaidAmount);
    return _booking(json, profile, paidAmount: paidAmount);
  }

  @override
  Future<List<Booking>> getBookings() async {
    try {
      final items = <Map<String, dynamic>>[];
      const limit = 100;
      var offset = 0;
      var total = 0;
      do {
        final response = await _dio.get<dynamic>(
          'bookings',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _responseMap(response.data);
        final rawItems = page['items'];
        if (rawItems is! List) {
          throw const ApiException(
            'Backend trả về danh sách booking không hợp lệ.',
          );
        }
        final pageItems = rawItems.map(_map).toList(growable: false);
        items.addAll(pageItems);
        total = _integer(page['total']);
        offset += pageItems.length;
        if (pageItems.isEmpty) break;
      } while (offset < total);

      final photographerIds = items
          .map(
            (item) =>
                _requiredString(item['photographer_id'], 'photographer_id'),
          )
          .toSet();
      final profiles = <String, Map<String, dynamic>>{};
      await Future.wait(
        photographerIds.map((id) async {
          try {
            profiles[id] = _responseMap(
              (await _dio.get<dynamic>('photographers/$id')).data,
            );
          } on DioException {
            // Booking data remains usable if a public profile cannot be loaded.
          }
        }),
      );
      return await Future.wait(
        items.map(
          (item) =>
              _bookingWithPayment(item, profiles[item['photographer_id']]),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    try {
      final response = await _dio.get<dynamic>('bookings/$id');
      return await _bookingWithPayment(_responseMap(response.data), null);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Booking> createBookingFromInput(BookingCreateInput input) async {
    try {
      final response = await _dio.post<dynamic>(
        'bookings',
        data: {
          'photographer_id': input.photographerId,
          'booking_plan_id': input.bookingPlanId,
          'location': input.location,
          'from': _isoWithOffset(input.from),
          'to': _isoWithOffset(input.to),
        },
      );
      return _booking(_responseMap(response.data), {
        'fullname': input.photographerName,
        'avatar_url': input.photographerAvatar,
      });
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Booking> cancelBooking(String bookingId, String reason) async {
    if (reason.trim().isEmpty) {
      throw const ApiException('Vui lòng nhập lý do hủy lịch.');
    }
    try {
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/cancel',
        data: {'reason': reason.trim()},
      );
      return _booking(_responseMap(response.data), null);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<Booking> confirmReceipt(String bookingId) async {
    try {
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/confirm-receipt',
      );
      return _booking(_responseMap(response.data), null);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> createBooking(Booking booking) async {
    final start = _dateTimeFromBooking(booking, start: true);
    final end = _dateTimeFromBooking(booking, start: false);
    await createBookingFromInput(
      BookingCreateInput(
        photographerId: booking.photographerId,
        bookingPlanId: _requiredString(booking.packageId, 'booking_plan_id'),
        location: booking.location,
        from: start,
        to: end,
        photographerName: booking.photographerName,
        photographerAvatar: booking.photographerAvatar ?? '',
      ),
    );
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    if (newStatus == BookingStatus.cancelled) {
      await cancelBooking(bookingId, 'Yêu cầu hủy từ ứng dụng khách hàng.');
      return;
    }
    if (newStatus == BookingStatus.completed ||
        newStatus == BookingStatus.released) {
      await confirmReceipt(bookingId);
      return;
    }
    throw const ApiException('Backend không hỗ trợ thao tác trạng thái này.');
  }

  @override
  Future<void> payRemaining(String bookingId, int coinsRedeemed) async {
    throw const ApiException(
      'Thanh toán cần tạo payment intent và xác nhận trạng thái từ Backend; Lens Xu không được Backend hỗ trợ.',
    );
  }
}

Booking _booking(
  Map<String, dynamic> json,
  Map<String, dynamic>? profile, {
  int paidAmount = 0,
}) {
  final start = VietnamTime.fromInstant(
    DateTime.parse(_requiredString(json['from'], 'from')),
  );
  final end = VietnamTime.fromInstant(
    DateTime.parse(_requiredString(json['to'], 'to')),
  );
  final status = switch (_requiredString(json['status'], 'status')) {
    'pending' =>
      paidAmount >= _integer(json['deposit_amount'])
          ? BookingStatus.pending
          : BookingStatus.awaiting_deposit,
    'accepted' => BookingStatus.accepted,
    'rejected' => BookingStatus.rejected,
    'cancelled' => BookingStatus.cancelled,
    'expired' => BookingStatus.expired,
    'in_progress' => BookingStatus.inProgress,
    'shot' => BookingStatus.shot,
    'completed' => BookingStatus.completed,
    final value => throw ApiException(
      'Backend trả trạng thái booking lạ: $value',
    ),
  };
  return Booking(
    id: _requiredString(json['id'], 'id'),
    clientId: _string(json['customer_id']),
    clientName: '',
    photographerId: _requiredString(json['photographer_id'], 'photographer_id'),
    photographerName: _string(profile?['fullname']),
    photographerAvatar: _string(profile?['avatar_url']),
    style: '',
    date: DateFormat('yyyy-MM-dd').format(start),
    timeSlot:
        '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
    location: _string(json['location']),
    price: _integer(json['total_amount']),
    status: status,
    backendStatus: _requiredString(json['status'], 'status'),
    paidAmount: paidAmount,
    packageId: _string(json['booking_plan_id']),
    packageSnapshot: _packageTerms(json, start, end),
    depositAmount: _integer(json['deposit_amount']),
    depositPaidAt: _nullableString(json['deposit_paid_at']),
    rating: profile == null
        ? null
        : _decimal(_map(profile['rating'])['average_rating']),
    reviewCount: profile == null
        ? null
        : _integer(_map(profile['rating'])['total_feedbacks']),
    galleryPublishedAt: _nullableString(json['gallery_published_at']),
  );
}

PackageTerms? _packageTerms(
  Map<String, dynamic> booking,
  DateTime start,
  DateTime end,
) {
  final snapshot = _optionalMap(booking['package_snapshot']);
  final plan = _optionalMap(booking['booking_plan']);
  if (snapshot.isEmpty && plan.isEmpty) return null;
  final details = {...plan, ...snapshot};
  final photoCount = _integerOrFallback(
    details['photo_count'] ?? details['photoCount'],
    fallback: _integerOrFallback(
      details['retouched_photo_count'] ?? details['retouchedPhotoCount'],
      fallback: 1,
    ),
  );
  final durationMinutes = _integerOrFallback(
    details['duration_minutes'] ?? details['durationMinutes'],
    fallback: end.difference(start).inMinutes,
  );
  final packageName = _string(details['name']);
  return PackageTerms(
    name: packageName.isEmpty ? 'Gói chụp' : packageName,
    photoCount: photoCount > 0 ? photoCount : 1,
    durationHours: (durationMinutes > 0 ? durationMinutes : 60) / 60,
    deliveryDays: _integer(details['delivery_days'] ?? details['deliveryDays']),
  );
}

DateTime _dateTimeFromBooking(Booking booking, {required bool start}) {
  final date = DateTime.parse(booking.date);
  final timeParts = (booking.timeSlot ?? '09:00').split(' - ');
  final time = timeParts[start ? 0 : (timeParts.length > 1 ? 1 : 0)].split(':');
  final hour = int.parse(time[0]);
  final minute = int.parse(time[1]);
  if (!start && timeParts.length == 1) {
    return DateTime.utc(date.year, date.month, date.day, hour, minute).add(
      Duration(
        minutes: ((booking.packageSnapshot?.durationHours ?? 1) * 60).round(),
      ),
    );
  }
  return DateTime.utc(date.year, date.month, date.day, hour, minute);
}

String _isoWithOffset(DateTime value) => VietnamTime.toApiIso(value);

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException(
    'Backend trả về dữ liệu booking không đúng cấu trúc.',
  );
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _map(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw ApiException(
        _string(payload['message']).isEmpty
            ? 'Backend không xác nhận yêu cầu booking thành công.'
            : _string(payload['message']),
      );
    }
    payload = _map(payload['data']);
  }
  return payload;
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

String _string(Object? value) => value?.toString() ?? '';
String? _nullableString(Object? value) => value is String ? value : null;
int _integer(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0
    : 0;
int _integerOrFallback(Object? value, {required int fallback}) {
  final parsed = _integer(value);
  return parsed == 0 ? fallback : parsed;
}

double _decimal(Object? value) => value is num ? value.toDouble() : 0;
Map<String, dynamic> _optionalMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}
