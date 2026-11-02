import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/features/customer/bookings/repositories/api_booking_report_repository.dart';

void main() {
  test('loads the newest report for the requested booking', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/v1/'));
    dio.httpClientAdapter = _Adapter((request) async {
      requests.add(request);
      return _response({
        'success': true,
        'data': {
          'items': [
            {
              'id': 'report-other',
              'target_type': 'booking',
              'target_id': 'booking-other',
              'status': 'open',
            },
            {
              'id': 'report-1',
              'target_type': 'booking',
              'target_id': 'booking-1',
              'booking_issue_type': 'late_delivery',
              'reason': 'Ảnh giao trễ',
              'status': 'resolved',
              'resolution': 'Lens đã xử lý',
              'created_at': '2026-10-10T01:00:00.000Z',
            },
          ],
          'total': 2,
          'limit': 100,
          'offset': 0,
        },
      });
    });

    final report = await ApiBookingReportRepository(dio)
        .getLatestForBooking('booking-1');

    expect(requests.single.uri.path, '/v1/reports/me');
    expect(requests.single.queryParameters, {'limit': 100, 'offset': 0});
    expect(report?.id, 'report-1');
    expect(report?.issueType, 'late_delivery');
    expect(report?.resolution, 'Lens đã xử lý');
  });

  test('creates a booking report with the backend dispute contract', () async {
    const bookingId = '123e4567-e89b-42d3-a456-426614174000';
    RequestOptions? request;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/v1/'));
    dio.httpClientAdapter = _Adapter((options) async {
      request = options;
      return _response({
        'success': true,
        'data': {
          'id': 'report-1',
          'target_type': 'booking',
          'target_id': bookingId,
          'booking_issue_type': 'photo_quality',
          'reason': 'Ảnh bàn giao bị mờ ở nhiều tấm.',
          'status': 'open',
          'created_at': '2026-10-10T01:00:00.000Z',
        },
      });
    });

    final report = await ApiBookingReportRepository(dio).createReport(
      bookingId: bookingId,
      issueType: 'photo_quality',
      reason: '  Ảnh bàn giao bị mờ ở nhiều tấm.  ',
      evidencePaths: const [],
    );

    expect(request?.method, 'POST');
    expect(request?.uri.path, '/v1/bookings/$bookingId/dispute');
    expect(request?.data, {
      'booking_issue_type': 'photo_quality',
      'reason': 'Ảnh bàn giao bị mờ ở nhiều tấm.',
      'evidence_media_ids': <String>[],
    });
    expect(report.status, 'open');
  });
}

ResponseBody _response(Object payload) => ResponseBody.fromString(
  jsonEncode(payload),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions request) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => respond(options);

  @override
  void close({bool force = false}) {}
}
