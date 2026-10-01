import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';

abstract class DeliveryMediaRepository {
  Future<void> saveImage({required String url, required String name});
}

class MockDeliveryMediaRepository implements DeliveryMediaRepository {
  final Dio _dio;

  MockDeliveryMediaRepository({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<void> saveImage({required String url, required String name}) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      throw StateError('Ảnh không hợp lệ.');
    }
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) throw StateError('Ảnh trống.');
    if (!await Gal.requestAccess()) throw StateError('Chưa có quyền lưu ảnh.');
    await Gal.putImageBytes(
      Uint8List.fromList(bytes),
      album: 'LENS',
      name: name,
    );
  }
}

final deliveryMediaRepositoryProvider = Provider<DeliveryMediaRepository>((
  ref,
) {
  return MockDeliveryMediaRepository();
});
