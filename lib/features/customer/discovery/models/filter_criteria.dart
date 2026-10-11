class FilterCriteria {
  final String? city;
  final double? minRating;
  final String? searchQuery;

  FilterCriteria({this.city, this.minRating, this.searchQuery});

  FilterCriteria copyWith({
    String? city,
    double? minRating,
    String? searchQuery,
    bool clearCity = false,
    bool clearRating = false,
  }) {
    return FilterCriteria(
      city: clearCity ? null : (city ?? this.city),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
