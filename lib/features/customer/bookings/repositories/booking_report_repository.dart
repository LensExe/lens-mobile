import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

enum BookingReportCategory {
  photoQuality('photo_quality', 'Chất lượng ảnh chưa đạt'),
  missingDeliverables(
    'missing_deliverables',
    'Thiếu ảnh hoặc sản phẩm bàn giao',
  ),
  lateDelivery('late_delivery', 'Giao ảnh trễ'),
  photographerConduct('photographer_conduct', 'Tác phong hoặc trải nghiệm'),
  bookingMismatch('booking_mismatch', 'Buổi chụp khác thỏa thuận'),
  paymentRefund('payment_refund', 'Thanh toán hoặc hoàn tiền'),
  other('other', 'Vấn đề khác');

  const BookingReportCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class BookingReportReceipt {
  const BookingReportReceipt({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.createdAt,
    this.category,
    this.resolution,
  });

  final String id;
  final String bookingId;
  final String status;
  final String createdAt;
  final String? category;
  final String? resolution;

  factory BookingReportReceipt.fromJson(Map<String, dynamic> json) {
    return BookingReportReceipt(
      id: _requiredString(json['id'], 'id'),
      bookingId: _requiredString(json['target_id'], 'target_id'),
      status: _requiredString(json['status'], 'status'),
      createdAt: _string(json['created_at']),
      category: _nullableString(json['booking_issue_type']),
      resolution: _nullableString(json['resolution']),
    );
  }
}

class BookingReportRepository {
  const BookingReportRepository(this._dio);

  static const maxEvidenceCount = 5;
  static const maxEvidenceBytes = 12 * 1024 * 1024;

  final Dio _dio;

  Future<BookingReportReceipt> createReport({
    required String bookingId,
    required BookingReportCategory category,
    required String reason,
    required List<String> evidenceMediaIds,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        'bookings/$bookingId/dispute',
        data: {
          'booking_issue_type': category.apiValue,
          'reason': reason.trim(),
          'evidence_media_ids': evidenceMediaIds,
        },
      );
      return BookingReportReceipt.fromJson(_responseMap(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<BookingReportReceipt?> latestForBooking(String bookingId) async {
    try {
      const limit = 100;
      var offset = 0;
      var total = 0;

      do {
        final response = await _dio.get<dynamic>(
          'reports/me',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final page = _responseMap(response.data);
        final rawItems = page['items'];
        if (rawItems is! List) {
          throw const ApiException('Danh sách report từ Backend không hợp lệ.');
        }

        final items = rawItems.map(_map).toList(growable: false);
        for (final item in items) {
          if (_string(item['target_type']) == 'booking' &&
              _string(item['target_id']) == bookingId) {
            return BookingReportReceipt.fromJson(item);
          }
        }

        total = _integer(page['total']);
        offset += items.length;
        if (items.isEmpty) break;
      } while (offset < total);

      return null;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadEvidence(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw const ApiException('Ảnh bằng chứng đang trống.');
    if (bytes.length > maxEvidenceBytes) {
      throw const ApiException('Mỗi ảnh bằng chứng phải nhỏ hơn 12 MB.');
    }

    final contentType = _contentType(bytes);
    try {
      final initResponse = await _dio.post<dynamic>(
        'media/upload-url',
        data: {
          'content_type': contentType,
          'file_size': bytes.length,
          'visibility': 'private',
        },
      );
      final init = _responseMap(initResponse.data);
      final media = _map(init['media']);
      final mediaId = _requiredString(media['id'], 'media.id');
      final uploadUrl = _requiredString(init['upload_url'], 'upload_url');

      try {
        await Dio().put<dynamic>(
          uploadUrl,
          data: bytes,
          options: Options(
            contentType: contentType,
            responseType: ResponseType.plain,
            headers: {Headers.contentTypeHeader: contentType},
          ),
        );
      } on DioException catch (error) {
        throw ApiException(
          'Không tải được ảnh bằng chứng lên kho lưu trữ. Vui lòng thử lại.',
          statusCode: error.response?.statusCode,
        );
      }
      await _dio.post<dynamic>(
        'media/complete-upload',
        data: {'media_id': mediaId},
      );

      for (var attempt = 0; attempt < 30; attempt++) {
        final response = await _dio.get<dynamic>('media/$mediaId');
        final mediaState = _responseMap(response.data);
        final status = _string(mediaState['status']);
        if (status == 'ready') return mediaId;
        if (status == 'failed') {
          throw const ApiException('Backend không xử lý được ảnh bằng chứng.');
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      throw const ApiException(
        'Ảnh đang được xử lý lâu hơn dự kiến. Vui lòng thử gửi report lại sau.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final bookingReportRepositoryProvider = Provider<BookingReportRepository>(
  (ref) => BookingReportRepository(ref.watch(dioProvider)),
);

final bookingReportProvider =
    FutureProvider.family<BookingReportReceipt?, String>((ref, bookingId) {
      return ref
          .watch(bookingReportRepositoryProvider)
          .latestForBooking(bookingId);
    });

String _contentType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  throw const ApiException(
    'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP làm bằng chứng.',
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả dữ liệu report không hợp lệ.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _map(value);
  while (payload.containsKey('data')) {
    if (payload['success'] == false) {
      final message = _string(payload['message']);
      throw ApiException(
        message.isEmpty ? 'Backend không xử lý được report.' : message,
      );
    }
    payload = _map(payload['data']);
  }
  return payload;
}

String _string(Object? value) => value?.toString() ?? '';

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả trường $field hợp lệ.');
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int _integer(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value) ?? 0
    : 0;
