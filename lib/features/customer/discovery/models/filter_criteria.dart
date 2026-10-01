import 'photographer_model.dart';

enum SortOption { featured, rating, priceAsc, priceDesc, reviewCount }

class FilterCriteria {
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? availableDate;
  final double? minRating;
  final Experience? experience;
  final String? searchQuery;
  final List<String> styles;

  FilterCriteria({
    this.city,
    this.minPrice,
    this.maxPrice,
    this.availableDate,
    this.minRating,
    this.experience,
    this.searchQuery,
    this.styles = const [],
  });

  FilterCriteria copyWith({
    String? city,
    double? minPrice,
    double? maxPrice,
    DateTime? availableDate,
    double? minRating,
    Experience? experience,
    String? searchQuery,
    List<String>? styles,
    bool clearDate = false,
    bool clearExperience = false,
    bool clearCity = false,
    bool clearRating = false,
  }) {
    return FilterCriteria(
      city: clearCity ? null : (city ?? this.city),
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      availableDate: clearDate ? null : (availableDate ?? this.availableDate),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      experience: clearExperience ? null : (experience ?? this.experience),
      searchQuery: searchQuery ?? this.searchQuery,
      styles: styles ?? this.styles,
    );
  }
}
