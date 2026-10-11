import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/data_providers.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/repositories/booking_repository.dart';
import '../../photographer_detail/repositories/photographer_detail_repository.dart';
import '../../photographer_detail/repositories/photographer_detail_repository_provider.dart';
import '../models/booking_wizard_state.dart';
import '../models/day_availability.dart';

class BookingWizardController extends Notifier<BookingWizardState> {
  int _availabilityRequest = 0;
  @override
  BookingWizardState build() {
    final now = DateTime.now();
    final initialDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 2));

    ref.watch(authUserProvider.select((user) => user?.id));
    final user = ref.read(authUserProvider);

    return BookingWizardState(
      selectedDate: initialDate,
      contactName: user?.name ?? '',
      contactPhone: user?.phone ?? '',
      city: user?.city ?? '',
      addressDetail: user?.address ?? '',
      note: '',
      saveAsDefault: user?.saveAsDefault ?? false,
      isAutofilled: user != null,
      availabilityMap: const {},
    );
  }

  PhotographerDetailRepository get _profileRepo =>
      ref.read(photographerDetailRepositoryProvider);

  Future<void> init(String photographerId, {String? packageId}) async {
    await _loadProfile(photographerId, packageId: packageId);
  }

  Future<void> _loadProfile(String photographerId, {String? packageId}) async {
    try {
      final profile = await _profileRepo.getPhotographerProfile(photographerId);

      state = state.copyWith(
        profile: profile,
        selectedPackageId: profile.packages.any((pkg) => pkg.id == packageId)
            ? packageId
            : null,
      );
      await _refreshAvailability(profile.id);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Không thể tải hồ sơ nhiếp ảnh gia: $e',
      );
    }
  }

  Future<void> _refreshAvailability(String photographerId) async {
    final request = ++_availabilityRequest;
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = from.add(const Duration(days: 30));
      final ranges = await _profileRepo.getAvailability(
        photographerId: photographerId,
        from: from,
        to: to,
      );
      if (request != _availabilityRequest) return;

      final map = <String, DayAvailability>{};
      for (var index = 0; index < 30; index++) {
        final date = from.add(Duration(days: index));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final slots = <TimeSlotAvailability>[];
        for (final range in ranges) {
          final rangeStart = range.from.toLocal();
          final rangeEnd = range.to.toLocal();
          final startsAt = rangeStart.isAfter(dayStart) ? rangeStart : dayStart;
          final endsAt = rangeEnd.isBefore(dayEnd) ? rangeEnd : dayEnd;
          if (!endsAt.isAfter(startsAt)) continue;
          slots.add(
            TimeSlotAvailability(
              time: DateFormat('HH:mm').format(startsAt),
              status: 'free',
              availableUntil: endsAt,
            ),
          );
        }
        slots.sort((a, b) => a.time.compareTo(b.time));
        map[DateFormat('yyyy-MM-dd').format(date)] = DayAvailability(
          date: date,
          isBookable: slots.isNotEmpty,
          slots: slots,
        );
      }
      state = state.copyWith(availabilityMap: map, clearTimeSlot: true);
    } catch (error) {
      if (request != _availabilityRequest) return;
      state = state.copyWith(
        availabilityMap: const {},
        errorMessage: 'Không thể tải lịch trống từ Backend: $error',
      );
    }
  }

  void selectPackage(String packageId) {
    if (state.selectedPackageId == packageId) return;
    state = state.copyWith(selectedPackageId: packageId, clearTimeSlot: true);
    if (state.profile != null) _refreshAvailability(state.profile!.id);
  }

  void selectDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    state = state.copyWith(selectedDate: dateOnly, clearTimeSlot: true);
    if (state.profile != null) _refreshAvailability(state.profile!.id);
  }

  void selectTimeSlot(String timeSlot) {
    final key = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    if (state.availabilityMap[key]?.canStartAt(timeSlot, state.durationHours) ==
        true) {
      state = state.copyWith(selectedTimeSlot: timeSlot);
    }
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

  Future<Booking?> submitBooking() async {
    if (!state.isStep3Valid) return null;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final profile = state.profile;
      final pkg = state.selectedPackage;
      final currentUser = ref.read(authUserProvider);
      if (currentUser == null ||
          currentUser.role != 'client' ||
          profile == null ||
          pkg == null) {
        throw StateError(
          'Vui lòng đăng nhập với tài khoản khách hàng và chọn gói chụp.',
        );
      }
      final selectedTime = state.selectedTimeSlot;
      final planId = state.selectedPackageId;
      if (selectedTime == null ||
          planId == null ||
          pkg.durationMinutes == null ||
          pkg.durationMinutes! <= 0 ||
          state.bookingLocation.isEmpty) {
        throw StateError('Thiếu gói, địa điểm hoặc thời lượng hợp lệ.');
      }
      final parts = selectedTime.split(':');
      final from = DateTime(
        state.selectedDate.year,
        state.selectedDate.month,
        state.selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final to = from.add(Duration(minutes: pkg.durationMinutes!));
      final created = await ref
          .read(customerBookingsControllerProvider.notifier)
          .createBookingFromInput(
            BookingCreateInput(
              photographerId: profile.id,
              bookingPlanId: planId,
              location: state.bookingLocation,
              from: from,
              to: to,
              photographerName: profile.name,
              photographerAvatar: profile.avatarUrl,
            ),
          );

      state = state.copyWith(isSubmitting: false, createdBookingId: created.id);

      return created;
    } catch (e) {
      final conflict = e.toString().contains('Khung giờ này không còn trống');
      if (conflict && state.profile != null) {
        await _refreshAvailability(state.profile!.id);
      }
      state = state.copyWith(
        isSubmitting: false,
        currentStep: conflict ? 0 : state.currentStep,
        clearTimeSlot: conflict,
        errorMessage: conflict
            ? 'Khung giờ này không còn trống. Vui lòng chọn khung giờ khác.'
            : 'Không thể tạo lịch đặt: $e',
      );
      return null;
    }
  }
}

final bookingWizardControllerProvider =
    NotifierProvider<BookingWizardController, BookingWizardState>(() {
      return BookingWizardController();
    });
