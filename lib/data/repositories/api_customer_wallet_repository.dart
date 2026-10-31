import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../domain/models/customer_wallet_model.dart';

abstract class CustomerWalletDataSource {
  Future<CustomerWallet> getWallet();

  Future<CustomerPayoutDestination> getPayoutDestination();

  Future<CustomerPayoutDestination> savePayoutDestination({
    required String bankCode,
    required String accountNumber,
    required String accountName,
  });

  Future<WalletWithdrawalRequest> requestWithdrawal({
    required int amount,
    required String reason,
    required String idempotencyKey,
  });
}

class ApiCustomerWalletRepository implements CustomerWalletDataSource {
  const ApiCustomerWalletRepository(this._dio);

  final Dio _dio;

  @override
  Future<CustomerWallet> getWallet() async {
    try {
      final walletResponse = await _dio.get<dynamic>('wallet');
      final wallet = _responseMap(walletResponse.data);
      final entries = <Map<String, dynamic>>[];
      const limit = 100;
      var offset = 0;
      var total = 0;

      do {
        final response = await _dio.get<dynamic>(
          'wallet/ledger',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _responseMap(response.data);
        final rawItems = page['items'];
        if (rawItems is! List) {
          throw const ApiException('Backend trả về sổ cái ví không hợp lệ.');
        }
        final pageItems = rawItems.map(_asMap).toList(growable: false);
        entries.addAll(pageItems);
        total = _integer(page['total']);
        offset += pageItems.length;
        if (pageItems.isEmpty) break;
      } while (offset < total);

      return CustomerWallet(
        availableBalance: _integer(wallet['balance']),
        frozenBalance: _integer(wallet['frozen_balance']),
        transactions: entries.map(_ledgerEntry).toList(growable: false),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<CustomerPayoutDestination> getPayoutDestination() async {
    try {
      final response = await _dio.get<dynamic>('wallet/payout-destination');
      return _payoutDestination(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<CustomerPayoutDestination> savePayoutDestination({
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        'wallet/payout-destination',
        data: {
          'bank_code': bankCode.trim(),
          'account_number': accountNumber.trim(),
          'account_name': accountName.trim(),
        },
      );
      return _payoutDestination(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<WalletWithdrawalRequest> requestWithdrawal({
    required int amount,
    required String reason,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        'wallet/withdrawals',
        data: {
          'amount': amount,
          'reason': reason.trim(),
          'idempotency_key': idempotencyKey,
        },
      );
      final request = _responseMap(response.data);
      final id = _string(request['id']);
      final requestAmount = _integer(request['amount']);
      final status = _string(request['status']);
      if (id.isEmpty || requestAmount <= 0 || status.isEmpty) {
        throw const ApiException(
          'Backend trả về yêu cầu rút tiền không hợp lệ.',
        );
      }
      return WalletWithdrawalRequest(
        id: id,
        amount: requestAmount,
        status: status,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

WalletTransaction _ledgerEntry(Map<String, dynamic> json) {
  final availableDelta = _integer(json['available_delta']);
  final frozenDelta = _integer(json['frozen_delta']);
  final entryType = _string(json['entry_type']);
  final description = _string(json['description']);
  final createdAt = DateTime.tryParse(_string(json['created_at']));
  final transaction = _optionalMap(json['transaction']);
  final booking = _optionalMap(json['booking']);
  return WalletTransaction(
    id: _string(json['id']),
    title: description.isEmpty ? _entryLabel(entryType) : description,
    subtitle: _entryLabel(entryType),
    date: createdAt == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal()),
    amount: availableDelta != 0 ? availableDelta : frozenDelta,
    isPositive: availableDelta + frozenDelta >= 0,
    type: WalletTransactionType.ledgerEntry,
    entryType: entryType,
    availableDelta: availableDelta,
    frozenDelta: frozenDelta,
    bookingId: _nullableString(booking['id']),
    bookingStatus: _nullableString(booking['status']),
    bookingFrom: _nullableString(booking['from']),
    bookingTo: _nullableString(booking['to']),
    bookingPackageName: _nullableString(booking['package_name']),
    transactionCode: _nullableString(transaction['transaction_code']),
    transactionStatus: _nullableString(transaction['status']),
    paymentGateway: _nullableString(transaction['payment_gateway']),
  );
}

CustomerPayoutDestination _payoutDestination(Map<String, dynamic> json) =>
    CustomerPayoutDestination(
      isConfigured: json['is_configured'] == true,
      bankCode: _nullableString(json['bank_code']),
      accountName: _nullableString(json['account_name']),
      accountNumberMasked: _nullableString(json['account_number_masked']),
      updatedAt: DateTime.tryParse(_string(json['updated_at'])),
    );

Map<String, dynamic> _optionalMap(Object? value) =>
    value is Map ? _asMap(value) : <String, dynamic>{};

String? _nullableString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

String _entryLabel(String value) => switch (value) {
  'topup' => 'Nạp ví',
  'booking_payment' => 'Thanh toán booking',
  'booking_escrow_hold' => 'Tiền được giữ cho booking',
  'booking_escrow_release' => 'Giải ngân booking',
  'refund_reserve' => 'Dự trữ hoàn tiền',
  'refund_credit' => 'Hoàn tiền',
  'refund_debit' => 'Điều chỉnh hoàn tiền',
  'withdrawal_reserve' => 'Yêu cầu rút tiền',
  'withdrawal_release' => 'Hoàn lại yêu cầu rút tiền',
  'withdrawal_paid' => 'Rút tiền',
  '' => 'Biến động ví',
  _ => value,
};

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu ví không đúng cấu trúc.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _asMap(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException('Backend không xác nhận dữ liệu ví.');
    }
    payload = _asMap(payload['data']);
  }
  return payload;
}

String _string(Object? value) => value is String ? value : '';

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
