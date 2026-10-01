import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';

abstract class PhotographerRepository {
  Future<List<PhotographerModel>> getPhotographers({
    FilterCriteria? criteria,
    SortOption sort = SortOption.featured,
  });
  Future<void> recordReview(String photographerId, double rating);
}
