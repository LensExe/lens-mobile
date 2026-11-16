class FilterCriteria {
  static const double defaultPriceMin = 50000;
  static const double defaultPriceMax = 3000000;

  final String? city;
  final double? minRating;
  final String? searchQuery;
  final List<String> styles;
  final double priceMin;
  final double priceMax;
  final String? experienceBucket;
  final String sort;

  /// [style] remains accepted for existing callers and old discovery URLs.
  FilterCriteria({
    this.city,
    this.minRating,
    this.searchQuery,
    String? style,
    List<String> styles = const [],
    this.priceMin = defaultPriceMin,
    this.priceMax = defaultPriceMax,
    this.experienceBucket,
    this.sort = 'featured',
  }) : styles = List.unmodifiable(
         (styles.isNotEmpty ? styles : (style == null ? const [] : [style]))
             .where((item) => item.trim().isNotEmpty && item != 'Tất cả')
             .toSet(),
       );

  /// Legacy single-style view used by old callers.
  String? get style => styles.length == 1 ? styles.single : null;

  bool get hasNarrowedPriceRange =>
      priceMin > defaultPriceMin || priceMax < defaultPriceMax;

  FilterCriteria copyWith({
    String? city,
    double? minRating,
    String? searchQuery,
    String? style,
    List<String>? styles,
    double? priceMin,
    double? priceMax,
    String? experienceBucket,
    String? sort,
    bool clearCity = false,
    bool clearRating = false,
    bool clearStyle = false,
    bool clearPrice = false,
    bool clearExperience = false,
  }) {
    return FilterCriteria(
      city: clearCity ? null : (city ?? this.city),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      searchQuery: searchQuery ?? this.searchQuery,
      styles: clearStyle
          ? const []
          : (styles ?? (style == null ? this.styles : [style])),
      priceMin: clearPrice ? defaultPriceMin : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? defaultPriceMax : (priceMax ?? this.priceMax),
      experienceBucket: clearExperience
          ? null
          : (experienceBucket ?? this.experienceBucket),
      sort: sort ?? this.sort,
    );
  }
}
