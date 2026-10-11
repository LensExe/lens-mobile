class FilterCriteria {
  final String? city;
  final double? minRating;
  final String? searchQuery;
  final String? style;

  FilterCriteria({
    this.city,
    this.minRating,
    this.searchQuery,
    this.style,
  });

  FilterCriteria copyWith({
    String? city,
    double? minRating,
    String? searchQuery,
    String? style,
    bool clearCity = false,
    bool clearRating = false,
    bool clearStyle = false,
  }) {
    return FilterCriteria(
      city: clearCity ? null : (city ?? this.city),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      searchQuery: searchQuery ?? this.searchQuery,
      style: clearStyle ? null : (style ?? this.style),
    );
  }
}
