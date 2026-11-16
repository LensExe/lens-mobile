import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

class BookingGalleryItem {
  const BookingGalleryItem({
    required this.mediaId,
    required this.thumbnailUrl,
    required this.contentType,
    required this.fileSize,
  });

  final String mediaId;
  final String thumbnailUrl;
  final String contentType;
  final int fileSize;
}

class BookingGallery {
  const BookingGallery({required this.items, this.publishedAt});
  final List<BookingGalleryItem> items;
  final String? publishedAt;
}

class BookingGalleryRepository {
  const BookingGalleryRepository(this._dio);
  final Dio _dio;

  Future<BookingGallery> getPublishedGallery(String bookingId) async {
    try {
      final response = await _dio.get<dynamic>('bookings/$bookingId/gallery');
      final data = _responseMap(response.data);
      return BookingGallery(
        publishedAt: _string(data['published_at']),
        items: _items(data['items'])
            .map((item) {
              final json = _map(item);
              return BookingGalleryItem(
                mediaId: _requiredString(
                  json['media_id'] ?? json['id'],
                  'gallery.media_id',
                ),
                thumbnailUrl: _requiredString(
                  json['thumbnail_url'],
                  'gallery.thumbnail_url',
                ),
                contentType: _string(json['content_type']),
                fileSize: _int(json['file_size']),
              );
            })
            .toList(growable: false),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> getDownloadUrl({
    required String bookingId,
    required String mediaId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'bookings/$bookingId/gallery/download',
      );
      final data = _responseMap(response.data);
      for (final item in _items(data['items'])) {
        final json = _map(item);
        if (_string(json['media_id'] ?? json['id']) == mediaId) {
          return _requiredString(json['download_url'], 'download_url');
        }
      }
      throw const ApiException('Backend không trả link tải ảnh này.');
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả gallery không đúng cấu trúc.');
}

List<Object?> _items(Object? value) => value is List ? value : const [];
String _string(Object? value) => value?.toString() ?? '';
String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả trường $field hợp lệ.');
}

int _int(Object? value) => value is num
    ? value.toInt()
    : value is String
    ? int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0
    : 0;

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _map(value);
  while (payload.containsKey('data')) {
    if (payload['success'] == false) {
      final message = _string(payload['message']);
      throw ApiException(
        message.isEmpty ? 'Backend không trả gallery thành công.' : message,
      );
    }
    payload = _map(payload['data']);
  }
  return payload;
}

final bookingGalleryRepositoryProvider = Provider<BookingGalleryRepository>(
  (ref) => BookingGalleryRepository(ref.watch(dioProvider)),
);

final bookingGalleryProvider = FutureProvider.family<BookingGallery, String>(
  (ref, bookingId) => ref
      .watch(bookingGalleryRepositoryProvider)
      .getPublishedGallery(bookingId),
);
