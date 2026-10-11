import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/photographer_model.dart';
import '../utils/photographer_cover_resolver.dart';
import 'api_photographer_repository.dart';

class CustomerRecommendationsRepository {
  const CustomerRecommendationsRepository(this._dio);

  final Dio _dio;

  Future<List<PhotographerModel>> getRecommendations({int limit = 6}) async {
    try {
      final response = await _dio.get<dynamic>(
        'customers/me/recommendations',
        queryParameters: {'limit': limit, 'offset': 0},
      );
      final page = _map(response.data);
      final items = page['items'];
      if (items is! List) {
        throw const ApiException(
          'Backend trả về danh sách gợi ý không hợp lệ.',
        );
      }
      final basePhotographers = items
          .map((item) => photographerFromApi(_map(item)))
          .toList(growable: false);

      return await Future.wait(
        basePhotographers.map(
          (p) => PhotographerCoverResolver.resolveWithCover(_dio, p),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw const ApiException('Backend trả về dữ liệu gợi ý không đúng cấu trúc.');
}

final customerRecommendationsRepositoryProvider =
    Provider<CustomerRecommendationsRepository>(
      (ref) => CustomerRecommendationsRepository(ref.watch(dioProvider)),
    );

final customerRecommendationsProvider = FutureProvider<List<PhotographerModel>>(
  (ref) =>
      ref.watch(customerRecommendationsRepositoryProvider).getRecommendations(),
);
