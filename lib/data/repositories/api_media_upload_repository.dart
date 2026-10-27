import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';

class ApiMediaUploadRepository {
  ApiMediaUploadRepository(this._apiDio, {Dio? storageDio})
    : _storageDio = storageDio ?? _newStorageDio();

  final Dio _apiDio;
  final Dio _storageDio;

  Future<String> uploadPublicImage(String localPath) async {
    final file = File(localPath);
    final contentType = _contentType(localPath);
    final fileSize = await _fileSize(file);
    if (fileSize < 1 || fileSize > 104857600) {
      throw const ApiException('Ảnh phải có dung lượng từ 1 byte đến 100 MB.');
    }

    try {
      final reservationResponse = await _apiDio.post<dynamic>(
        'media/upload-url',
        data: {
          'content_type': contentType,
          'file_size': fileSize,
          'visibility': 'public',
        },
      );
      final reservation = _responseMap(reservationResponse.data);
      final media = _asMap(reservation['media']);
      final mediaId = _requiredString(media['id'], 'media.id');
      final uploadUrl = _requiredString(
        reservation['upload_url'],
        'upload_url',
      );
      final parsedUploadUrl = Uri.tryParse(uploadUrl);
      if (parsedUploadUrl == null || parsedUploadUrl.scheme != 'https') {
        throw const ApiException('Backend trả về URL tải ảnh không an toàn.');
      }

      final bytes = await file.readAsBytes();
      await _storageDio.put<dynamic>(
        uploadUrl,
        data: bytes,
        options: Options(
          contentType: contentType,
          headers: {'Content-Type': contentType},
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      await _apiDio.post<dynamic>(
        'media/complete-upload',
        data: {'media_id': mediaId},
      );

      for (var attempt = 0; attempt < 40; attempt++) {
        final mediaResponse = await _apiDio.get<dynamic>('media/$mediaId');
        final uploadedMedia = _responseMap(mediaResponse.data);
        final status = uploadedMedia['status']?.toString().toLowerCase();
        if (status == 'ready') {
          final imageUrl = _string(
            uploadedMedia['preview_url'] ?? uploadedMedia['download_url'],
          );
          if (imageUrl.isEmpty || Uri.tryParse(imageUrl)?.scheme != 'https') {
            throw const ApiException(
              'Backend chưa cung cấp URL ảnh đại diện hợp lệ.',
            );
          }
          return imageUrl;
        }
        if (status == 'failed' || status == 'deleted') {
          throw const ApiException('Backend không xử lý được ảnh đã tải lên.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }
      throw const ApiException(
        'Ảnh vẫn đang được xử lý. Vui lòng thử lại sau ít phút.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Dio _newStorageDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  Future<int> _fileSize(File file) async {
    try {
      return await file.length();
    } on FileSystemException {
      throw const ApiException('Không thể đọc ảnh đã chọn. Hãy chọn lại ảnh.');
    }
  }

  String _contentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw const ApiException('Chỉ hỗ trợ ảnh JPG, PNG hoặc WebP.'),
    };
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  throw const ApiException('Backend trả về dữ liệu media không hợp lệ.');
}

Map<String, dynamic> _responseMap(Object? value) {
  var payload = _asMap(value);
  while (payload.containsKey('success') && payload.containsKey('data')) {
    if (payload['success'] != true) {
      throw const ApiException('Backend không xác nhận yêu cầu tải ảnh.');
    }
    payload = _asMap(payload['data']);
  }
  return payload;
}

String _requiredString(Object? value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw ApiException('Backend không trả về trường $field hợp lệ.');
}

String _string(Object? value) => value is String ? value.trim() : '';
