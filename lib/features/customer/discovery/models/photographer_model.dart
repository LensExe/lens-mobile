enum Experience { under1Year, from1To3Years, from3To5Years, over5Years }

class PhotographerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String coverImageUrl;
  final String city;
  final double rating;
  final int reviewCount;
  final double pricePerSession;
  final bool isFeatured;
  final bool isVerified;
  final Experience? experience;
  final List<String> styles;
  final List<DateTime> availableDates;

  PhotographerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.coverImageUrl,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.pricePerSession,
    required this.isFeatured,
    required this.isVerified,
    this.experience,
    required this.styles,
    required this.availableDates,
  });

  PhotographerModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? coverImageUrl,
    String? city,
    double? rating,
    int? reviewCount,
    double? pricePerSession,
    bool? isFeatured,
    bool? isVerified,
    Experience? experience,
    List<String>? styles,
    List<DateTime>? availableDates,
  }) =>
      PhotographerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        city: city ?? this.city,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        pricePerSession: pricePerSession ?? this.pricePerSession,
        isFeatured: isFeatured ?? this.isFeatured,
        isVerified: isVerified ?? this.isVerified,
        experience: experience ?? this.experience,
        styles: styles ?? this.styles,
        availableDates: availableDates ?? this.availableDates,
      );
}
