import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../domain/models/customer_wallet_model.dart';

abstract class CustomerWalletDataSource {
  Future<CustomerWallet> getWallet();
}

class ApiCustomerWalletRepository implements CustomerWalletDataSource {
  const ApiCustomerWalletRepository(this._dio);

  final Dio _dio;

  @override
  Future<CustomerWallet> getWallet() async {
    try {
      final walletResponse = await _dio.get<dynamic>('wallet');
      final wallet = _asMap(walletResponse.data);
      final entries = <Map<String, dynamic>>[];
      const limit = 100;
      var offset = 0;
      var total = 0;

      do {
        final response = await _dio.get<dynamic>(
          'wallet/ledger',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _asMap(response.data);
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
}

WalletTransaction _ledgerEntry(Map<String, dynamic> json) {
  final availableDelta = _integer(json['available_delta']);
  final frozenDelta = _integer(json['frozen_delta']);
  final entryType = _string(json['entry_type']);
  final description = _string(json['description']);
  final createdAt = DateTime.tryParse(_string(json['created_at']));
  return WalletTransaction(
    id: _string(json['id']),
    title: description.isEmpty ? _entryLabel(entryType) : description,
    subtitle: _entryLabel(entryType),
    date: createdAt == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal()),
    amount: availableDelta.abs() + frozenDelta.abs(),
    isPositive: availableDelta + frozenDelta >= 0,
    type: WalletTransactionType.ledgerEntry,
    entryType: entryType,
    availableDelta: availableDelta,
    frozenDelta: frozenDelta,
  );
}

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

String _string(Object? value) => value is String ? value : '';

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
