import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_photographer_repository.dart';
import 'photographer_repository.dart';

final discoveryRepositoryProvider = Provider<PhotographerRepository>((ref) {
  return MockPhotographerRepository();
});
