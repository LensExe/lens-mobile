import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';

abstract class PhotographerRepository {
  Future<List<PhotographerModel>> getPhotographers({FilterCriteria? criteria});
  Future<void> recordReview(String photographerId, double rating);

  Future<PhotographerPage> getPhotographersPage({
    FilterCriteria? criteria,
    required int limit,
    required int offset,
    bool topRated = false,
  });
}

class PhotographerPage {
  const PhotographerPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<PhotographerModel> items;
  final int total;
  final int limit;
  final int offset;
}
