import '../models/booking_model.dart';
import 'booking_repository.dart';

String _dateFromNow(int days) {
  final date = DateTime.now().add(Duration(days: days));
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class MockBookingRepository implements BookingRepository {
  static const _deliveryPhotos = [
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1532712938736-59c79ae04527?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1606800052052-a08af7148866?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=900&q=80',
  ];
  static List<String> _deliveryPhotosFor(String bookingId, int count) => [
    for (var index = 0; index < count; index++)
      if (index < _deliveryPhotos.length)
        _deliveryPhotos[index]
      else
        'https://picsum.photos/seed/lens-$bookingId-$index/900/1200',
  ];
  static int _minutes(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) throw StateError('Khung giờ không hợp lệ.');
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static (int, int) _range(Booking booking) {
    final start = _minutes(booking.timeSlot ?? '');
    final parts = booking.timeSlot!.split(' - ');
    final end = parts.length == 2
        ? _minutes(parts[1])
        : start + ((booking.packageSnapshot?.durationHours ?? 1) * 60).round();
    return (start, end);
  }

  static final List<Booking> _bookings = [
    Booking(
      id: 'bk-84920',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p2',
      photographerName: 'Elena Rostova',
      photographerAvatar: 'https://i.pravatar.cc/150?u=elena',
      style: 'Thời trang Lookbook',
      date: _dateFromNow(6),
      timeSlot: '14:00',
      location: 'Studio 4B, 15 Lê Lợi, Quận 1, TP.HCM',
      price: 4500000,
      status: BookingStatus.held,
      packageId: 'standard',
      packageSnapshot: const PackageTerms(
        name: 'Editorial Fashion Lookbook',
        photoCount: 35,
        durationHours: 3.0,
        deliveryDays: 2,
      ),
      contactPhone: '0901234567',
      note: 'Chuẩn bị đèn strobe và phông trắng',
      depositAmount: 1350000,
      depositPaidAt: '2024-10-20T10:00:00Z',
      rating: 4.98,
      reviewCount: 64,
      uploadedProofsCount: 35,
      deliveryPhotoUrls: _deliveryPhotosFor('bk-84920', 35),
      createdTimeAgo: '2 giờ trước',
    ),
    Booking(
      id: 'bk-85014',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p1',
      photographerName: 'Minh Hà Studio',
      photographerAvatar: 'https://i.pravatar.cc/150?u=minhha',
      style: 'Ảnh cưới hoàng hôn',
      date: _dateFromNow(14),
      timeSlot: '16:00',
      location: 'Cầu Thủ Thiêm & Bờ kè Sông Sài Gòn, TP.HCM',
      price: 6800000,
      status: BookingStatus.confirmed,
      packageId: 'premium',
      packageSnapshot: const PackageTerms(
        name: 'Gói ngoại cảnh hoàng hôn',
        photoCount: 80,
        durationHours: 3.0,
        deliveryDays: 5,
      ),
      contactPhone: '0901234567',
      note: 'Chụp phong cách cinematic, tone màu ấm',
      depositAmount: 2040000,
      depositPaidAt: '2024-10-22T14:30:00Z',
      rating: 4.95,
      reviewCount: 62,
      uploadedProofsCount: 0,
      createdTimeAgo: 'Còn 2 ngày nữa',
    ),
    Booking(
      id: 'bk-85102',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p3',
      photographerName: 'Khải Nguyễn',
      photographerAvatar: 'https://i.pravatar.cc/150?u=khai',
      style: 'Kiến trúc & Không gian',
      date: _dateFromNow(21),
      timeSlot: '09:00',
      location: 'Tòa nhà Landmark 81, Bình Thạnh, TP.HCM',
      price: 3200000,
      status: BookingStatus.awaiting_deposit,
      packageId: 'basic',
      packageSnapshot: const PackageTerms(
        name: 'Gói kiến trúc tiêu chuẩn',
        photoCount: 40,
        durationHours: 2.0,
        deliveryDays: 2,
      ),
      contactPhone: '0901234567',
      depositAmount: 960000,
      depositDeadline: DateTime.now()
          .add(const Duration(minutes: 30))
          .toIso8601String(),
      rating: 5.0,
      reviewCount: 210,
      uploadedProofsCount: 0,
      createdTimeAgo: '30 phút trước',
    ),
    Booking(
      id: 'bk-84610',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p5',
      photographerName: 'Tuấn Đạt',
      photographerAvatar: 'https://i.pravatar.cc/150?u=tuandat',
      style: 'Ẩm thực & Nhà hàng',
      date: _dateFromNow(-18),
      timeSlot: '10:00',
      location: 'Nhà hàng Fusion, Quận 3, TP.HCM',
      price: 2500000,
      status: BookingStatus.released,
      packageId: 'standard',
      packageSnapshot: const PackageTerms(
        name: 'Gói chụp Menu món ăn',
        photoCount: 50,
        durationHours: 2.0,
        deliveryDays: 2,
      ),
      contactPhone: '0901234567',
      depositAmount: 750000,
      depositPaidAt: '2024-10-10T08:00:00Z',
      rating: 4.8,
      reviewCount: 35,
      uploadedProofsCount: 50,
      deliveryPhotoUrls: _deliveryPhotosFor('bk-84610', 50),
      createdTimeAgo: 'Đã hoàn thành',
    ),
    Booking(
      id: 'bk-84220',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p7',
      photographerName: 'Hoàng Vũ',
      photographerAvatar: 'https://i.pravatar.cc/150?u=hoangvu',
      style: 'Đường phố & Sự kiện',
      date: _dateFromNow(-35),
      timeSlot: '15:00',
      location: 'Phố đi bộ Nguyễn Huệ, Quận 1, TP.HCM',
      price: 1200000,
      status: BookingStatus.cancelled,
      packageId: 'basic',
      packageSnapshot: const PackageTerms(
        name: 'Gói chụp sự kiện',
        photoCount: 30,
        durationHours: 1.5,
        deliveryDays: 2,
      ),
      contactPhone: '0901234567',
      depositAmount: 360000,
      rating: 4.5,
      reviewCount: 20,
      uploadedProofsCount: 0,
      createdTimeAgo: 'Đã hủy',
    ),
    Booking(
      id: 'bk-84550',
      clientId: 'u-khachhang',
      clientName: 'Trần Khách Hàng',
      photographerId: 'p1',
      photographerName: 'Minh Hà Studio',
      photographerAvatar: 'https://i.pravatar.cc/150?u=minhha',
      style: 'Chân dung',
      date: _dateFromNow(-10),
      timeSlot: '09:00 - 10:00',
      location: 'Quận 1, TP. Hồ Chí Minh',
      price: 2800000,
      status: BookingStatus.released,
      packageId: 'basic',
      packageSnapshot: const PackageTerms(
        name: 'Gói chân dung',
        photoCount: 15,
        durationHours: 1,
        deliveryDays: 5,
      ),
      contactPhone: '0901234567',
      depositAmount: 840000,
      uploadedProofsCount: 15,
      deliveryPhotoUrls: _deliveryPhotosFor('bk-84550', 15),
      createdTimeAgo: 'Đã hoàn thành',
    ),
  ];

  @override
  Future<List<Booking>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var index = 0; index < _bookings.length; index++) {
      final booking = _bookings[index];
      if (booking.status == BookingStatus.awaiting_deposit &&
          booking.depositDeadline != null &&
          DateTime.tryParse(booking.depositDeadline!)
                  ?.isBefore(DateTime.now()) ==
              true) {
        _bookings[index] = booking.copyWith(status: BookingStatus.cancelled);
      }
    }
    return List.unmodifiable(_bookings);
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw StateError('Không tìm thấy lịch đặt.');
    final booking = _bookings[index];
    final allowed = switch (booking.status) {
      BookingStatus.awaiting_deposit => [
        BookingStatus.pending,
        BookingStatus.cancelled,
      ],
      BookingStatus.pending => [
        BookingStatus.confirmed,
        BookingStatus.cancelled,
      ],
      BookingStatus.confirmed => [BookingStatus.held, BookingStatus.cancelled],
      BookingStatus.held => [BookingStatus.released, BookingStatus.cancelled],
      _ => <BookingStatus>[],
    };
    if (!allowed.contains(newStatus)) {
      throw StateError('Trạng thái lịch đặt không cho phép thao tác này.');
    }
    if (newStatus == BookingStatus.pending &&
        booking.depositDeadline != null &&
        DateTime.tryParse(booking.depositDeadline!)?.isBefore(DateTime.now()) ==
            true) {
      _bookings[index] = booking.copyWith(status: BookingStatus.cancelled);
      throw StateError('Lịch đặt đã hết hạn giữ chỗ.');
    }
    if (newStatus == BookingStatus.released &&
        (booking.isStorageLocked ||
            booking.uploadedProofsCount <
                (booking.packageSnapshot?.photoCount ?? 0))) {
      throw StateError('Bộ ảnh chưa đủ hoặc đang bị khoá.');
    }
    _bookings[index] = booking.copyWith(
      status: newStatus,
      depositPaidAt: newStatus == BookingStatus.pending
          ? DateTime.now().toIso8601String()
          : booking.depositPaidAt,
      coinsEarned: newStatus == BookingStatus.released
          ? (booking.price * 0.05).round()
          : booking.coinsEarned,
    );
  }

  @override
  Future<void> payRemaining(String bookingId, int coinsRedeemed) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw StateError('Không tìm thấy lịch đặt.');
    final booking = _bookings[index];
    if (booking.status != BookingStatus.confirmed ||
        coinsRedeemed < 0 ||
        coinsRedeemed > (booking.price * 0.2).floor() ||
        coinsRedeemed > booking.remainingAmount) {
      throw StateError('Không thể thanh toán lịch đặt này.');
    }
    _bookings[index] = booking.copyWith(
      status: BookingStatus.held,
      coinsRedeemed: coinsRedeemed,
    );
  }

  @override
  Future<void> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (booking.status != BookingStatus.awaiting_deposit ||
        booking.packageId == null ||
        booking.timeSlot == null) {
      throw StateError('Thông tin lịch đặt chưa hợp lệ.');
    }
    final (start, end) = _range(booking);
    final occupied = _bookings.any((existing) {
      if (existing.photographerId != booking.photographerId ||
          existing.date != booking.date ||
          existing.status == BookingStatus.cancelled ||
          existing.timeSlot == null) {
        return false;
      }
      if (existing.status == BookingStatus.awaiting_deposit &&
          existing.depositDeadline != null &&
          DateTime.tryParse(existing.depositDeadline!)
                  ?.isBefore(DateTime.now()) ==
              true) {
        return false;
      }
      final (otherStart, otherEnd) = _range(existing);
      return start < otherEnd && otherStart < end;
    });
    if (occupied) throw StateError('Khung giờ này không còn trống.');
    _bookings.insert(0, booking);
  }
}
