import '../models/booking_model.dart';
import 'booking_repository.dart';

String _dateFromNow(int days) {
  final date = DateTime.now().add(Duration(days: days));
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class MockBookingRepository implements BookingRepository {
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
        name: 'Gói 3 giờ Studio',
        photoCount: 120,
        durationHours: 3.0,
        deliveryDays: 3,
      ),
      contactPhone: '0901234567',
      note: 'Chuẩn bị đèn strobe và phông trắng',
      depositAmount: 1350000,
      depositPaidAt: '2024-10-20T10:00:00Z',
      rating: 4.98,
      reviewCount: 94,
      uploadedProofsCount: 120,
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
  ];

  @override
  Future<List<Booking>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
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
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: newStatus,
        date: _bookings[index].date,
      );
    }
  }

  @override
  Future<void> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bookings.insert(0, booking);
  }
}
