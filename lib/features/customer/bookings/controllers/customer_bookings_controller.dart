import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
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
            b.flowStatus == BookingStatus.held ||
            (b.backendStatus == null && b.status == BookingStatus.inProgress),
      )
      .toList();

  List<Booking> get awaitingBookings => allBookings
      .where(
        (b) =>
            b.flowStatus == BookingStatus.awaiting_deposit ||
            b.flowStatus == BookingStatus.pending ||
            b.flowStatus == BookingStatus.confirmed ||
            (b.backendStatus == null && b.status == BookingStatus.accepted),
      )
      .toList();

  List<Booking> get confirmedBookings => allBookings
      .where(
        (b) =>
            b.flowStatus == BookingStatus.confirmed ||
            (b.backendStatus == null && b.status == BookingStatus.accepted),
      )
      .toList();

  List<Booking> get completedBookings => allBookings
      .where(
        (b) =>
            b.flowStatus == BookingStatus.released ||
            (b.backendStatus == null && b.status == BookingStatus.completed),
      )
      .toList();

  List<Booking> get cancelledBookings => allBookings
      .where(
        (b) =>
            b.flowStatus == BookingStatus.cancelled ||
            (b.backendStatus == null &&
                [
                  BookingStatus.rejected,
                  BookingStatus.expired,
                  BookingStatus.cancelled,
                ].contains(b.status)),
      )
      .toList();

  // Active bookings in client workspace (not completed, not cancelled)
  int get activeCount => allBookings
      .where(
        (b) => ![
          BookingStatus.released,
          BookingStatus.cancelled,
          BookingStatus.completed,
          BookingStatus.rejected,
          BookingStatus.expired,
        ].contains(b.flowStatus),
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
            .where((b) => b.flowStatus == BookingStatus.pending)
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
                  b.flowStatus == BookingStatus.awaiting_deposit ||
                  b.flowStatus == BookingStatus.confirmed ||
                  b.needsRemainingPayment ||
                  (b.backendStatus == null &&
                      b.status == BookingStatus.accepted),
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
  int _loadRequest = 0;
  final Set<String> _uncertainBookingInputs = <String>{};
  final Map<String, Booking> _cachedBookings = <String, Booking>{};

  @override
  CustomerBookingsState build() {
    ref.watch(authUserProvider);
    _uncertainBookingInputs.clear();
    _cachedBookings.clear();
    final state = CustomerBookingsState();
    Future.microtask(() => loadBookings());
    return state;
  }

  BookingRepository get _repo => ref.read(customerBookingRepositoryProvider);

  Future<void> loadBookings() async {
    final request = ++_loadRequest;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getBookings();
      if (request != _loadRequest) return;
      state = state.copyWith(
        isLoading: false,
        // GET /bookings is already scoped to the authenticated Backend actor.
        // customer_id is a separate entity UUID, not the user's auth UUID.
        allBookings: ref.read(authUserProvider)?.role == 'client'
            ? _mergeCachedBookings(list)
            : [],
      );
    } catch (_) {
      if (request != _loadRequest) return;
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

    final inputKey = _bookingInputKey(input);
    if (_uncertainBookingInputs.contains(inputKey)) {
      try {
        final bookings = await _repo.getBookings();
        final recovered = _findMatchingBooking(bookings, input);
        if (recovered != null) {
          _uncertainBookingInputs.remove(inputKey);
          _cacheBooking(recovered);
          return recovered;
        }
        _uncertainBookingInputs.remove(inputKey);
      } catch (_) {
        throw const ApiException(
          'Kết quả gửi lịch trước đó chưa xác định. Chưa thể kiểm tra lịch đã được tạo hay chưa; vui lòng làm mới mục Lịch đặt trước khi gửi lại.',
        );
      }
    }

    final existing = _findMatchingBooking(state.allBookings, input);
    if (existing != null) return existing;

    try {
      final booking = await _repo.createBookingFromInput(input);
      _cacheBooking(booking);
      await loadBookings();
      // Keep the just-created booking available even if the list endpoint is
      // briefly stale immediately after the POST.
      _cacheBooking(booking);
      return booking;
    } catch (error, stackTrace) {
      // A timeout or response-decoding error can happen after the Backend has
      // committed the booking. Reconcile before allowing the caller to retry
      // the POST, since a pending booking reserves its time slot.
      var reconciliationSucceeded = false;
      try {
        final bookings = await _repo.getBookings();
        reconciliationSucceeded = true;
        final recovered = _findMatchingBooking(bookings, input);
        if (recovered != null) {
          _uncertainBookingInputs.remove(inputKey);
          _cacheBooking(recovered);
          return recovered;
        }
      } catch (_) {
        // Preserve the original POST error when the reconciliation GET also
        // fails; its failure cannot prove that the booking was not created.
      }
      if (!reconciliationSucceeded || _mightHaveCommitted(error)) {
        _uncertainBookingInputs.add(inputKey);
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Booking?> loadBookingIfMissing(String bookingId) async {
    for (final booking in state.allBookings) {
      if (booking.id == bookingId) return booking;
    }
    final booking = await _repo.getBookingById(bookingId);
    if (booking == null || ref.read(authUserProvider)?.role != 'client') {
      return null;
    }
    _cacheBooking(booking);
    return booking;
  }

  void _cacheBooking(Booking booking) {
    _cachedBookings[booking.id] = booking;
    state = state.copyWith(
      allBookings: [
        booking,
        ...state.allBookings.where((item) => item.id != booking.id),
      ],
    );
  }

  List<Booking> _mergeCachedBookings(List<Booking> serverBookings) {
    final merged = List<Booking>.of(serverBookings);
    final serverIds = merged.map((booking) => booking.id).toSet();
    for (final entry in _cachedBookings.entries.toList()) {
      if (serverIds.contains(entry.key)) {
        _cachedBookings.remove(entry.key);
      } else {
        merged.insert(0, entry.value);
      }
    }
    return merged;
  }

  Booking? _findMatchingBooking(
    List<Booking> bookings,
    BookingCreateInput input,
  ) {
    for (final booking in bookings) {
      final canContinueToPayment =
          booking.status == BookingStatus.awaiting_deposit ||
          booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.accepted;
      if (!canContinueToPayment ||
          booking.photographerId != input.photographerId ||
          booking.packageId != input.bookingPlanId ||
          booking.location.trim() != input.location.trim() ||
          !_sameWallMinute(_bookingTime(booking, end: false), input.from)) {
        continue;
      }
      final bookingEnd = _bookingTime(booking, end: true);
      if (bookingEnd == null || _sameWallMinute(bookingEnd, input.to)) {
        return booking;
      }
    }
    return null;
  }
}

String _bookingInputKey(BookingCreateInput input) {
  String stamp(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  return [
    input.photographerId,
    input.bookingPlanId,
    input.location.trim(),
    stamp(input.from),
    stamp(input.to),
  ].join('|');
}

bool _mightHaveCommitted(Object error) {
  if (error is! ApiException) return true;
  final statusCode = error.statusCode;
  return statusCode == null || statusCode >= 500;
}

DateTime? _bookingTime(Booking booking, {required bool end}) {
  final dateParts = booking.date.split('-').map(int.tryParse).toList();
  if (dateParts.length != 3 || dateParts.any((part) => part == null)) {
    return null;
  }
  final times = (booking.timeSlot ?? '').split(' - ');
  final time = times.length > 1 ? times[end ? 1 : 0] : (end ? '' : times.first);
  final timeParts = time.split(':').map(int.tryParse).toList();
  if (timeParts.length != 2 || timeParts.any((part) => part == null)) {
    return null;
  }
  return DateTime.utc(
    dateParts[0]!,
    dateParts[1]!,
    dateParts[2]!,
    timeParts[0]!,
    timeParts[1]!,
  );
}

bool _sameWallMinute(DateTime? first, DateTime second) =>
    first != null &&
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day &&
    first.hour == second.hour &&
    first.minute == second.minute;

final customerBookingsControllerProvider =
    NotifierProvider<CustomerBookingsController, CustomerBookingsState>(() {
      return CustomerBookingsController();
    });
