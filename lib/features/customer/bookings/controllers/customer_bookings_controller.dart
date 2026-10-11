import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/customer_booking_repository_provider.dart';
import '../../../../providers/data_providers.dart';

class CustomerBookingsState {
  final bool isLoading;
  final List<Booking> allBookings;
  final String? errorMessage;
  final String selectedTab;

  CustomerBookingsState({
    this.isLoading = true,
    this.allBookings = const [],
    this.errorMessage,
    this.selectedTab = 'Tất cả',
  });

  CustomerBookingsState copyWith({
    bool? isLoading,
    List<Booking>? allBookings,
    String? errorMessage,
    bool clearError = false,
    String? selectedTab,
  }) {
    return CustomerBookingsState(
      isLoading: isLoading ?? this.isLoading,
      allBookings: allBookings ?? this.allBookings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  // Bookings currently undergoing active escrow / shooting / proofing
  List<Booking> get inProgressBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.inProgress ||
            b.status == BookingStatus.held,
      )
      .toList();

  List<Booking> get awaitingBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.awaiting_deposit ||
            b.status == BookingStatus.pending ||
            b.status == BookingStatus.accepted,
      )
      .toList();

  List<Booking> get confirmedBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.accepted,
      )
      .toList();

  List<Booking> get completedBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.released ||
            b.status == BookingStatus.completed,
      )
      .toList();

  List<Booking> get cancelledBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.cancelled ||
            b.status == BookingStatus.rejected ||
            b.status == BookingStatus.expired,
      )
      .toList();

  // Active bookings in client workspace (not completed, not cancelled)
  int get activeCount => allBookings
      .where(
        (b) => ![
          BookingStatus.released,
          BookingStatus.completed,
          BookingStatus.cancelled,
          BookingStatus.rejected,
          BookingStatus.expired,
        ].contains(b.status),
      )
      .length;

  // Filtered bookings based on selected tab
  List<Booking> get filteredBookings {
    switch (selectedTab) {
      case 'Đang thực hiện':
        return inProgressBookings;
      case 'Chờ xử lý':
      case 'Chờ xác nhận':
      case 'Chờ duyệt':
        return allBookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
      case 'Đã chấp nhận':
        return confirmedBookings;
      case 'Chờ nhận ảnh':
        return allBookings
            .where((b) => b.status == BookingStatus.shot)
            .toList();
      case 'Chờ đặt cọc':
      case 'Cần thanh toán':
      case 'Chờ thanh toán':
        return allBookings
            .where(
              (b) =>
                  b.status == BookingStatus.awaiting_deposit ||
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.accepted,
            )
            .toList();
      case 'Hoàn thành':
      case 'Đã hoàn tất':
        return completedBookings;
      case 'Đã hủy':
      case 'Đã huỷ':
        return cancelledBookings;
      case 'Tất cả':
      default:
        return allBookings;
    }
  }

  int getCountForTab(String tab) {
    return CustomerBookingsState(
      allBookings: allBookings,
      selectedTab: tab,
      isLoading: false,
    ).filteredBookings.length;
  }
}

class CustomerBookingsController extends Notifier<CustomerBookingsState> {
  @override
  CustomerBookingsState build() {
    ref.watch(authUserProvider);
    final state = CustomerBookingsState();
    Future.microtask(() => loadBookings());
    return state;
  }

  BookingRepository get _repo => ref.read(customerBookingRepositoryProvider);

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getBookings();
      state = state.copyWith(
        isLoading: false,
        // GET /bookings is already scoped to the authenticated Backend actor.
        // customer_id is a separate entity UUID, not the user's auth UUID.
        allBookings: ref.read(authUserProvider)?.role == 'client' ? list : [],
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải lịch đặt. Vui lòng thử lại.',
      );
    }
  }

  void selectTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<void> updateStatus(String bookingId, BookingStatus newStatus) async {
    if (!state.allBookings.any((booking) => booking.id == bookingId)) {
      throw StateError('Lịch đặt không thuộc tài khoản của bạn.');
    }
    if (newStatus == BookingStatus.cancelled) {
      await _repo.cancelBooking(
        bookingId,
        'Yêu cầu hủy từ ứng dụng khách hàng.',
      );
    } else if (newStatus == BookingStatus.completed ||
        newStatus == BookingStatus.released) {
      await _repo.confirmReceipt(bookingId);
    } else {
      throw StateError('Backend không hỗ trợ thao tác trạng thái này.');
    }
    await loadBookings();
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    if (!state.allBookings.any((booking) => booking.id == bookingId)) {
      throw StateError('Lịch đặt không thuộc tài khoản của bạn.');
    }
    await _repo.cancelBooking(bookingId, reason);
    await loadBookings();
  }

  Future<void> confirmReceipt(String bookingId) async {
    if (!state.allBookings.any((booking) => booking.id == bookingId)) {
      throw StateError('Lịch đặt không thuộc tài khoản của bạn.');
    }
    await _repo.confirmReceipt(bookingId);
    await loadBookings();
  }

  Future<void> payRemaining(String bookingId, int coinsRedeemed) async {
    if (!state.allBookings.any((booking) => booking.id == bookingId)) {
      throw StateError('Lịch đặt không thuộc tài khoản của bạn.');
    }
    await _repo.payRemaining(bookingId, coinsRedeemed);
    await loadBookings();
  }

  Future<void> createBooking(Booking booking) async {
    if (booking.clientId != ref.read(authUserProvider)?.id) {
      throw StateError('Vui lòng đăng nhập với tài khoản khách hàng.');
    }
    await _repo.createBooking(booking);
    await loadBookings();
  }

  Future<Booking> createBookingFromInput(BookingCreateInput input) async {
    final user = ref.read(authUserProvider);
    if (user == null || user.role != 'client') {
      throw StateError('Vui lòng đăng nhập với tài khoản khách hàng.');
    }
    final booking = await _repo.createBookingFromInput(input);
    await loadBookings();
    return booking;
  }
}

final customerBookingsControllerProvider =
    NotifierProvider<CustomerBookingsController, CustomerBookingsState>(() {
      return CustomerBookingsController();
    });
