import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

enum BookingPaymentType { deposit, remaining }

enum BookingPaymentMethod { gateway, wallet }

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    this.type,
    this.checkoutUrl,
    this.qrCode,
    this.checkoutExpiresAt,
  });

  final String id;
  final String status;
  final int amount;
  final String currency;
  final String? type;
  final String? checkoutUrl;
  final String? qrCode;
  final String? checkoutExpiresAt;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    id: _requiredString(json['id'], 'id'),
    status: _requiredString(json['status'], 'status'),
    amount: _int(json['amount']),
    currency: json['currency']?.toString() ?? 'VND',
    type: _nullableString(json['type']),
    checkoutUrl: _nullableString(json['checkout_url']),
    qrCode: _nullableString(json['qr_code']),
    checkoutExpiresAt: _nullableString(json['checkout_expires_at']),
  );
}

class PaymentHistory {
  const PaymentHistory({required this.items});
  final List<PaymentIntent> items;
}

class BookingPaymentRepository {
  const BookingPaymentRepository(this._dio);
  final Dio _dio;

  Future<PaymentIntent> createIntent({
    required String bookingId,
    required BookingPaymentType type,
    required BookingPaymentMethod method,
  }) async {
    final action = type == BookingPaymentType.deposit ? 'deposit' : 'remaining';
    try {
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/payments/$action',
        data: {
          'idempotency_key': 'lens-mobile:$bookingId:$action',
          'payment_method': method.name,
        },
      );
      return PaymentIntent.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaymentHistory> getBookingHistory(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>('bookings/$bookingId/payments');
      final data = _map(response.data);
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

  Future<PaymentIntent> getPayment(String paymentId) async {
    try {
      final response = await _dio.get<dynamic>('payments/$paymentId');
      return PaymentIntent.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PaymentIntent> getPaymentQr(String paymentId) async {
    try {
      final response = await _dio.get<dynamic>('payments/$paymentId/qr');
      return PaymentIntent.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<int> getPaidBookingTotal(String bookingId) async {
    final history = await getBookingHistory(bookingId);
    return history.items
        .where(
          (payment) =>
              payment.status == 'paid' &&
              (payment.type == 'deposit' || payment.type == 'remaining'),
        )
        .fold<int>(0, (total, payment) => total + payment.amount);
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException(
    'Backend trả về dữ liệu thanh toán không đúng cấu trúc.',
  );
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

String? _nullableString(Object? value) => value is String ? value : null;
int _int(Object? value) => value is num ? value.toInt() : 0;

final bookingPaymentRepositoryProvider = Provider<BookingPaymentRepository>(
  (ref) => BookingPaymentRepository(ref.watch(dioProvider)),
);

final bookingPaidTotalProvider = FutureProvider.family<int, String>(
  (ref, bookingId) => ref
      .watch(bookingPaymentRepositoryProvider)
      .getPaidBookingTotal(bookingId),
);
