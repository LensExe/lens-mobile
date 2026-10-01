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
  final Experience experience;
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
    required this.experience,
    required this.styles,
    required this.availableDates,
  });

  PhotographerModel copyWith({double? rating, int? reviewCount}) =>
      PhotographerModel(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        coverImageUrl: coverImageUrl,
        city: city,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        pricePerSession: pricePerSession,
        isFeatured: isFeatured,
        isVerified: isVerified,
        experience: experience,
        styles: styles,
        availableDates: availableDates,
      );
}
