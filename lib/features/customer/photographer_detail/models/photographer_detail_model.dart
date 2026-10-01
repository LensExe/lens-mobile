class PortfolioItem {
  final String id;
  final String imageUrl;
  final String title;
  final String style; // 'Thời trang', 'Chân dung', 'Đường phố', 'Cưới', 'Phim 35mm', 'Sự kiện'
  final String
  subtitle; // e.g. "Harper's Bazaar Vietnam • Fall Cover", "The Row Lookbook"
  final String
  cameraGear; // e.g. "Sony A7R V", "Leica M11 • 35mm", "Profoto D2 • 85mm"
  final bool isFeatured; // Hero card or grid card

  const PortfolioItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.style,
    required this.subtitle,
    required this.cameraGear,
    this.isFeatured = false,
  });
}

class ProfilePackage {
  final String id;
  final String name;
  final String subtitle;
  final int price;
  final String duration;
  final List<String> deliverables;
  final bool isMostSelected;
  final int? photoCount;
  final int? deliveryDays;
  final String
  highlightBadge; // e.g. "Được chọn nhiều nhất", "Sản xuất chuyên nghiệp"

  const ProfilePackage({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.deliverables,
    this.isMostSelected = false,
    this.photoCount,
    this.deliveryDays,
    this.highlightBadge = '',
  });
}

class ClientReview {
  final String id;
  final String clientName;
  final String clientRole; // e.g. "Giám đốc Sáng tạo • The Row VN"
  final String clientInitials; // e.g. "MC"
  final double rating;
  final String timeAgo; // e.g. "2 ngày trước"
  final String packageTag; // e.g. "Lookbook Thời Trang"
  final String content;

  const ClientReview({
    required this.id,
    required this.clientName,
    required this.clientRole,
    required this.clientInitials,
    required this.rating,
    required this.timeAgo,
    required this.packageTag,
    required this.content,
  });
}

class StudioGearInfo {
  final List<String> cameraBodies;
  final List<String> lightingModifiers;
  final String studioAddress;
  final String insuranceNotice;

  const StudioGearInfo({
    required this.cameraBodies,
    required this.lightingModifiers,
    required this.studioAddress,
    required this.insuranceNotice,
  });
}

class PhotographerProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final String coverImageUrl;
  final String city;
  final String rank; // 'PRO GOLD', 'PRO', 'STUDIO'
  final double rating;
  final int reviewCount;
  final int startingPrice;
  final String bio;
  final int experienceYears;
  final int completedShoots;
  final int completionRate;
  final bool isVerified;
  final bool isInsured;
  final String verificationBadge;
  final List<String> styles;
  final List<PortfolioItem> portfolio;
  final List<ProfilePackage> packages;
  final List<ClientReview> reviews;
  final StudioGearInfo gearInfo;

  const PhotographerProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.coverImageUrl,
    required this.city,
    this.rank = 'PRO GOLD',
    required this.rating,
    required this.reviewCount,
    required this.startingPrice,
    required this.bio,
    required this.experienceYears,
    required this.completedShoots,
    this.completionRate = 100,
    this.isVerified = true,
    this.isInsured = true,
    this.verificationBadge = 'Studio Đã Xác Minh & Bảo Hiểm',
    required this.styles,
    required this.portfolio,
    required this.packages,
    required this.reviews,
    required this.gearInfo,
  });

  PhotographerProfile copyWith({double? rating, int? reviewCount}) =>
      PhotographerProfile(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        coverImageUrl: coverImageUrl,
        city: city,
        rank: rank,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        startingPrice: startingPrice,
        bio: bio,
        experienceYears: experienceYears,
        completedShoots: completedShoots,
        completionRate: completionRate,
        isVerified: isVerified,
        isInsured: isInsured,
        verificationBadge: verificationBadge,
        styles: styles,
        portfolio: portfolio,
        packages: packages,
        reviews: reviews,
        gearInfo: gearInfo,
      );
}
