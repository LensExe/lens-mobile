class Photographer {
  final String id;
  final String name;
  final String avatar;
  final String cover;
  final String city;
  final List<String> styles;
  final int pricePerSession;
  final double rating;
  final int reviewCount;
  final String bio;
  final int experienceYears;
  final List<String> portfolio;
  final List<PhotographerPackage> packages;
  final bool featured;
  final String rank;

  Photographer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.cover,
    required this.city,
    required this.styles,
    required this.pricePerSession,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.experienceYears,
    required this.portfolio,
    this.packages = const [],
    this.featured = false,
    this.rank = 'Pro',
  });
}

class PhotographerPackage {
  final String id;
  final String name;
  final String duration;
  final int price;

  PhotographerPackage({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
  });
}

enum BookingStatus { pending, confirmed, held, released, cancelled }

class Booking {
  final String id;
  final String clientId;
  final String clientName;
  final String photographerId;
  final String photographerName;
  final String style;
  final String date;
  final String location;
  final int price;
  BookingStatus status;

  Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.photographerId,
    required this.photographerName,
    required this.style,
    required this.date,
    required this.location,
    required this.price,
    this.status = BookingStatus.pending,
  });
}

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'client' or 'photographer'

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class Conversation {
  final String id;
  final String bookingId;
  final String otherPartyId;
  final String otherPartyName;
  final String otherPartyAvatar;
  final String lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.bookingId,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.otherPartyAvatar,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      bookingId: bookingId,
      otherPartyId: otherPartyId,
      otherPartyName: otherPartyName,
      otherPartyAvatar: otherPartyAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole; // 'customer' | 'photographer' | 'ai'
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });
}
