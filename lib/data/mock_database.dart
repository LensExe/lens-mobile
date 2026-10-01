import '../domain/models/models.dart';

class MockDatabase {
  static final User customerUser = User(
    id: 'u-khachhang',
    name: 'Trần Khách Hàng',
    email: 'customer@lens.com',
    role: 'client',
    phone: '0901234567',
    city: 'TP. Hồ Chí Minh',
    address: '123 Nguyễn Huệ, Phường Bến Nghé, Quận 1',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    saveAsDefault: true,
    twoFactorEnabled: true,
  );
  static final User photographerUser = User(
    id: 'u2',
    name: 'Alex Photography',
    email: 'photo@lens.com',
    role: 'photographer',
    phone: '0912345678',
    city: 'Hồ Chí Minh',
    address: '45 Lê Lợi, Quận 1',
  );

  static User? currentUser;

  static List<ActiveSession> activeSessions = [
    ActiveSession(
      id: 'sess-1',
      deviceName: 'iPhone 15 Pro (Ứng dụng này)',
      location: 'TP. Hồ Chí Minh, Việt Nam',
      lastActive: 'Đang hoạt động',
      isCurrent: true,
    ),
    ActiveSession(
      id: 'sess-2',
      deviceName: 'MacBook Pro · Chrome 129',
      location: 'TP. Hồ Chí Minh, Việt Nam',
      lastActive: '2 giờ trước',
      isCurrent: false,
    ),
    ActiveSession(
      id: 'sess-3',
      deviceName: 'iPad Air · Safari',
      location: 'Đà Lạt, Việt Nam',
      lastActive: '3 ngày trước',
      isCurrent: false,
    ),
  ];

  static final List<Photographer> photographers = [
    Photographer(
      id: 'p1',
      name: 'Alex Photography',
      avatar: 'https://i.pravatar.cc/150?u=p1',
      cover: 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?q=80&w=1000',
      city: 'Hồ Chí Minh',
      styles: ['Cưới', 'Chân dung'],
      pricePerSession: 2000000,
      rating: 4.8,
      reviewCount: 124,
      bio: 'Chuyên gia chụp ảnh cưới với 5 năm kinh nghiệm.',
      experienceYears: 5,
      portfolio: [
        'https://images.unsplash.com/photo-1511285560929-80b456fea0bc',
        'https://images.unsplash.com/photo-1519741497674-611481863552',
      ],
      packages: [
        PhotographerPackage(
          id: 'pkg1',
          name: 'Gói Tiêu chuẩn',
          duration: '2 giờ',
          price: 2000000,
        ),
        PhotographerPackage(
          id: 'pkg2',
          name: 'Gói Cao cấp',
          duration: '4 giờ',
          price: 3500000,
        ),
      ],
    ),
    Photographer(
      id: 'p2',
      name: 'Studio YC',
      avatar: 'https://i.pravatar.cc/150?u=p2',
      cover: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?q=80&w=1000',
      city: 'Hà Nội',
      styles: ['Sản phẩm', 'Thương mại'],
      pricePerSession: 3500000,
      rating: 4.9,
      reviewCount: 89,
      bio: 'Studio chuyên chụp ảnh sản phẩm quảng cáo.',
      experienceYears: 7,
      portfolio: [
        'https://images.unsplash.com/photo-1542038784456-1ea8e935640e',
      ],
      packages: [
        PhotographerPackage(
          id: 'pkg3',
          name: 'Chụp Sản phẩm',
          duration: '3 giờ',
          price: 3500000,
        ),
      ],
    ),
  ];

  static List<Booking> bookings = [
    Booking(
      id: 'b1',
      clientId: 'u1',
      clientName: 'Nguyễn Văn A',
      photographerId: 'p2',
      photographerName: 'Studio YC',
      style: 'Sản phẩm',
      date: '2026-10-15',
      location: 'Quận 1, TP.HCM',
      price: 3500000,
      status: BookingStatus.pending,
    ),
    Booking(
      id: 'b2',
      clientId: 'u1',
      clientName: 'Nguyễn Văn A',
      photographerId: 'p1',
      photographerName: 'Alex Photography',
      style: 'Cưới',
      date: '2026-09-20',
      location: 'Đà Lạt',
      price: 2000000,
      status: BookingStatus.confirmed,
    ),
    Booking(
      id: 'b3',
      clientId: 'u1',
      clientName: 'Nguyễn Văn A',
      photographerId: 'p1',
      photographerName: 'Alex Photography',
      style: 'Chân dung',
      date: '2026-10-01',
      location: 'Studio Quận 3',
      price: 1500000,
      status: BookingStatus.held,
    ),
    Booking(
      id: 'b4',
      clientId: 'u1',
      clientName: 'Nguyễn Văn A',
      photographerId: 'p2',
      photographerName: 'Studio YC',
      style: 'Sản phẩm',
      date: '2026-08-15',
      location: 'Công ty ABC',
      price: 5000000,
      status: BookingStatus.released,
    ),
    Booking(
      id: 'b5',
      clientId: 'u1',
      clientName: 'Nguyễn Văn A',
      photographerId: 'p1',
      photographerName: 'Alex Photography',
      style: 'Sự kiện',
      date: '2026-11-20',
      location: 'Khách sạn Rex',
      price: 4000000,
      status: BookingStatus.cancelled,
    ),
  ];

  static List<Conversation> conversations = [
    Conversation(
      id: 'c1',
      bookingId: 'bk-85014',
      otherPartyId: 'p1',
      otherPartyName: 'Minh Hà Studio',
      otherPartyAvatar: 'https://i.pravatar.cc/150?u=p1',
      lastMessage: 'Chào bạn, mình đã nhận được lịch đặt chụp.',
      unreadCount: 1,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      isOnline: true,
      aiAssistantEnabled: true,
    ),
    Conversation(
      id: 'c2',
      bookingId: 'bk-84920',
      otherPartyId: 'p2',
      otherPartyName: 'Elena Rostova',
      otherPartyAvatar: 'https://i.pravatar.cc/150?u=p2',
      lastMessage: 'Ok bạn.',
      unreadCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      isOnline: false,
      aiAssistantEnabled: false,
    ),
  ];

  static List<Message> messages = [
    Message(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'p1',
      senderRole: 'ai',
      text: 'Chào bạn, mình là trợ lý AI của Minh Hà Studio. Vui lòng để lại lời nhắn, Minh Hà sẽ trả lời sớm nhất.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Message(
      id: 'm2',
      conversationId: 'c1',
      senderId: 'u-khachhang',
      senderRole: 'customer',
      text: 'Mình muốn trao đổi thêm về concept.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Message(
      id: 'm3',
      conversationId: 'c1',
      senderId: 'p1',
      senderRole: 'photographer',
      text: 'Chào bạn, mình đã nhận được lịch đặt chụp.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Message(
      id: 'm4',
      conversationId: 'c2',
      senderId: 'u-khachhang',
      senderRole: 'customer',
      text: 'Mình đã xem qua portfolio.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    Message(
      id: 'm5',
      conversationId: 'c2',
      senderId: 'p2',
      senderRole: 'photographer',
      text: 'Ok bạn.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
