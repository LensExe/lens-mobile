import '../models/photographer_detail_model.dart';

abstract class PhotographerDetailRepository {
  Future<PhotographerProfile> getPhotographerProfile(String photographerId);

  Future<List<AvailabilityRange>> getAvailability({
    required String photographerId,
    required DateTime from,
    required DateTime to,
  });
}

class AvailabilityRange {
  const AvailabilityRange({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}
