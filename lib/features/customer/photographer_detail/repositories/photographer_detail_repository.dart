import '../models/photographer_detail_model.dart';

abstract class PhotographerDetailRepository {
  Future<PhotographerProfile> getPhotographerProfile(String photographerId);
}
