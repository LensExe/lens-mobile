import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/repositories/api_media_upload_repository.dart';
import '../../../../domain/models/customer_booking_report_model.dart';

class ApiBookingReportRepository {
  const ApiBookingReportRepository(this._dio);

  final Dio _dio;

  Future<CustomerBookingReport?> getLatestForBooking(String bookingId) async {
    const limit = 100;
    var offset = 0;
    var total = 0;
    try {
      do {
        final response = await _dio.get<dynamic>(
          'reports/me',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _responseMap(response.data);
        final rawItems = page['items'];
        if (rawItems is! List) {
          throw const ApiException(
            'Backend trả về danh sách report không hợp lệ.',
          );
        }
        for (final rawItem in rawItems) {
          final item = _map(rawItem);
          if (item['target_type'] == 'booking' &&
              item['target_id'] == bookingId) {
            return _reportFromApi(item, bookingId);
          }
        }
        total = _integer(page['total'], offset + rawItems.length);
        if (rawItems.isEmpty) break;
        offset += rawItems.length;
      } while (offset < total);
      return null;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<CustomerBookingReport> createReport({
    required String bookingId,
    required String issueType,
    required String reason,
    required List<String> evidencePaths,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.length < 10 || trimmedReason.length > 10000) {
      throw const ApiException('Mô tả vấn đề cần có từ 10 đến 10.000 ký tự.');
    }
    if (evidencePaths.length > 5) {
      throw const ApiException('Bạn chỉ có thể đính kèm tối đa 5 ảnh.');
    }

    try {
      final mediaRepository = ApiMediaUploadRepository(_dio);
      final mediaIds = <String>[];
      for (final path in evidencePaths) {
        mediaIds.add(await mediaRepository.uploadPrivateImage(path));
      }
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/dispute',
        data: {
          'booking_issue_type': issueType,
          'reason': trimmedReason,
          'evidence_media_ids': mediaIds,
        },
      );
      return _reportFromApi(_responseMap(response.data), bookingId);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

CustomerBookingReport _reportFromApi(
  Map<String, dynamic> item,
  String fallbackBookingId,
) {
  final id = _string(item['id']);
  final bookingId = _string(item['target_id']).isEmpty
      ? fallbackBookingId
      : _string(item['target_id']);
  final status = _string(item['status']);
  if (id.isEmpty || status.isEmpty) {
    throw const ApiException('Backend trả về report không hợp lệ.');
  }
  return CustomerBookingReport(
    id: id,
    bookingId: bookingId,
    issueType: _nullableString(item['booking_issue_type']),
    reason: _string(item['reason']),
    status: status,
    createdAt: DateTime.tryParse(_string(item['created_at'])),
    resolution: _nullableString(item['resolution']),
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  throw const ApiException('Backend trả về dữ liệu report không hợp lệ.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _map(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException('Backend không xác nhận yêu cầu report.');
    }
    payload = _map(payload['data']);
  }
  return payload;
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _nullableString(Object? value) {
  final string = _string(value);
  return string.isEmpty ? null : string;
}

int _integer(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
