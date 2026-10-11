import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import 'api_photographer_repository.dart';
import 'photographer_repository.dart';

final discoveryRepositoryProvider = Provider<PhotographerRepository>((ref) {
  return ApiPhotographerRepository(ref.watch(dioProvider));
});
