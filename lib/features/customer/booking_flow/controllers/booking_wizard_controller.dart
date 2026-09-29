import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/repositories/booking_repository.dart';
import '../../photographer_detail/repositories/photographer_detail_repository.dart';
import '../../photographer_detail/controllers/photographer_detail_controller.dart';
import '../models/booking_wizard_state.dart';
import '../models/day_availability.dart';

class BookingWizardController extends Notifier<BookingWizardState> {
  @override
  BookingWizardState build() {
    final now = DateTime.now();
    final initialDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 2));

    return BookingWizardState(
      selectedDate: initialDate,
      contactName: 'Trần Khách Hàng',
      contactPhone: '0901234567',
      city: 'TP. Hồ Chí Minh',
      addressDetail: 'Studio 4B, 15 Lê Lợi, Phường Bến Nghé, Quận 1',
      note: 'Chụp lookbook thời trang cho bộ sưu tập Thu Đông, cần tư vấn thêm về concept ánh sáng.',
      saveAsDefault: false,
      isAutofilled: true,
      availabilityMap: _generateAvailability(initialDate),
    );
  }

  PhotographerDetailRepository get _profileRepo =>
      ref.read(photographerDetailRepositoryProvider);

  BookingRepository get _bookingRepo =>
      ref.read(customerBookingRepositoryProvider);

  Future<void> init(String photographerId) async {
    await _loadProfile(photographerId);
  }

  Future<void> _loadProfile(String photographerId) async {
    try {
      final profile = await _profileRepo.getPhotographerProfile(photographerId);

      String? defaultPkgId;
      if (profile.packages.isNotEmpty) {
        final popularPkg = profile.packages.firstWhere(
          (p) =>
              p.isMostSelected ||
              p.highlightBadge.contains('Phổ biến') ||
              p.highlightBadge.contains('nhiều nhất'),
          orElse: () => profile.packages.first,
        );
        defaultPkgId = popularPkg.id;
      }

      state = state.copyWith(
        profile: profile,
        selectedPackageId: defaultPkgId,
        selectedTimeSlot: '14:00',
      );
    } catch (_) {
      // Fallback
    }
  }

  static Map<String, DayAvailability> _generateAvailability(
    DateTime startDate,
  ) {
    final Map<String, DayAvailability> map = {};
    for (int i = 0; i < 30; i++) {
      final d = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(d);

      final isWeekend =
          d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
      final booked = isWeekend
          ? ['09:00', '09:30', '10:00', '15:00', '15:30']
          : ['10:00', '10:30', '16:00'];
      final busy = ['12:00', '12:30'];

      map[dateKey] = DayAvailability(
        date: d,
        isBookable: true,
        slots: DayAvailability.generateDefaultSlots(
          bookedSlots: booked,
          busySlots: busy,
        ),
      );
    }
    return map;
  }

  void selectPackage(String packageId) {
    if (state.selectedPackageId == packageId) return;
    state = state.copyWith(
      selectedPackageId: packageId,
      selectedTimeSlot: null,
    );
  }

  void selectDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: dateOnly, selectedTimeSlot: null);
  }

  void selectTimeSlot(String timeSlot) {
    state = state.copyWith(selectedTimeSlot: timeSlot);
  }

  void updateContactName(String name) {
    state = state.copyWith(contactName: name);
  }

  void updateContactPhone(String phone) {
    state = state.copyWith(contactPhone: phone);
  }

  void updateCity(String city) {
    state = state.copyWith(city: city);
  }

  void updateAddressDetail(String address) {
    state = state.copyWith(addressDetail: address);
  }

  void updateNote(String note) {
    state = state.copyWith(note: note);
  }

  void toggleSaveAsDefault(bool value) {
    state = state.copyWith(saveAsDefault: value);
  }

  void toggleAgreedToTerms(bool value) {
    state = state.copyWith(agreedToTerms: value);
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  bool nextStep() {
    if (state.currentStep == 0) {
      if (!state.isStep1Valid) return false;
      state = state.copyWith(currentStep: 1);
      return true;
    } else if (state.currentStep == 1) {
      if (!state.isStep2Valid) return false;
      state = state.copyWith(currentStep: 2);
      return true;
    }
    return false;
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  String _calculateEndTime(String startTime, double durationHours) {
    final parts = startTime.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final totalMinutes = (h * 60 + m + (durationHours * 60).round());
    final endH = (totalMinutes ~/ 60) % 24;
    final endM = totalMinutes % 60;
    return '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
  }

  Future<Booking?> submitBooking() async {
    if (!state.isStep3Valid) return null;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final profile = state.profile;
      final pkg = state.selectedPackage;
      final bookingId = 'bk-${Random().nextInt(89999) + 10000}';
      final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      final startTime = state.selectedTimeSlot ?? '14:00';
      final endTime = _calculateEndTime(startTime, state.durationHours);
      final fullTimeSlot = '$startTime - $endTime';

      final newBooking = Booking(
        id: bookingId,
        clientId: 'u-khachhang',
        clientName: state.contactName.trim(),
        photographerId: profile?.id ?? 'p2',
        photographerName: profile?.name ?? 'Elena Rostova',
        photographerAvatar: profile?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
        style: profile != null && profile.styles.length > 1
            ? profile.styles[1]
            : 'Thời trang',
        date: dateStr,
        timeSlot: fullTimeSlot,
        location: state.addressDetail.trim().isNotEmpty
            ? '${state.addressDetail.trim()}, ${state.city.trim()}'
            : state.city.trim(),
        price: state.price,
        status: BookingStatus.awaiting_deposit,
        packageId: state.selectedPackageId,
        packageSnapshot: PackageTerms(
          name: pkg?.name ?? 'Gói chụp tiêu chuẩn',
          photoCount: pkg != null ? 35 : 20,
          durationHours: state.durationHours,
          deliveryDays: 3,
        ),
        contactPhone: state.contactPhone.trim(),
        note: state.note.trim().isNotEmpty ? state.note.trim() : null,
        depositAmount: state.depositAmount,
        depositDeadline: DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String(),
        rating: profile?.rating ?? 4.98,
        reviewCount: profile?.reviewCount ?? 64,
        createdTimeAgo: 'Vừa xong',
      );

      await _bookingRepo.createBooking(newBooking);

      ref.read(customerBookingsControllerProvider.notifier).loadBookings();

      state = state.copyWith(isSubmitting: false, createdBookingId: bookingId);

      return newBooking;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Có lỗi xảy ra: $e',
      );
      return null;
    }
  }
}

final bookingWizardControllerProvider =
    NotifierProvider<BookingWizardController, BookingWizardState>(() {
      return BookingWizardController();
    });
