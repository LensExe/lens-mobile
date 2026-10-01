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
  List<Booking> get inProgressBookings =>
      allBookings.where((b) => b.status == BookingStatus.held).toList();

  List<Booking> get awaitingBookings => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.awaiting_deposit ||
            b.status == BookingStatus.pending,
      )
      .toList();

  List<Booking> get confirmedBookings =>
      allBookings.where((b) => b.status == BookingStatus.confirmed).toList();

  List<Booking> get completedBookings =>
      allBookings.where((b) => b.status == BookingStatus.released).toList();

  List<Booking> get cancelledBookings =>
      allBookings.where((b) => b.status == BookingStatus.cancelled).toList();

  // Active bookings in client workspace (not completed, not cancelled)
  int get activeCount => allBookings
      .where(
        (b) =>
            b.status != BookingStatus.released &&
            b.status != BookingStatus.cancelled,
      )
      .length;

  // Total escrow funds currently held in protection
  int get totalEscrowHeld => allBookings
      .where(
        (b) =>
            b.status == BookingStatus.held ||
            b.status == BookingStatus.confirmed,
      )
      .fold(
        0,
        (sum, b) =>
            sum + (b.status == BookingStatus.held ? b.price : b.depositAmount),
      );

  // Filtered bookings based on selected tab
  List<Booking> get filteredBookings {
    switch (selectedTab) {
      case 'Sàn đang giữ tiền':
      case 'Đang thực hiện':
        return inProgressBookings;
      case 'Chờ đặt cọc':
        return allBookings
            .where((b) => b.status == BookingStatus.awaiting_deposit)
            .toList();
      case 'Chờ xác nhận':
      case 'Chờ duyệt':
        return allBookings
            .where((b) => b.status == BookingStatus.pending)
            .toList();
      case 'Chờ thanh toán':
      case 'Cần thanh toán':
        return selectedTab == 'Cần thanh toán'
            ? allBookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.awaiting_deposit ||
                        b.status == BookingStatus.confirmed,
                  )
                  .toList()
            : confirmedBookings;
      case 'Đã xác nhận':
        return confirmedBookings;
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
      final user = ref.read(authUserProvider);
      state = state.copyWith(
        isLoading: false,
        allBookings: user?.role == 'client'
            ? list.where((booking) => booking.clientId == user!.id).toList()
            : [],
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
    await _repo.updateBookingStatus(bookingId, newStatus);
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
}

final customerBookingsControllerProvider =
    NotifierProvider<CustomerBookingsController, CustomerBookingsState>(() {
      return CustomerBookingsController();
    });
