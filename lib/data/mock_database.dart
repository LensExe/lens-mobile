import '../domain/models/models.dart';

class MockDatabase {
  static final User customerUser = User(id: 'u1', name: 'Nguyễn Văn A', email: 'customer@lens.com', role: 'client');
  static final User photographerUser = User(id: 'u2', name: 'Studio YC', email: 'photo@lens.com', role: 'photographer');

  static User? currentUser;

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
        PhotographerPackage(id: 'pkg1', name: 'Gói Tiêu chuẩn', duration: '2 giờ', price: 2000000),
        PhotographerPackage(id: 'pkg2', name: 'Gói Cao cấp', duration: '4 giờ', price: 3500000),
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
        PhotographerPackage(id: 'pkg3', name: 'Chụp Sản phẩm', duration: '3 giờ', price: 3500000),
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
      bookingId: 'b2',
      otherPartyId: 'p1',
      otherPartyName: 'Alex Photography',
      otherPartyAvatar: 'https://i.pravatar.cc/150?u=p1',
      lastMessage: 'Chào bạn, mình đã nhận được lịch đặt chụp.',
      unreadCount: 1,
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Conversation(
      id: 'c2',
      bookingId: 'b1',
      otherPartyId: 'p2',
      otherPartyName: 'Studio YC',
      otherPartyAvatar: 'https://i.pravatar.cc/150?u=p2',
      lastMessage: 'Ok bạn.',
      unreadCount: 0,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static List<Message> messages = [
    Message(
      id: 'm1',
      conversationId: 'c1',
      senderId: 'p1',
      senderRole: 'ai',
      text: 'Chào bạn, mình là trợ lý AI của Alex Photography. Vui lòng để lại lời nhắn, Alex sẽ trả lời sớm nhất.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Message(
      id: 'm2',
      conversationId: 'c1',
      senderId: 'u1',
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
      senderId: 'u1',
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
