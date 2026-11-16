import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import 'api_photographer_detail_repository.dart';
import 'photographer_detail_repository.dart';

final photographerDetailRepositoryProvider =
    Provider<PhotographerDetailRepository>((ref) {
      return ApiPhotographerDetailRepository(ref.watch(dioProvider));
    });
