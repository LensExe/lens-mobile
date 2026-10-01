import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../providers/data_providers.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../../bookings/repositories/booking_repository.dart';
import '../../bookings/repositories/customer_booking_repository_provider.dart';
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
      availabilityMap: _generateAvailability(initialDate),
    );
  }

  PhotographerDetailRepository get _profileRepo =>
      ref.read(photographerDetailRepositoryProvider);

  BookingRepository get _bookingRepo =>
      ref.read(customerBookingRepositoryProvider);

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

  Future<void> _refreshAvailability(String photographerId) async {
    final request = ++_availabilityRequest;
    final map = _generateAvailability(state.selectedDate);
    final bookings = await _bookingRepo.getBookings();
    if (request != _availabilityRequest) return;
    for (final booking in bookings) {
      if (booking.photographerId != photographerId ||
          booking.status == BookingStatus.cancelled ||
          booking.timeSlot == null) {
        continue;
      }
      final day = map[booking.date];
      if (day == null) continue;
      final parts = booking.timeSlot!.split(' - ');
      final start = _slotMinutes(parts.first);
      final end = parts.length == 2
          ? _slotMinutes(parts.last)
          : start +
                ((booking.packageSnapshot?.durationHours ?? 1) * 60).round();
      map[booking.date] = DayAvailability(
        date: day.date,
        isBookable: day.isBookable,
        slots: [
          for (final slot in day.slots)
            TimeSlotAvailability(
              time: slot.time,
              status:
                  _slotMinutes(slot.time) >= start &&
                      _slotMinutes(slot.time) < end
                  ? 'booked'
                  : slot.status,
            ),
        ],
      );
    }
    state = state.copyWith(availabilityMap: map);
  }

  static int _slotMinutes(String time) {
    final pieces = time.split(':');
    return int.parse(pieces[0]) * 60 + int.parse(pieces[1]);
  }

  void selectPackage(String packageId) {
    if (state.selectedPackageId == packageId) return;
    state = state.copyWith(selectedPackageId: packageId, clearTimeSlot: true);
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
      final currentUser = ref.read(authUserProvider);
      if (currentUser == null ||
          currentUser.role != 'client' ||
          profile == null ||
          pkg == null) {
        throw StateError(
          'Vui lòng đăng nhập với tài khoản khách hàng và chọn gói chụp.',
        );
      }
      final bookingId = 'bk-${DateTime.now().microsecondsSinceEpoch}';
      final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);
      final startTime = state.selectedTimeSlot ?? '14:00';
      final endTime = _calculateEndTime(startTime, state.durationHours);
      final fullTimeSlot = '$startTime - $endTime';

      final newBooking = Booking(
        id: bookingId,
        clientId: currentUser.id,
        clientName: state.contactName.trim(),
        photographerId: profile.id,
        photographerName: profile.name,
        photographerAvatar: profile.avatarUrl,
        style: profile.styles.firstWhere(
          (style) => style != 'Tất cả',
          orElse: () => '',
        ),
        date: dateStr,
        timeSlot: fullTimeSlot,
        location: state.addressDetail.trim().isNotEmpty
            ? '${state.addressDetail.trim()}, ${state.city.trim()}'
            : state.city.trim(),
        price: state.price,
        status: BookingStatus.awaiting_deposit,
        packageId: state.selectedPackageId,
        packageSnapshot: PackageTerms(
          name: pkg.name,
          photoCount:
              pkg.photoCount ??
              int.tryParse(
                RegExp(r'\d+')
                        .firstMatch(pkg.deliverables.join(' '))
                        ?.group(0) ??
                    '',
              ) ??
              0,
          durationHours: state.durationHours,
          deliveryDays: pkg.deliveryDays ?? 3,
        ),
        contactPhone: state.contactPhone.trim(),
        note: state.note.trim().isNotEmpty ? state.note.trim() : null,
        depositAmount: state.depositAmount,
        depositDeadline: DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String(),
        rating: profile.rating,
        reviewCount: profile.reviewCount,
        createdTimeAgo: 'Vừa xong',
      );

      await _bookingRepo.createBooking(newBooking);

      if (state.saveAsDefault) {
        await ref
            .read(authUserProvider.notifier)
            .updateProfile(
              name: state.contactName.trim(),
              phone: state.contactPhone.trim(),
              city: state.city.trim(),
              address: state.addressDetail.trim(),
              saveAsDefault: true,
            );
      }

      ref.read(customerBookingsControllerProvider.notifier).loadBookings();

      state = state.copyWith(isSubmitting: false, createdBookingId: bookingId);

      return newBooking;
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
