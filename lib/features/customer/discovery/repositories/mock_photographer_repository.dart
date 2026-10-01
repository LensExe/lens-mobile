import '../models/filter_criteria.dart';
import '../models/photographer_model.dart';
import 'photographer_repository.dart';
import '../../../../core/utils/vietnamese_text.dart';

class MockPhotographerRepository implements PhotographerRepository {
  // Khi có REST API / GraphQL, chỉ cần tạo file ApiPhotographerRepository.dart implements PhotographerRepository và inject vào UI

  final List<PhotographerModel> _mockData = [
    PhotographerModel(
      id: 'p1',
      name: 'Minh Hà Studio',
      avatarUrl: 'https://i.pravatar.cc/150?u=minhha',
      coverImageUrl: 'https://images.unsplash.com/photo-1554080353-a576cf803bda?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rating: 4.98,
      reviewCount: 124,
      pricePerSession: 2800000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Thời trang', 'Chân dung'],
      availableDates: [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 3)),
      ],
    ),
    PhotographerModel(
      id: 'p2',
      name: 'Elena Rostova',
      avatarUrl: 'https://i.pravatar.cc/150?u=elena',
      coverImageUrl: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rating: 4.98,
      reviewCount: 64,
      pricePerSession: 2800000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Thời trang', 'Chân dung'],
      availableDates: [
        DateTime.now().add(const Duration(days: 2)),
        DateTime.now().add(const Duration(days: 5)),
      ],
    ),
    PhotographerModel(
      id: 'p3',
      name: 'Khải Nguyễn',
      avatarUrl: 'https://i.pravatar.cc/150?u=khai',
      coverImageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80',
      city: 'Đà Nẵng',
      rating: 5.0,
      reviewCount: 210,
      pricePerSession: 3200000,
      isFeatured: false,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Kiến trúc', 'Đường phố'],
      availableDates: [DateTime.now().add(const Duration(days: 1))],
    ),
    PhotographerModel(
      id: 'p4',
      name: 'Lan Anh Photo',
      avatarUrl: 'https://i.pravatar.cc/150?u=lananh',
      coverImageUrl: 'https://images.unsplash.com/photo-1537151608804-ea2f1fa56801?auto=format&fit=crop&q=80',
      city: 'Đà Lạt',
      rating: 4.8,
      reviewCount: 45,
      pricePerSession: 1500000,
      isFeatured: false,
      isVerified: false,
      experience: Experience.from1To3Years,
      styles: ['Cưới', 'Gia đình'],
      availableDates: [
        DateTime.now().add(const Duration(days: 4)),
        DateTime.now().add(const Duration(days: 6)),
      ],
    ),
    PhotographerModel(
      id: 'p5',
      name: 'Tuấn Đạt',
      avatarUrl: 'https://i.pravatar.cc/150?u=tuandat',
      coverImageUrl: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rating: 4.6,
      reviewCount: 32,
      pricePerSession: 1200000,
      isFeatured: false,
      isVerified: true,
      experience: Experience.from1To3Years,
      styles: ['Sản phẩm', 'Ẩm thực'],
      availableDates: [DateTime.now().add(const Duration(days: 2))],
    ),
    PhotographerModel(
      id: 'p6',
      name: 'Thanh Hằng',
      avatarUrl: 'https://i.pravatar.cc/150?u=thanhhang',
      coverImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80',
      city: 'Cần Thơ',
      rating: 4.9,
      reviewCount: 150,
      pricePerSession: 2000000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.from3To5Years,
      styles: ['Du lịch', 'Chân dung'],
      availableDates: [
        DateTime.now().add(const Duration(days: 5)),
        DateTime.now().add(const Duration(days: 7)),
      ],
    ),
    PhotographerModel(
      id: 'p7',
      name: 'Hoàng Vũ',
      avatarUrl: 'https://i.pravatar.cc/150?u=hoangvu',
      coverImageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80',
      city: 'Hải Phòng',
      rating: 4.5,
      reviewCount: 20,
      pricePerSession: 800000,
      isFeatured: false,
      isVerified: false,
      experience: Experience.under1Year,
      styles: ['Đường phố', 'Sự kiện'],
      availableDates: [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 2)),
      ],
    ),
    PhotographerModel(
      id: 'p8',
      name: 'Ngọc Diệp Studio',
      avatarUrl: 'https://i.pravatar.cc/150?u=ngocdiep',
      coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80',
      city: 'Hà Nội',
      rating: 4.92,
      reviewCount: 88,
      pricePerSession: 2500000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Cưới', 'Thời trang'],
      availableDates: [DateTime.now().add(const Duration(days: 8))],
    ),
    PhotographerModel(
      id: 'p9',
      name: 'Bảo Minh',
      avatarUrl: 'https://i.pravatar.cc/150?u=baominh',
      coverImageUrl: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&q=80',
      city: 'Đà Nẵng',
      rating: 4.7,
      reviewCount: 65,
      pricePerSession: 1800000,
      isFeatured: false,
      isVerified: true,
      experience: Experience.from3To5Years,
      styles: ['Chân dung', 'Gia đình'],
      availableDates: [DateTime.now().add(const Duration(days: 3))],
    ),
    PhotographerModel(
      id: 'p10',
      name: 'Lê Khoa',
      avatarUrl: 'https://i.pravatar.cc/150?u=lekhoa',
      coverImageUrl: 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rating: 4.4,
      reviewCount: 12,
      pricePerSession: 900000,
      isFeatured: false,
      isVerified: false,
      experience: Experience.under1Year,
      styles: ['Sự kiện'],
      availableDates: [
        DateTime.now().add(const Duration(days: 2)),
        DateTime.now().add(const Duration(days: 4)),
      ],
    ),
    PhotographerModel(
      id: 'p11',
      name: 'Kim Ngân',
      avatarUrl: 'https://i.pravatar.cc/150?u=kimngan',
      coverImageUrl: 'https://images.unsplash.com/photo-1481824429379-07aa5e5b0739?auto=format&fit=crop&q=80',
      city: 'Hà Nội',
      rating: 4.85,
      reviewCount: 92,
      pricePerSession: 2200000,
      isFeatured: false,
      isVerified: true,
      experience: Experience.from3To5Years,
      styles: ['Thời trang', 'Sản phẩm'],
      availableDates: [DateTime.now().add(const Duration(days: 5))],
    ),
    PhotographerModel(
      id: 'p12',
      name: 'Phúc Anh',
      avatarUrl: 'https://i.pravatar.cc/150?u=phucanh',
      coverImageUrl: 'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?auto=format&fit=crop&q=80',
      city: 'Đà Lạt',
      rating: 4.95,
      reviewCount: 178,
      pricePerSession: 3500000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Kiến trúc', 'Du lịch'],
      availableDates: [DateTime.now().add(const Duration(days: 1))],
    ),
    PhotographerModel(
      id: 'p13',
      name: 'Vy Vy',
      avatarUrl: 'https://i.pravatar.cc/150?u=vyvy',
      coverImageUrl: 'https://images.unsplash.com/photo-1505934333218-8fe9d9c39e23?auto=format&fit=crop&q=80',
      city: 'Cần Thơ',
      rating: 4.65,
      reviewCount: 40,
      pricePerSession: 1400000,
      isFeatured: false,
      isVerified: false,
      experience: Experience.from1To3Years,
      styles: ['Gia đình', 'Chân dung'],
      availableDates: [
        DateTime.now().add(const Duration(days: 2)),
        DateTime.now().add(const Duration(days: 3)),
      ],
    ),
    PhotographerModel(
      id: 'p14',
      name: 'Quang Dũng',
      avatarUrl: 'https://i.pravatar.cc/150?u=quangdung',
      coverImageUrl: 'https://images.unsplash.com/photo-1541336032412-2048a678540d?auto=format&fit=crop&q=80',
      city: 'Hải Phòng',
      rating: 4.75,
      reviewCount: 55,
      pricePerSession: 1600000,
      isFeatured: false,
      isVerified: true,
      experience: Experience.from1To3Years,
      styles: ['Sự kiện', 'Đường phố'],
      availableDates: [DateTime.now().add(const Duration(days: 4))],
    ),
    PhotographerModel(
      id: 'p15',
      name: 'Trang Nguyễn',
      avatarUrl: 'https://i.pravatar.cc/150?u=trangnguyen',
      coverImageUrl: 'https://images.unsplash.com/photo-1496095493478-f71e54868f04?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rating: 4.88,
      reviewCount: 110,
      pricePerSession: 2600000,
      isFeatured: true,
      isVerified: true,
      experience: Experience.over5Years,
      styles: ['Ẩm thực', 'Sản phẩm'],
      availableDates: [
        DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 5)),
      ],
    ),
  ];

  @override
  Future<void> recordReview(String photographerId, double rating) async {
    final index = _mockData.indexWhere((item) => item.id == photographerId);
    if (index < 0) throw StateError('Không tìm thấy nhiếp ảnh gia.');
    final current = _mockData[index];
    final count = current.reviewCount + 1;
    _mockData[index] = current.copyWith(
      rating: (current.rating * current.reviewCount + rating) / count,
      reviewCount: count,
    );
  }

  @override
  Future<List<PhotographerModel>> getPhotographers({
    FilterCriteria? criteria,
    SortOption sort = SortOption.featured,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    List<PhotographerModel> filteredList = List.from(_mockData);

    if (criteria != null) {
      // Filter by Search Query
      if (criteria.searchQuery != null &&
          criteria.searchQuery!.trim().isNotEmpty) {
        final query = foldVietnamese(
          criteria.searchQuery!.trim().toLowerCase(),
        );
        filteredList = filteredList.where((p) {
          final nameMatch = foldVietnamese(p.name.toLowerCase())
              .contains(query);
          final cityMatch = foldVietnamese(p.city.toLowerCase())
              .contains(query);
          final styleMatch = p.styles.any(
            (s) => foldVietnamese(s.toLowerCase()).contains(query),
          );
          return nameMatch || cityMatch || styleMatch;
        }).toList();
      }

      // Filter by City
      if (criteria.city != null && criteria.city != 'Tất cả') {
        filteredList = filteredList
            .where((p) => p.city == criteria.city)
            .toList();
      }

      // Filter by Price Range
      if (criteria.minPrice != null) {
        filteredList = filteredList
            .where((p) => p.pricePerSession >= criteria.minPrice!)
            .toList();
      }
      if (criteria.maxPrice != null) {
        filteredList = filteredList
            .where((p) => p.pricePerSession <= criteria.maxPrice!)
            .toList();
      }

      // Filter by Styles
      if (criteria.styles.isNotEmpty) {
        filteredList = filteredList.where((p) {
          // Photographer must have AT LEAST ONE of the selected styles
          return p.styles.any((s) => criteria.styles.contains(s));
        }).toList();
      }

      // Filter by Available Date
      if (criteria.availableDate != null) {
        filteredList = filteredList.where((p) {
          return p.availableDates.any(
            (d) =>
                d.year == criteria.availableDate!.year &&
                d.month == criteria.availableDate!.month &&
                d.day == criteria.availableDate!.day,
          );
        }).toList();
      }

      // Filter by Rating
      if (criteria.minRating != null) {
        filteredList = filteredList
            .where((p) => p.rating >= criteria.minRating!)
            .toList();
      }

      // Filter by Experience
      if (criteria.experience != null) {
        filteredList = filteredList
            .where((p) => p.experience == criteria.experience)
            .toList();
      }
    }

    // Sorting
    switch (sort) {
      case SortOption.featured:
        filteredList.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.rating.compareTo(
            a.rating,
          ); // If both featured or not, sort by rating desc
        });
        break;
      case SortOption.rating:
        filteredList.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.priceAsc:
        filteredList.sort(
          (a, b) => a.pricePerSession.compareTo(b.pricePerSession),
        );
        break;
      case SortOption.priceDesc:
        filteredList.sort(
          (a, b) => b.pricePerSession.compareTo(a.pricePerSession),
        );
        break;
      case SortOption.reviewCount:
        filteredList.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    return filteredList;
  }
}
