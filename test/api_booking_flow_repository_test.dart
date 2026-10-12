import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lens_app/features/customer/bookings/repositories/booking_gallery_repository.dart';
import 'package:lens_app/features/customer/payments/payment_repository.dart';

void main() {
  const bookingId = '61ce08cf-2d44-4f59-bc54-4033a8eec025';

  test('unwraps Backend envelope for published booking gallery', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/v1/'));
    dio.httpClientAdapter = _Adapter((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/bookings/$bookingId/gallery');
      return _response({
        'success': true,
        'statusCode': 200,
        'data': {
          'id': bookingId,
          'published_at': '2026-10-10T03:00:00.000Z',
          'items': [
            {
              'id': 'delivery-item-id',
              'media_id': 'media-id',
              'thumbnail_url': 'https://cdn.example.test/thumb.jpg',
              'content_type': 'image/jpeg',
              'file_size': '2048',
            },
          ],
        },
        'timestamp': '2026-10-10T03:01:00.000Z',
      });
    });

    final gallery = await BookingGalleryRepository(dio)
        .getPublishedGallery(bookingId);

    expect(gallery.publishedAt, '2026-10-10T03:00:00.000Z');
    expect(gallery.items, hasLength(1));
    expect(gallery.items.single.mediaId, 'media-id');
    expect(gallery.items.single.fileSize, 2048);
  });

  test(
    'unwraps Backend envelope when requesting gallery download URLs',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/v1/'));
      dio.httpClientAdapter = _Adapter((request) async {
        expect(request.uri.path, '/v1/bookings/$bookingId/gallery/download');
        return _response({
          'success': true,
          'statusCode': 200,
          'data': {
            'items': [
              {
                'media_id': 'media-id',
                'download_url': 'https://cdn.example.test/download.jpg',
              },
            ],
          },
          'timestamp': '2026-10-10T03:01:00.000Z',
        });
      });

      final url = await BookingGalleryRepository(dio)
          .getDownloadUrl(bookingId: bookingId, mediaId: 'media-id');

      expect(url, 'https://cdn.example.test/download.jpg');
    },
  );

  test('creates the deposit intent with the Backend contract', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/v1/'));
    dio.httpClientAdapter = _Adapter((request) async {
      captured = request;
      return _response({
        'success': true,
        'statusCode': 200,
        'data': {
          'id': 'payment-id',
          'status': 'pending',
          'amount': '360000',
          'currency': 'VND',
          'type': 'deposit',
          'payment_gateway': 'payos',
        },
        'timestamp': '2026-10-10T03:01:00.000Z',
      });
    });

    final intent = await BookingPaymentRepository(dio).createIntent(
      bookingId: bookingId,
      type: BookingPaymentType.deposit,
      method: BookingPaymentMethod.gateway,
    );

    expect(captured?.method, 'POST');
    expect(captured?.uri.path, '/v1/bookings/$bookingId/payments/deposit');
    expect(captured?.data, {
      'idempotency_key': 'lens-mobile:$bookingId:deposit',
      'payment_method': 'gateway',
    });
    expect(intent.id, 'payment-id');
    expect(intent.amount, 360000);
    expect(intent.status, 'pending');
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
