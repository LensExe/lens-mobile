import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

enum BookingPaymentType { deposit, remaining }

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.status,
    required this.amount,
    this.type,
  });

  final String id;
  final String status;
  final int amount;
  final String? type;

  bool get isSettled => status.toLowerCase() == 'paid';

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    id: _requiredString(json['id'], 'id'),
    status: _requiredString(json['status'], 'status'),
    amount: _int(json['amount']),
    type: _nullableString(json['type']),
  );
}

class PaymentHistory {
  const PaymentHistory({required this.items});
  final List<PaymentIntent> items;
}

class BookingPaymentRepository {
  const BookingPaymentRepository(this._dio);
  final Dio _dio;

  Future<String> createMobileCheckoutHandoff({
    required String bookingId,
    required BookingPaymentType type,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        'mobile-checkout/handoff',
        data: {
          'booking_id': bookingId,
          'payment_purpose': type == BookingPaymentType.deposit
              ? 'deposit'
              : 'remaining',
        },
      );
      return _requiredString(
        _responseMap(response.data)['checkout_url'],
        'checkout_url',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaymentHistory> getBookingHistory(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>('bookings/$bookingId/payments');
      final data = _responseMap(response.data);
      final raw = data['items'];
      if (raw is! List) {
        throw const ApiException(
          'Backend trả về lịch sử thanh toán không hợp lệ.',
        );
      }
      return PaymentHistory(
        items: raw.map((item) => PaymentIntent.fromJson(_map(item))).toList(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> getPaidBookingTotal(String bookingId) async {
    final history = await getBookingHistory(bookingId);
    final netPaid = history.items.fold<int>(0, (total, payment) {
      if (!payment.isSettled) return total;
      return switch (payment.type?.toLowerCase()) {
        'deposit' || 'remaining' => total + payment.amount,
        'refund' => total - payment.amount,
        _ => total,
      };
    });
    return netPaid < 0 ? 0 : netPaid;
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException(
    'Backend trả về dữ liệu thanh toán không đúng cấu trúc.',
  );
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _map(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw ApiException(
        'Backend không xác nhận yêu cầu thanh toán thành công.',
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

String? _nullableString(Object? value) => value is String ? value : null;
int _int(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0
    : 0;

final bookingPaymentRepositoryProvider = Provider<BookingPaymentRepository>(
  (ref) => BookingPaymentRepository(ref.watch(dioProvider)),
);

final bookingPaidTotalProvider = FutureProvider.family<int, String>(
  (ref, bookingId) => ref
      .watch(bookingPaymentRepositoryProvider)
      .getPaidBookingTotal(bookingId),
);
