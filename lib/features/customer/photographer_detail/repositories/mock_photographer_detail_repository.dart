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
    if (matches.isEmpty && featured == null) {
      throw StateError('Không tìm thấy nhiếp ảnh gia.');
    }
    if (matches.isEmpty) {
      return featured!;
    }
    final directoryItem = matches.first;
    return (featured ?? _buildDirectoryProfile(directoryItem)).copyWith(
      rating: directoryItem.rating,
      reviewCount: directoryItem.reviewCount,
    );
  }

  PhotographerProfile _buildDirectoryProfile(PhotographerModel photographer) {
    final base = photographer.pricePerSession.round();
    final years = switch (photographer.experience) {
      Experience.under1Year => 1,
      Experience.from1To3Years => 2,
      Experience.from3To5Years => 4,
      Experience.over5Years => 6,
    };

    final styles = ['Tất cả', ...photographer.styles];
    final primaryStyle = photographer.styles.isNotEmpty
        ? photographer.styles.first
        : 'Chân dung';

    return PhotographerProfile(
      id: photographer.id,
      name: photographer.name,
      avatarUrl: photographer.avatarUrl,
      coverImageUrl: photographer.coverImageUrl,
      city: photographer.city,
      rank: photographer.isFeatured ? 'PRO GOLD' : 'PRO',
      rating: photographer.rating,
      reviewCount: photographer.reviewCount > 0 ? photographer.reviewCount : 45,
      startingPrice: base,
      bio:
          'Nhiếp ảnh gia chuyên nghiệp hoạt động tại ${photographer.city}. Với phong cách sáng tác tinh tế và hơn $years năm kinh nghiệm trong lĩnh vực ${photographer.styles.join(', ')}, ${photographer.name} luôn mang tới những khung hình giàu cảm xúc, chuẩn màu sắc nghệ thuật và độ phân giải cao.',
      experienceYears: years,
      completedShoots: photographer.reviewCount > 0
          ? (photographer.reviewCount * 1.5).round()
          : 68,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      verificationBadge: 'Nhiếp Ảnh Gia Đã Xác Minh & Bảo Hiểm',
      styles: styles,
      portfolio: _generateDirectoryPortfolio(photographer, primaryStyle),
      packages: [
        ProfilePackage(
          id: 'pkg_${photographer.id}_basic',
          name: 'Gói Chụp $primaryStyle Cá Nhân',
          subtitle: 'Phù hợp chụp cá nhân, lưu giữ khoảnh khắc tại 1 địa điểm.',
          price: base,
          duration: '1.5 Giờ',
          deliverables: const [
            '20 ảnh Master Retouch chỉnh da & màu cao cấp',
            '1 địa điểm ngoại cảnh hoặc Studio ánh sáng tự nhiên',
            'Bàn giao ảnh hoàn thiện trong 3 ngày',
            'Cung cấp toàn bộ file gốc chụp trong buổi',
          ],
          photoCount: 20,
          deliveryDays: 3,
        ),
        ProfilePackage(
          id: 'pkg_${photographer.id}_standard',
          name: 'Gói Chụp $primaryStyle & Nghệ Thuật (Bán chạy)',
          subtitle: 'Đủ thời gian thay đổi 2-3 concept và bối cảnh khác nhau.',
          price: ((base * 1.7 / 10000).round() * 10000),
          duration: '3 Giờ',
          deliverables: const [
            '45 ảnh Master Retouch chuẩn in ấn & tạp chí',
            'Setup 2 bối cảnh khác nhau kèm đèn trợ sáng',
            'Hỗ trợ tạo dáng & định hướng phong cách trang phục',
            'Cam kết bàn giao ảnh đúng hẹn trong 48 giờ',
            'Toàn bộ file RAW gốc độ phân giải cao',
          ],
          photoCount: 45,
          deliveryDays: 2,
          isMostSelected: true,
          highlightBadge: 'Được chọn nhiều nhất',
        ),
        ProfilePackage(
          id: 'pkg_${photographer.id}_premium',
          name: 'Gói Chụp Trọn Gói VIP & Campaign',
          subtitle: 'Buổi chụp nửa ngày chuyên nghiệp, trọn quyền sử dụng thương mại.',
          price: base * 3,
          duration: '5 Giờ',
          deliverables: const [
            '80 ảnh Master Retouch cao cấp chuẩn quốc tế',
            'Ekip trợ lý ánh sáng & trạm truyền ảnh trực tiếp',
            'Tặng 01 Khung ảnh pha lê cao cấp để bàn',
            'Hỗ trợ chỉnh sửa nhanh lấy ngay trong 24 giờ',
            'Bảo hiểm LENS Care bảo vệ quyền lợi trọn gói',
          ],
          photoCount: 80,
          deliveryDays: 2,
          highlightBadge: 'Sản xuất chuyên nghiệp',
        ),
      ],
      reviews: [
        ClientReview(
          id: 'rev_${photographer.id}_1',
          clientName: 'Nguyễn Thanh Trúc',
          clientRole: 'Khách hàng cá nhân',
          clientInitials: 'TT',
          rating: 5.0,
          timeAgo: '3 ngày trước',
          packageTag: 'Gói $primaryStyle',
          content: '"Bộ ảnh cực kỳ ưng ý! Nhiếp ảnh gia hướng dẫn tạo dáng rất nhiệt tình, bắt được những góc mặt đẹp nhất của mình. Khâu hậu kỳ màu sắc rất sang."',
        ),
        ClientReview(
          id: 'rev_${photographer.id}_2',
          clientName: 'Vũ Mạnh Cường',
          clientRole: 'Founder • Brand Startup',
          clientInitials: 'MC',
          rating: 5.0,
          timeAgo: '1 tuần trước',
          packageTag: 'Gói Tiêu Chuẩn',
          content: '"Tác phong đúng giờ, chuẩn bị thiết bị kỹ lưỡng. Giao file ảnh nhanh hơn cam kết và chất lượng màu sắc rất chuyên nghiệp."',
        ),
        ClientReview(
          id: 'rev_${photographer.id}_3',
          clientName: 'Đặng Mai Lan',
          clientRole: 'Content Creator',
          clientInitials: 'ML',
          rating: 4.9,
          timeAgo: '2 tuần trước',
          packageTag: 'Gói VIP',
          content: '"Đã hợp tác nhiều lần và lần nào cũng hài lòng 100%. Ánh sáng và bố cục hình ảnh rất có gu nghệ thuật."',
        ),
      ],
      gearInfo: StudioGearInfo(
        cameraBodies: [
          'Sony A7R V (Cảm biến 61MP BSI-CMOS)',
          'Canon EOS R5 Mirrorless 45MP',
          'Ống kính Prime 35mm F1.4 & 85mm F1.2 GM',
        ],
        lightingModifiers: [
          'Hệ thống đèn Godox AD600 Pro x2 & AD400 Pro',
          'Softbox bát giác Octabox 120cm kèm lưới tổ ong',
          'Chân C-Stand, dù phản xạ & hắt sáng 5-in-1',
        ],
        studioAddress: 'Studio đối tác LENS tại trung tâm ${photographer.city}',
        insuranceNotice: 'Được bảo chứng bởi LENS Care: Thiết bị & địa điểm được bảo hiểm trách nhiệm dân sự lên tới 500.000.000 ₫ cho mỗi buổi chụp.',
      ),
    );
  }

  List<PortfolioItem> _generateDirectoryPortfolio(
    PhotographerModel photographer,
    String primaryStyle,
  ) {
    return [
      PortfolioItem(
        id: 'port_${photographer.id}_1',
        imageUrl: photographer.coverImageUrl,
        title: '${photographer.name} Collection',
        style: primaryStyle,
        subtitle: 'Bộ sưu tập tiêu biểu tại ${photographer.city}',
        cameraGear: 'Sony A7R V • 50mm GM',
        isFeatured: true,
      ),
      PortfolioItem(
        id: 'port_${photographer.id}_2',
        imageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&q=80',
        title: 'Sunset Romance',
        style: primaryStyle,
        subtitle: 'Khoảnh khắc hoàng hôn lãng mạn',
        cameraGear: 'Canon R5 • 85mm F1.2',
      ),
      PortfolioItem(
        id: 'port_${photographer.id}_3',
        imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80',
        title: 'Modern Elegance',
        style: photographer.styles.length > 1
            ? photographer.styles[1]
            : primaryStyle,
        subtitle: 'Concept Thời Trang Đương Đại',
        cameraGear: 'Sony A7R V • 35mm GM',
      ),
      PortfolioItem(
        id: 'port_${photographer.id}_4',
        imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
        title: 'Chân Dung Tối Giản',
        style: primaryStyle,
        subtitle: 'Ánh sáng tự nhiên Studio',
        cameraGear: 'Leica M11 • 50mm Summilux',
      ),
      PortfolioItem(
        id: 'port_${photographer.id}_5',
        imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&q=80',
        title: 'Lookbook Mùa Thu',
        style: photographer.styles.length > 1
            ? photographer.styles[1]
            : primaryStyle,
        subtitle: 'Editorial Campaign 2024',
        cameraGear: 'Fujifilm GFX 100 II',
      ),
      PortfolioItem(
        id: 'port_${photographer.id}_6',
        imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80',
        title: 'Khung Hình Kỷ Niệm',
        style: primaryStyle,
        subtitle: 'Kỷ niệm ngoài trời tự nhiên',
        cameraGear: 'Sony A7R V • 70-200mm GM',
      ),
    ];
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
      styles: const [
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
        PortfolioItem(
          id: 'port_7',
          imageUrl: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&q=80',
          title: 'Cinematic Sunset Romance',
          style: 'Chân dung',
          subtitle: 'Buổi chiều hoàng hôn Cầu Ba Son',
          cameraGear: 'Leica M11 • 50mm F1.4',
        ),
        PortfolioItem(
          id: 'port_8',
          imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80',
          title: 'The Golden Silhouette',
          style: 'Nghệ thuật',
          subtitle: 'Art Basel Vietnam Pre-Show',
          cameraGear: 'Hasselblad X2D 100C',
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
    return const PhotographerProfile(
      id: 'p1',
      name: 'Minh Hà Studio',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80',
      coverImageUrl: 'https://images.unsplash.com/photo-1554080353-a576cf803bda?auto=format&fit=crop&q=80',
      city: 'TP. Hồ Chí Minh',
      rank: 'PRO GOLD',
      rating: 4.98,
      reviewCount: 124,
      startingPrice: 2800000,
      bio: 'Studio nhiếp ảnh thời trang & pre-wedding nghệ thuật với hơn 7 năm kinh nghiệm tại Sài Gòn. Từng hợp tác cùng Elle, Harper\'s Bazaar và nhiều nhãn hàng nội địa. Chuyên sâu về ánh sáng điện ảnh, lookbook thương mại và các bộ ảnh cưới phong cách cinematic châu Âu.',
      experienceYears: 7,
      completedShoots: 189,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      verificationBadge: 'Studio Đã Xác Minh & Bảo Hiểm Toàn Diện',
      styles: ['Tất cả', 'Thời trang', 'Chân dung', 'Cưới', 'Lookbook'],
      portfolio: [
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
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&q=80',
          title: 'Heritage Silk Runway',
          style: 'Thời trang',
          subtitle: "Harper's Bazaar Vietnam • Bìa Mùa Thu",
          cameraGear: 'Sony A1 • 85mm F1.2',
        ),
        PortfolioItem(
          id: 'mh_3',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
          title: 'Chân Dung Điện Ảnh Sài Gòn',
          style: 'Chân dung',
          subtitle: 'Cinematic Noir Studio Session',
          cameraGear: 'Leica M11 • 35mm F1.4',
        ),
        PortfolioItem(
          id: 'mh_4',
          imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?auto=format&fit=crop&q=80',
          title: 'Minimalism Capsule 24',
          style: 'Lookbook',
          subtitle: 'BST Thu Đông • The Row Saigon',
          cameraGear: 'Sony A7R V • 24-70mm GM II',
        ),
        PortfolioItem(
          id: 'mh_5',
          imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&q=80',
          title: 'Hồ Tràm Golden Twilight',
          style: 'Cưới',
          subtitle: 'Destination Wedding • Melia Ho Tram',
          cameraGear: 'Sony A1 • 35mm GM',
        ),
        PortfolioItem(
          id: 'mh_6',
          imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80',
          title: 'Aura Glow Beauty',
          style: 'Chân dung',
          subtitle: 'Dior Beauty Editorial Study',
          cameraGear: 'Profoto D2 • 85mm',
        ),
        PortfolioItem(
          id: 'mh_7',
          imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&q=80',
          title: 'Metropolis Chic',
          style: 'Thời trang',
          subtitle: 'Sài Gòn Heritage Streetwear Campaign',
          cameraGear: 'Fujifilm GFX 100 II',
        ),
        PortfolioItem(
          id: 'mh_8',
          imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80',
          title: 'Velvet Autumn Concept',
          style: 'Lookbook',
          subtitle: 'Lookbook Thời Trang Thiết Kế Cia',
          cameraGear: 'Sony A7R V • 50mm GM',
        ),
        PortfolioItem(
          id: 'mh_9',
          imageUrl: 'https://images.unsplash.com/photo-1469371670807-013ccf25f16a?auto=format&fit=crop&q=80',
          title: 'Lễ Đường Bên Rừng Thông',
          style: 'Cưới',
          subtitle: 'Đà Lạt Intimate Wedding 2024',
          cameraGear: 'Sony A1 • 70-200mm GM II',
        ),
      ],
      packages: [
        ProfilePackage(
          id: 'pkg_mh_1',
          name: 'Gói Chụp Lookbook Studio & Thời Trang',
          subtitle: 'Phù hợp cho shop thời trang, thương hiệu nội địa ra mắt BST mới.',
          price: 3500000,
          duration: '3 Giờ',
          photoCount: 40,
          deliveryDays: 2,
          isMostSelected: true,
          highlightBadge: 'Bán chạy nhất',
          deliverables: [
            '40 ảnh chỉnh sửa chi tiết chuẩn màu thương hiệu',
            'Phòng chụp Studio Cyclorama 100m2 máy lạnh Quận 1',
            'Ekip trợ lý ánh sáng & máy tạo khói chuyên nghiệp',
            'Bàn giao toàn bộ ảnh hoàn thiện trong 48 giờ',
            'Cung cấp toàn bộ file RAW gốc độ phân giải 50MP',
          ],
        ),
        ProfilePackage(
          id: 'pkg_mh_2',
          name: 'Gói Chân Dung Nghệ Thuật & Profile',
          subtitle: 'Buổi chụp chân dung cá nhân mang màu sắc điện ảnh giàu chiều sâu.',
          price: 2800000,
          duration: '1.5 Giờ',
          photoCount: 20,
          deliveryDays: 2,
          highlightBadge: 'Phổ biến',
          deliverables: [
            '20 ảnh Master Retouch tông màu điện ảnh chuyên sâu',
            '1 bối cảnh Studio Cyclorama hoặc ngoại cảnh Sài Gòn',
            'Hỗ trợ định hướng phong cách & tạo dáng tự nhiên',
            'Bàn giao ảnh đã chỉnh sửa trong 48 giờ',
            'Tặng toàn bộ file gốc chụp trong buổi',
          ],
        ),
        ProfilePackage(
          id: 'pkg_mh_3',
          name: 'Gói Pre-Wedding Điện Ảnh & Ngoại Cảnh VIP',
          subtitle:
              'Trọn gói chụp ảnh cưới phong cách cinematic châu Âu lãng mạn.',
          price: 7800000,
          duration: '5 Giờ',
          photoCount: 80,
          deliveryDays: 3,
          highlightBadge: 'Sản xuất cao cấp',
          deliverables: [
            '80 ảnh Master Retouch phong cách điện ảnh châu Âu',
            'Chụp kết hợp Studio và 2 địa điểm ngoại cảnh hoàng hôn',
            'Tặng 01 Album Photobook 30x30cm ép màng mờ cao cấp',
            'Tặng 01 Ảnh cổng pha lê tráng gương 60x90cm',
            'Toàn bộ file RAW gốc và clip hậu trường Reel ngắn',
            'Bảo hiểm trách nhiệm & thiết bị LENS Care 500 triệu',
          ],
        ),
      ],
      reviews: [
        ClientReview(
          id: 'rev_mh_1',
          clientName: 'Phương Oanh',
          clientRole: 'CEO • Oanh Fashion',
          clientInitials: 'PO',
          rating: 5.0,
          timeAgo: '4 ngày trước',
          packageTag: 'Lookbook Studio',
          content: '"Làm việc với Minh Hà Studio 3 mùa liên tiếp rồi và chưa bao giờ thất vọng. Tác phong đúng giờ, chuẩn bị ánh sáng chu đáo, tone màu lên form đồ rất nịnh mắt. Đội ngũ nhiệt tình 10/10."',
        ),
        ClientReview(
          id: 'rev_mh_2',
          clientName: 'Hoàng Nam & Thảo Vy',
          clientRole: 'Cặp đôi Pre-wedding',
          clientInitials: 'NV',
          rating: 5.0,
          timeAgo: '1 tuần trước',
          packageTag: 'Pre-Wedding VIP',
          content: '"Chúng mình chọn gói Pre-wedding ngoại cảnh hoàng hôn Thủ Thiêm và bộ ảnh đẹp vượt mong đợi! Bạn photographer hướng dẫn tạo dáng rất nhẹ nhàng, bắt trọn từng khoảnh khắc tự nhiên của hai đứa. Rất đáng đồng tiền bát gạo!"',
        ),
        ClientReview(
          id: 'rev_mh_3',
          clientName: 'Trần Quốc Dũng',
          clientRole: 'Founder • L\'Artisan Leather',
          clientInitials: 'QD',
          rating: 5.0,
          timeAgo: '2 tuần trước',
          packageTag: 'Lookbook Studio',
          content: '"Bộ ảnh lookbook đồ da của bên mình nhận về lượt tương tác gấp 3 lần bình thường. Tông màu cinematic sang trọng, góc máy bắt kết cấu da rất chi tiết và sắc nét. Chắc chắn sẽ quay lại cho BST mùa đông tới."',
        ),
        ClientReview(
          id: 'rev_mh_4',
          clientName: 'Kim Tuyến',
          clientRole: 'Model & Influencer',
          clientInitials: 'KT',
          rating: 4.9,
          timeAgo: '3 tuần trước',
          packageTag: 'Chân Dung Nghệ Thuật',
          content: '"Không gian studio ấm cúng, âm nhạc thư giãn giúp mình thả lỏng tâm trạng. Ảnh chụp bằng máy Leica cho màu da siêu nịnh mắt. Mọi thứ từ khâu tư vấn đến nhận ảnh qua app Lens đều mượt mà."',
        ),
      ],
      gearInfo: StudioGearInfo(
        cameraBodies: [
          'Sony A1 Flagship 50.1MP (8K Video & 30fps)',
          'Sony A7R V (Cảm biến 61MP BSI-CMOS)',
          'Leica M11 Rangefinder • Summilux 35mm F1.4',
          'Fujifilm GFX 100 II Medium Format',
        ],
        lightingModifiers: [
          'Hệ thống Profoto D2 1000 AirTTL x4 đèn',
          'Aputure 600d Pro kèm Light Dome 150cm',
          'Softbox bát giác Octabox 120cm lưới tổ ong',
          'Máy tạo khói haze Antari, C-stand & thanh boom Matthew',
        ],
        studioAddress: '15 Lê Lợi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh (Cyclorama 100m² view Landmark)',
        insuranceNotice: 'Bảo hiểm trách nhiệm nghề nghiệp & thiết bị LENS Care toàn diện 500.000.000 ₫ cho mỗi buổi chụp.',
      ),
    );
  }

  PhotographerProfile _buildKhaiNguyenProfile() {
    return const PhotographerProfile(
      id: 'p3',
      name: 'Khải Nguyễn',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80',
      coverImageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80',
      city: 'Đà Nẵng',
      rank: 'PRO GOLD',
      rating: 5.0,
      reviewCount: 210,
      startingPrice: 3200000,
      bio: 'Chuyên gia nhiếp ảnh kiến trúc, không gian nội thất & phong cảnh đương đại với hơn 8 năm tác nghiệp tại miền Trung. Khắc hoạ cấu trúc hình khối và vẻ đẹp ánh sáng qua lăng kính quang học Tilt-Shift và Medium Format sắc bén.',
      experienceYears: 8,
      completedShoots: 210,
      completionRate: 100,
      isVerified: true,
      isInsured: true,
      verificationBadge: 'Nhiếp Ảnh Gia Đã Xác Minh & Bảo Hiểm',
      styles: ['Tất cả', 'Kiến trúc', 'Nội thất', 'Đường phố', 'Nghệ thuật'],
      portfolio: [
        PortfolioItem(
          id: 'kn_1',
          imageUrl: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80',
          title: 'The Concrete Harmony',
          style: 'Kiến trúc',
          subtitle: 'Trung tâm Hành chính & Cầu Rồng Đà Nẵng',
          cameraGear: 'Sony A7R V • 16-35mm GM II',
          isFeatured: true,
        ),
        PortfolioItem(
          id: 'kn_2',
          imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80',
          title: 'Minimalist Nordic Living',
          style: 'Nội thất',
          subtitle: 'Penthouse Furama Resort Danang',
          cameraGear: 'Nikon Z9 • 19mm Tilt-Shift',
        ),
        PortfolioItem(
          id: 'kn_3',
          imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80',
          title: 'Hội An Lantern Noir',
          style: 'Đường phố',
          subtitle: 'Phố Cổ Hội An Ban Đêm',
          cameraGear: 'Leica Q3 • 28mm Summilux',
        ),
        PortfolioItem(
          id: 'kn_4',
          imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&q=80',
          title: 'Bamboo Pavilion Study',
          style: 'Kiến trúc',
          subtitle: 'Khu Nghỉ Dưỡng Sinh Thái Nam Hội An',
          cameraGear: 'Hasselblad X2D 100C',
        ),
        PortfolioItem(
          id: 'kn_5',
          imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80',
          title: 'Wabi Sabi Apartment',
          style: 'Nội thất',
          subtitle: 'Căn hộ Duplex Sông Hàn Đà Nẵng',
          cameraGear: 'Sony A7R V • 24mm GM',
        ),
        PortfolioItem(
          id: 'kn_6',
          imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80',
          title: 'Danang Coastline Shadows',
          style: 'Đường phố',
          subtitle: 'Bình Minh Bãi Biển Mỹ Khê',
          cameraGear: 'Nikon Z9 • 50mm F1.2',
        ),
        PortfolioItem(
          id: 'kn_7',
          imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
          title: 'Geometric Facade Study',
          style: 'Nghệ thuật',
          subtitle: 'Triển lãm Kiến trúc Miền Trung 2024',
          cameraGear: 'Nikon Z9 • 85mm F1.2',
        ),
        PortfolioItem(
          id: 'kn_8',
          imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&q=80',
          title: 'Zen Garden Tea House',
          style: 'Kiến trúc',
          subtitle: 'Không gian Trà Đạo Bà Nà Hills',
          cameraGear: 'Sony A7R V • 35mm GM',
        ),
      ],
      packages: [
        ProfilePackage(
          id: 'pkg_kn_1',
          name: 'Chụp Không Gian Căn Hộ & Villa',
          subtitle: 'Tối ưu góc máy kiến trúc cho căn hộ chung cư cao cấp, biệt thự nghỉ dưỡng.',
          price: 3200000,
          duration: '2 Giờ',
          photoCount: 25,
          deliveryDays: 3,
          deliverables: [
            '25 ảnh chỉnh sửa cân bằng phối cảnh & ánh sáng HDR',
            'Sử dụng ống kính Tilt-Shift chống méo phối cảnh',
            'Bàn giao ảnh trong 3 ngày',
            'Toàn bộ file gốc độ phân giải cao',
          ],
        ),
        ProfilePackage(
          id: 'pkg_kn_2',
          name: 'Hồ Sơ Kiến Trúc & Công Trình Thương Mại',
          subtitle:
              'Dành cho văn phòng kiến trúc sư, nhà thầu & chủ đầu tư dự án.',
          price: 6500000,
          duration: '4 Giờ',
          photoCount: 50,
          deliveryDays: 2,
          isMostSelected: true,
          highlightBadge: 'Bán chạy nhất',
          deliverables: [
            '50 ảnh Master Retouch chất lượng in ấn catalogue',
            'Chụp cả ánh sáng ban ngày & khoảnh khắc Twilight hoàng hôn',
            'Chỉnh sửa xóa khuyết điểm công trình & rác thị giác',
            'Bàn giao trong 48 giờ kèm file TIFF 16-bit',
          ],
        ),
        ProfilePackage(
          id: 'pkg_kn_3',
          name: 'Sản Xuất Hình Ảnh Khách Sạn & Resort VIP',
          subtitle: 'Bộ ảnh truyền thông toàn diện cho chuỗi khách sạn, khu nghỉ dưỡng 5 sao.',
          price: 14000000,
          duration: '1 Ngày (8 Giờ)',
          photoCount: 100,
          deliveryDays: 4,
          highlightBadge: 'Sản xuất chuyên nghiệp',
          deliverables: [
            '100 ảnh hoàn thiện bao gồm ngoại thất, nội thất & tiện ích',
            'Chụp Flycam 4K trên cao & toàn cảnh dự án',
            'Ekip trợ lý ánh sáng & máy tạo khói chuyên nghiệp',
            'Toàn quyền sở hữu thương mại vĩnh viễn',
          ],
        ),
      ],
      reviews: [
        ClientReview(
          id: 'rev_kn_1',
          clientName: 'KTS. Lê Hoàng Quân',
          clientRole: 'Văn phòng Kiến trúc Vo Trong Nghia Danang',
          clientInitials: 'HQ',
          rating: 5.0,
          timeAgo: '5 ngày trước',
          packageTag: 'Hồ Sơ Kiến Trúc',
          content: '"Khải có góc nhìn về hình khối và ánh sáng tự nhiên cực kỳ chuẩn xác. Kỹ thuật chụp Tilt-Shift giúp các đường thẳng đứng hoàn hảo, tôn vinh trọn vẹn ý đồ thiết kế của công trình."',
        ),
        ClientReview(
          id: 'rev_kn_2',
          clientName: 'Nguyễn Phương Mai',
          clientRole: 'Tổng Quản Lý • Furama Villas Danang',
          clientInitials: 'PM',
          rating: 5.0,
          timeAgo: '2 tuần trước',
          packageTag: 'Khách Sạn & Resort VIP',
          content: '"Bộ ảnh resort làm mới giúp tỷ lệ đặt phòng trực tuyến của chúng tôi tăng 40% trong tháng vừa qua. Khải làm việc đúng tiến độ, chỉn chu và rất tận tâm."',
        ),
        ClientReview(
          id: 'rev_kn_3',
          clientName: 'Trần Trọng Hiếu',
          clientRole: 'Chủ chuỗi Café The Shelter',
          clientInitials: 'TH',
          rating: 5.0,
          timeAgo: '1 tháng trước',
          packageTag: 'Không Gian Căn Hộ',
          content: '"Không gian quán ban đêm rất khó chụp nhưng Khải xử lý ánh sáng đèn ấm cực kỳ mượt mà. Khách hàng xem ảnh ai cũng khen đẹp."',
        ),
      ],
      gearInfo: StudioGearInfo(
        cameraBodies: [
          'Nikon Z9 Flagship 45.7MP',
          'Nikon PC-E 19mm F4 ED Tilt-Shift chuyên kiến trúc',
          'Hasselblad X2D 100C Medium Format',
          'Leica Q3 60MP Full-frame',
        ],
        lightingModifiers: [
          'Profoto Pro-11 2400 AirTTL',
          'Đèn panel Godox FL150S uốn dẻo cho góc hẹp nội thất',
          'Chân máy carbon Gitzo Systematic & đầu Pan/Tilt Arca-Swiss',
          'Bộ filter kính lọc phân cực CPL & ND NiSi chuyên dụng',
        ],
        studioAddress:
            'Nguyễn Văn Linh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
        insuranceNotice:
            'Bảo hiểm thiết bị và an toàn công trình LENS Care 500.000.000 ₫.',
      ),
    );
  }
}
