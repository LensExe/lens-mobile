import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/repositories/discovery_repository_provider.dart';
import 'mock_photographer_detail_repository.dart';
import 'photographer_detail_repository.dart';

final photographerDetailRepositoryProvider =
    Provider<PhotographerDetailRepository>((ref) {
      return MockPhotographerDetailRepository(
        ref.read(discoveryRepositoryProvider),
      );
    });
