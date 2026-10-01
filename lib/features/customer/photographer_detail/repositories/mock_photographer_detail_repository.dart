import '../models/photographer_detail_model.dart';
import 'photographer_detail_repository.dart';
import '../../discovery/repositories/photographer_repository.dart';
import '../../discovery/models/photographer_model.dart';

class MockPhotographerDetailRepository implements PhotographerDetailRepository {
  final PhotographerRepository directory;

  MockPhotographerDetailRepository(this.directory);

  @override
  Future<PhotographerProfile> getPhotographerProfile(
    String photographerId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));

    PhotographerProfile? featured;
    if (photographerId == 'p1' || photographerId == 'minh-ha') {
      featured = _buildMinhHaProfile();
    } else if (photographerId == 'p3') {
      featured = _buildKhaiNguyenProfile();
    } else if (photographerId == 'p2') {
      featured = _buildElenaRostovaProfile(photographerId);
    }
    final matches = (await directory.getPhotographers()).where(
      (item) =>
          item.id == (photographerId == 'minh-ha' ? 'p1' : photographerId),
    );
    if (matches.isEmpty) throw StateError('Không tìm thấy nhiếp ảnh gia.');
    final directoryItem = matches.first;
    return (featured ?? _buildDirectoryProfile(directoryItem)).copyWith(
      rating: directoryItem.rating,
      reviewCount: directoryItem.reviewCount,
    );
  }

  PhotographerProfile _buildDirectoryProfile(PhotographerModel photographer) {
    final base = photographer.pricePerSession.round();
    final years = switch (photographer.experience) {
      Experience.under1Year => 0,
      Experience.from1To3Years => 1,
      Experience.from3To5Years => 3,
      Experience.over5Years => 5,
    };
    return PhotographerProfile(
      id: photographer.id,
      name: photographer.name,
      avatarUrl: photographer.avatarUrl,
      coverImageUrl: photographer.coverImageUrl,
      city: photographer.city,
      rank: photographer.isFeatured ? 'PRO' : 'Mới',
      rating: photographer.rating,
      reviewCount: photographer.reviewCount,
      startingPrice: base,
      bio: '',
      experienceYears: years,
      completedShoots: 0,
      completionRate: 0,
      isVerified: photographer.isVerified,
      isInsured: false,
      verificationBadge: photographer.isVerified ? 'Đã xác minh' : '',
      styles: ['Tất cả', ...photographer.styles],
      portfolio: [
        PortfolioItem(
          id: 'cover-${photographer.id}',
          imageUrl: photographer.coverImageUrl,
          title: photographer.name,
          style: photographer.styles.first,
          subtitle: '',
          cameraGear: '',
        ),
      ],
      packages: [
        ProfilePackage(
          id: 'basic',
          name: 'Gói cơ bản',
          subtitle: 'Buổi chụp gọn nhẹ, phù hợp chân dung cá nhân.',
          price: base,
          duration: '1 giờ',
          deliverables: const ['15 ảnh'],
          photoCount: 15,
          deliveryDays: 5,
        ),
        ProfilePackage(
          id: 'standard',
          name: 'Gói tiêu chuẩn',
          subtitle: 'Đủ thời gian đổi 2 bộ trang phục và bối cảnh.',
          price: ((base * 1.8 / 10000).round() * 10000),
          duration: '2 giờ',
          deliverables: const ['35 ảnh'],
          photoCount: 35,
          deliveryDays: 7,
        ),
        ProfilePackage(
          id: 'premium',
          name: 'Gói cao cấp',
          subtitle: 'Nửa ngày chụp, nhiều bối cảnh, kèm album in.',
          price: base * 3,
          duration: '4 giờ',
          deliverables: const ['70 ảnh'],
          photoCount: 70,
          deliveryDays: 10,
        ),
      ],
      reviews: const [],
      gearInfo: const StudioGearInfo(
        cameraBodies: [],
        lightingModifiers: [],
        studioAddress: '',
        insuranceNotice: '',
      ),
    );
  }

  PhotographerProfile _buildElenaRostovaProfile(String id) {
    return PhotographerProfile(
      id: id,
      name: 'Elena Rostova',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
      coverImageUrl: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rank: 'PRO GOLD',
      rating: 4.98,
      reviewCount: 64,
      startingPrice: 2800000,
      bio: 'Nhiếp ảnh gia thời trang & chân dung nghệ thuật với hơn 6 năm hoạt động tại Paris và Sài Gòn. Chuyên sâu về ánh sáng điện ảnh, high-fashion lookbook và chất phim 35mm hoài niệm.',
      experienceYears: 6,
      completedShoots: 142,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      verificationBadge: 'Studio Đã Xác Minh & Bảo Hiểm',
      styles: [
        'Tất cả',
        'Thời trang',
        'Phim 35mm',
        'Chân dung',
        'Lookbook',
        'Nghệ thuật',
      ],
      portfolio: const [
        PortfolioItem(
          id: 'port_1',
          imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&q=80',
          title: 'Terracotta Structure & Silk',
          style: 'Thời trang',
          subtitle: "Harper's Bazaar Vietnam • Bìa Mùa Thu",
          cameraGear: 'Sony A7R V',
          isFeatured: true,
        ),
        PortfolioItem(
          id: 'port_2',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80',
          title: 'District 1 Noir',
          style: 'Phim 35mm',
          subtitle: 'The Row Saigon Campaign',
          cameraGear: 'Leica M11 • 35mm',
        ),
        PortfolioItem(
          id: 'port_3',
          imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80',
          title: 'Aura Beauty Study',
          style: 'Chân dung',
          subtitle: 'Dior Beauty Editorial',
          cameraGear: 'Profoto D2 • 85mm',
        ),
        PortfolioItem(
          id: 'port_4',
          imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&q=80',
          title: 'Shadow Play VII',
          style: 'Nghệ thuật',
          subtitle: 'Triển lãm Ánh sáng & Đổ bóng',
          cameraGear: 'B&W Hasselblad',
        ),
        PortfolioItem(
          id: 'port_5',
          imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80',
          title: 'Ether Capsule 24',
          style: 'Lookbook',
          subtitle: 'Bộ sưu tập Thu Đông 2024',
          cameraGear: '50mm F1.2 GM',
        ),
        PortfolioItem(
          id: 'port_6',
          imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&q=80',
          title: 'Metropolis Elegance',
          style: 'Thời trang',
          subtitle: 'Sài Gòn Heritage Streetwear',
          cameraGear: 'Sony A7R V • 24-70mm GM II',
        ),
      ],
      packages: const [
        ProfilePackage(
          id: 'pkg_lookbook',
          name: 'Editorial Fashion Lookbook',
          subtitle: 'Lý tưởng cho nhà thiết kế, người mẫu & chụp lookbook thương mại cao cấp.',
          price: 4500000,
          duration: '3 Giờ',
          photoCount: 35,
          deliveryDays: 2,
          isMostSelected: true,
          highlightBadge: 'Được chọn nhiều nhất',
          deliverables: [
            '35 ảnh Master Retouch chuẩn in ấn & tạp chí',
            'Đã bao gồm Studio Cyclorama 4B Quận 1',
            'Cam kết giao ảnh nhanh trong 48 giờ',
            'Cung cấp toàn bộ kho lưu trữ file RAW gốc',
            'Trợ lý ánh sáng & máy tạo khói chuyên nghiệp',
          ],
        ),
        ProfilePackage(
          id: 'pkg_portrait',
          name: 'Cinematic Portrait Session',
          subtitle:
              'Buổi chụp chân dung nghệ thuật mang màu sắc điện ảnh cá nhân.',
          price: 2800000,
          duration: '1.5 Giờ',
          photoCount: 15,
          deliveryDays: 3,
          highlightBadge: 'Phổ biến',
          deliverables: [
            '15 ảnh chỉnh sửa tông màu điện ảnh chuyên sâu',
            '1 địa điểm (Ngoại cảnh hoặc Studio ánh sáng tự nhiên)',
            'Giao ảnh chỉnh sửa trong 3 ngày',
            'Hỗ trợ định hướng phong cách & tạo dáng',
          ],
        ),
        ProfilePackage(
          id: 'pkg_campaign',
          name: 'Half-Day Campaign & Brand',
          subtitle: 'Chiến dịch thương hiệu trọn gói nửa ngày với bản quyền thương mại.',
          price: 8500000,
          duration: '5 Giờ',
          photoCount: 70,
          highlightBadge: 'Sản xuất chuyên nghiệp',
          deliverables: [
            '70 ảnh Master Retouch với toàn quyền thương mại',
            'Ekip trợ lý ánh sáng & trạm Tether station chụp truyền trực tiếp',
            'Setup 2 bối cảnh khác nhau tại Studio hoặc ngoại cảnh',
            'Hỗ trợ bàn giao file TIFF 16-bit độ phân giải cao',
          ],
        ),
      ],
      reviews: const [
        ClientReview(
          id: 'rev_1',
          clientName: 'Minh Châu Nguyễn',
          clientRole: 'Giám đốc Sáng tạo • The Row VN',
          clientInitials: 'MC',
          rating: 5.0,
          timeAgo: '2 ngày trước',
          packageTag: 'Editorial Lookbook',
          content: '"Elena làm việc cực kỳ có gu và chuyên nghiệp! Cách bạn hướng dẫn người mẫu tự nhiên, kiểm soát ánh sáng gắt giữa trưa một cách điêu luyện và bàn giao toàn bộ kho ảnh hoàn thiện chỉ trong 48h khiến cả ekip kinh ngạc."',
        ),
        ClientReview(
          id: 'rev_2',
          clientName: 'Trần Quốc Bảo',
          clientRole: 'Founder • L’Atelier Saigon',
          clientInitials: 'TB',
          rating: 5.0,
          timeAgo: '1 tuần trước',
          packageTag: 'Campaign & Brand',
          content: '"Chất lượng ảnh xuất sắc vượt ngoài mong đợi. Màu ảnh sâu và sang trọng, đúng tinh thần tối giản mà thương hiệu của chúng tôi theo đuổi. Chắc chắn sẽ tiếp tục hợp tác các bộ sưu tập tiếp theo."',
        ),
        ClientReview(
          id: 'rev_3',
          clientName: 'Hà Linh Đan',
          clientRole: 'Fashion Model & Content Creator',
          clientInitials: 'HL',
          rating: 4.9,
          timeAgo: '3 tuần trước',
          packageTag: 'Cinematic Portrait',
          content: '"Buổi chụp rất thoải mái, Elena tạo không khí cực kỳ ấm cúng giúp mình giải tỏa mọi áp lực trước ống kính. Góc máy của Elena tôn lên trọn vẹn đường nét khuôn mặt."',
        ),
      ],
      gearInfo: const StudioGearInfo(
        cameraBodies: [
          'Sony A7R V (Cảm biến 61MP BSI-CMOS)',
          'Leica M11 (Rangefinder 60MP chuyên phim)',
          'Hasselblad 907X 100C (Medium Format siêu nét)',
        ],
        lightingModifiers: [
          'Hệ thống Profoto B10X Plus x3 (Công suất 500Ws)',
          'Chân C-Stands, Boom Arm công nghiệp & Sandbags',
          'Softbox Bát giác Profoto 120cm Octabox & Grid tổ ong',
          'Nanlite Forza 500B Bi-color hỗ trợ đèn quay liên tục',
        ],
        studioAddress: 'Studio Cyclorama 4B, 15 Lê Lợi, P. Bến Nghé, Quận 1, TP. Hồ Chí Minh',
        insuranceNotice: 'Được bảo chứng bởi LENS Care: Thiết bị & địa điểm được bảo hiểm trách nhiệm dân sự lên tới 500.000.000 ₫ cho mỗi buổi chụp.',
      ),
    );
  }

  PhotographerProfile _buildMinhHaProfile() {
    return PhotographerProfile(
      id: 'p1',
      name: 'Minh Hà Studio',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80',
      coverImageUrl: 'https://images.unsplash.com/photo-1554080353-a576cf803bda?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rank: 'PRO GOLD',
      rating: 4.98,
      reviewCount: 124,
      startingPrice: 2800000,
      bio: 'Studio nhiếp ảnh chuyên nghiệp tại trung tâm Sài Gòn, chuyên sâu các dự án thời trang cao cấp, lookbook thời trang và bộ ảnh cưới phong cách điện ảnh châu Âu.',
      experienceYears: 7,
      completedShoots: 189,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      verificationBadge: 'Studio Đã Xác Minh & Bảo Hiểm',
      styles: ['Tất cả', 'Thời trang', 'Chân dung', 'Cưới', 'Lookbook'],
      portfolio: const [
        PortfolioItem(
          id: 'mh_1',
          imageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&q=80',
          title: 'Sài Gòn Sunset Whispers',
          style: 'Cưới',
          subtitle: 'Pre-wedding Cầu Thủ Thiêm & Bến Bạch Đằng',
          cameraGear: 'Sony A1 • 50mm GM',
          isFeatured: true,
        ),
        PortfolioItem(
          id: 'mh_2',
          imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80',
          title: 'Golden Hour Silhouette',
          style: 'Thời trang',
          subtitle: 'Heritage Silk Runway',
          cameraGear: 'Canon R5 • 85mm F1.2',
        ),
      ],
      packages: const [
        ProfilePackage(
          id: 'pkg_mh_1',
          name: 'Gói Chụp Lookbook Studio',
          subtitle: 'Phù hợp cho shop thời trang, thương hiệu nội địa ra mắt BST mới.',
          price: 3500000,
          duration: '3 Giờ',
          photoCount: 40,
          deliveryDays: 2,
          isMostSelected: true,
          highlightBadge: 'Bán chạy nhất',
          deliverables: [
            '40 ảnh chỉnh sửa chi tiết chuẩn màu thương hiệu',
            'Phòng chụp Studio Cyclorama 80m2 máy lạnh',
            'Bàn giao ảnh trong 48 giờ',
            'Toàn bộ file gốc độ phân giải cao',
          ],
        ),
      ],
      reviews: const [
        ClientReview(
          id: 'rev_mh_1',
          clientName: 'Phương Oanh',
          clientRole: 'CEO • Oanh Fashion',
          clientInitials: 'PO',
          rating: 5.0,
          timeAgo: '4 ngày trước',
          packageTag: 'Lookbook Studio',
          content: '"Làm việc với Minh Hà Studio 3 mùa liên tiếp rồi và chưa bao giờ thất vọng. Tác phong đúng giờ, chuẩn bị ánh sáng chu đáo."',
        ),
      ],
      gearInfo: const StudioGearInfo(
        cameraBodies: ['Sony A1 (50MP 30fps)', 'Canon EOS R5C'],
        lightingModifiers: [
          'Godox AD600 Pro x4',
          'Softbox Aputure Light Dome 150',
        ],
        studioAddress: '15 Lê Lợi, P. Bến Nghé, Quận 1, TP. Hồ Chí Minh',
        insuranceNotice: 'Bảo hiểm LENS Care toàn diện 500.000.000 ₫.',
      ),
    );
  }

  PhotographerProfile _buildKhaiNguyenProfile() {
    return PhotographerProfile(
      id: 'p3',
      name: 'Khải Nguyễn',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80',
      coverImageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80',
      city: 'Đà Nẵng',
      rank: 'PRO',
      rating: 5.0,
      reviewCount: 210,
      startingPrice: 3200000,
      bio: 'Chuyên gia kiến trúc và không gian nội thất đương đại. Khắc hoạ vẻ đẹp kết cấu hình khối qua lăng kính quang học sắc bén.',
      experienceYears: 8,
      completedShoots: 210,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      styles: ['Tất cả', 'Kiến trúc', 'Nội thất', 'Đường phố'],
      portfolio: const [],
      packages: const [
        ProfilePackage(
          id: 'basic',
          name: 'Gói cơ bản',
          subtitle: 'Buổi chụp gọn nhẹ, phù hợp chân dung cá nhân.',
          price: 3200000,
          duration: '1 giờ',
          deliverables: ['15 ảnh'],
          photoCount: 15,
          deliveryDays: 5,
        ),
        ProfilePackage(
          id: 'standard',
          name: 'Gói tiêu chuẩn',
          subtitle: 'Đủ thời gian đổi 2 bộ trang phục và bối cảnh.',
          price: 5760000,
          duration: '2 giờ',
          deliverables: ['35 ảnh'],
          photoCount: 35,
          deliveryDays: 7,
        ),
        ProfilePackage(
          id: 'premium',
          name: 'Gói cao cấp',
          subtitle: 'Nửa ngày chụp, nhiều bối cảnh, kèm album in.',
          price: 9600000,
          duration: '4 giờ',
          deliverables: ['70 ảnh'],
          photoCount: 70,
          deliveryDays: 10,
        ),
      ],
      reviews: const [],
      gearInfo: const StudioGearInfo(
        cameraBodies: ['Nikon Z9', 'Nikon PC-E 19mm Tilt-Shift'],
        lightingModifiers: ['Profoto Pro-11'],
        studioAddress: 'Nguyễn Văn Linh, Hải Châu, Đà Nẵng',
        insuranceNotice: 'Bảo hiểm LENS Care 500 triệu.',
      ),
    );
  }
}
