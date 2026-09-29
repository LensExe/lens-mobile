import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../repositories/mock_booking_repository.dart';

final customerBookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return MockBookingRepository();
});

class CustomerBookingsState {
  final bool isLoading;
  final List<Booking> allBookings;
  final String selectedTab; // 'Đang thực hiện', 'Tất cả', 'Chờ duyệt', 'Đã xác nhận', 'Hoàn thành', 'Đã hủy'

  CustomerBookingsState({
    this.isLoading = true,
    this.allBookings = const [],
    this.selectedTab = 'Đang thực hiện',
  });

  CustomerBookingsState copyWith({
    bool? isLoading,
    List<Booking>? allBookings,
    String? selectedTab,
  }) {
    return CustomerBookingsState(
      isLoading: isLoading ?? this.isLoading,
      allBookings: allBookings ?? this.allBookings,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  // Bookings currently undergoing active escrow / shooting / proofing
  List<Booking> get inProgressBookings =>
      allBookings.where((b) => b.status == BookingStatus.held).toList();

  List<Booking> get awaitingBookings =>
      allBookings.where((b) => b.status == BookingStatus.awaiting_deposit || b.status == BookingStatus.pending).toList();

  List<Booking> get confirmedBookings =>
      allBookings.where((b) => b.status == BookingStatus.confirmed).toList();

  List<Booking> get completedBookings =>
      allBookings.where((b) => b.status == BookingStatus.released).toList();

  List<Booking> get cancelledBookings =>
      allBookings.where((b) => b.status == BookingStatus.cancelled).toList();

  // Active bookings in client workspace (not completed, not cancelled)
  int get activeCount => allBookings.where((b) =>
      b.status != BookingStatus.released && b.status != BookingStatus.cancelled).length;

  // Total escrow funds currently held in protection
  int get totalEscrowHeld => allBookings
      .where((b) => b.status == BookingStatus.held || b.status == BookingStatus.confirmed)
      .fold(0, (sum, b) => sum + (b.status == BookingStatus.held ? b.price : b.depositAmount));

  // Filtered bookings based on selected tab
  List<Booking> get filteredBookings {
    switch (selectedTab) {
      case 'Đang thực hiện':
        return inProgressBookings;
      case 'Chờ duyệt':
        return awaitingBookings;
      case 'Đã xác nhận':
        return confirmedBookings;
      case 'Hoàn thành':
        return completedBookings;
      case 'Đã hủy':
        return cancelledBookings;
      case 'Tất cả':
      default:
        return allBookings;
    }
  }

  int getCountForTab(String tab) {
    switch (tab) {
      case 'Đang thực hiện':
        return inProgressBookings.length;
      case 'Chờ duyệt':
        return awaitingBookings.length;
      case 'Đã xác nhận':
        return confirmedBookings.length;
      case 'Hoàn thành':
        return completedBookings.length;
      case 'Đã hủy':
        return cancelledBookings.length;
      case 'Tất cả':
      default:
        return allBookings.length;
    }
  }
}

class CustomerBookingsController extends Notifier<CustomerBookingsState> {
  @override
  CustomerBookingsState build() {
    final state = CustomerBookingsState();
    Future.microtask(() => loadBookings());
    return state;
  }

  BookingRepository get _repo => ref.read(customerBookingRepositoryProvider);

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getBookings();
      state = state.copyWith(
        isLoading: false,
        allBookings: list,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void selectTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<void> updateStatus(String bookingId, BookingStatus newStatus) async {
    await _repo.updateBookingStatus(bookingId, newStatus);
    await loadBookings();
  }
}

final customerBookingsControllerProvider =
    NotifierProvider<CustomerBookingsController, CustomerBookingsState>(() {
  return CustomerBookingsController();
});
