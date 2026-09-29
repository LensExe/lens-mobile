// ignore_for_file: constant_identifier_names

enum BookingStatus {
  awaiting_deposit, // Chờ đặt cọc (30%)
  pending,          // Đã cọc, chờ NAG xác nhận
  confirmed,        // NAG đã nhận, chờ thanh toán nốt (70%)
  held,             // Đã thanh toán 100%, sàn giữ tiền (escrow) chờ chụp & giao ảnh
  released,         // Khách đã nghiệm thu nhận ảnh -> hoàn tất, giải ngân cho NAG
  cancelled,        // Đã huỷ lịch
}

class PackageTerms {
  final String name;
  final int photoCount;       // Số ảnh cam kết (dùng để chặn nghiệm thu nếu chưa đủ ảnh)
  final double durationHours;  // Thời lượng buổi chụp (giờ)
  final int deliveryDays;     // Hạn giao ảnh (số ngày sau ngày chụp)

  const PackageTerms({
    required this.name,
    required this.photoCount,
    required this.durationHours,
    required this.deliveryDays,
  });

  factory PackageTerms.fromJson(Map<String, dynamic> json) => PackageTerms(
    name: json['name'] as String,
    photoCount: json['photoCount'] as int,
    durationHours: (json['durationHours'] as num).toDouble(),
    deliveryDays: json['deliveryDays'] as int,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'photoCount': photoCount,
    'durationHours': durationHours,
    'deliveryDays': deliveryDays,
  };
}

class BookingCollaborator {
  final String photographerId;
  final String photographerName;
  final String photographerAvatar;
  final int sharePct; // % chia thù lao (vd: 40%)
  final String status; // 'invited' | 'accepted' | 'declined'

  const BookingCollaborator({
    required this.photographerId,
    required this.photographerName,
    required this.photographerAvatar,
    required this.sharePct,
    required this.status,
  });

  factory BookingCollaborator.fromJson(Map<String, dynamic> json) => BookingCollaborator(
    photographerId: json['photographerId'] as String,
    photographerName: json['photographerName'] as String,
    photographerAvatar: json['photographerAvatar'] as String,
    sharePct: json['sharePct'] as int,
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'photographerId': photographerId,
    'photographerName': photographerName,
    'photographerAvatar': photographerAvatar,
    'sharePct': sharePct,
    'status': status,
  };
}

class Booking {
  final String id;                  // vd: "bk-tkh-1"
  final String clientId;            // "u-khachhang"
  final String clientName;          // "Trần Khách Hàng"
  final String photographerId;      // "p2"
  final String photographerName;    // "Trần Quốc Bảo"
  final String? photographerAvatar;
  final String style;               // "Cưới", "Chân dung",...
  final String date;                // ISO "yyyy-MM-dd"
  final String? timeSlot;           // "14:00"
  final String location;            // "Hồ Gươm, Hà Nội"
  final int price;                  // Tổng giá tiền (VND)
  final BookingStatus status;
  final String? packageId;          // "basic", "standard", "premium"
  final PackageTerms? packageSnapshot;
  final String? contactPhone;
  final String? note;
  final int depositAmount;          // Tiền cọc = price * 0.3
  final String? depositPaidAt;      // ISO datetime
  final String? depositDeadline;    // ISO datetime (sau 30p nếu chưa cọc thì huỷ)
  final int? coinsRedeemed;         // Lens Xu đã dùng khấu trừ tiền mặt
  final int? coinsEarned;           // Lens Xu hoàn lại khi hoàn tất (cashback)
  final List<BookingCollaborator>? collaborators;

  // Thuộc tính phụ trợ phục vụ hiển thị
  final double rating;
  final int reviewCount;
  final int uploadedProofsCount;
  final String? createdTimeAgo;

  const Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.photographerId,
    required this.photographerName,
    this.photographerAvatar,
    required this.style,
    required this.date,
    this.timeSlot,
    required this.location,
    required this.price,
    required this.status,
    this.packageId,
    this.packageSnapshot,
    this.contactPhone,
    this.note,
    required this.depositAmount,
    this.depositPaidAt,
    this.depositDeadline,
    this.coinsRedeemed,
    this.coinsEarned,
    this.collaborators,
    this.rating = 4.95,
    this.reviewCount = 50,
    this.uploadedProofsCount = 0,
    this.createdTimeAgo = 'Vừa xong',
  });

  /// Tính số tiền còn lại phải thanh toán sau khi cọc (70%)
  int get remainingAmount => price - depositAmount;

  /// Mã booking hiển thị cho user (vd: "bk-tkh-1" -> "LS-TKH-1")
  String get displayCode => id.toUpperCase().replaceAll('BK-', 'LS-');

  Booking copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? photographerId,
    String? photographerName,
    String? photographerAvatar,
    String? style,
    String? date,
    String? timeSlot,
    String? location,
    int? price,
    BookingStatus? status,
    String? packageId,
    PackageTerms? packageSnapshot,
    String? contactPhone,
    String? note,
    int? depositAmount,
    String? depositPaidAt,
    String? depositDeadline,
    int? coinsRedeemed,
    int? coinsEarned,
    List<BookingCollaborator>? collaborators,
    double? rating,
    int? reviewCount,
    int? uploadedProofsCount,
    String? createdTimeAgo,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      photographerId: photographerId ?? this.photographerId,
      photographerName: photographerName ?? this.photographerName,
      photographerAvatar: photographerAvatar ?? this.photographerAvatar,
      style: style ?? this.style,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      location: location ?? this.location,
      price: price ?? this.price,
      status: status ?? this.status,
      packageId: packageId ?? this.packageId,
      packageSnapshot: packageSnapshot ?? this.packageSnapshot,
      contactPhone: contactPhone ?? this.contactPhone,
      note: note ?? this.note,
      depositAmount: depositAmount ?? this.depositAmount,
      depositPaidAt: depositPaidAt ?? this.depositPaidAt,
      depositDeadline: depositDeadline ?? this.depositDeadline,
      coinsRedeemed: coinsRedeemed ?? this.coinsRedeemed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      collaborators: collaborators ?? this.collaborators,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      uploadedProofsCount: uploadedProofsCount ?? this.uploadedProofsCount,
      createdTimeAgo: createdTimeAgo ?? this.createdTimeAgo,
    );
  }
}
