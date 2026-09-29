import '../models/day_availability.dart';
import '../../photographer_detail/models/photographer_detail_model.dart';

class BookingWizardState {
  final int currentStep; // 0: Step 1, 1: Step 2, 2: Step 3
  final PhotographerProfile? profile;

  // Step 1: Package & Schedule
  final String? selectedPackageId;
  final DateTime selectedDate;
  final String? selectedTimeSlot;
  final Map<String, DayAvailability> availabilityMap;

  // Step 2: Contact & Location
  final String contactName;
  final String contactPhone;
  final String city;
  final String addressDetail;
  final String note;
  final bool saveAsDefault;
  final bool isAutofilled;

  // Step 3: Review & Agreement
  final bool agreedToTerms;
  final bool isSubmitting;
  final String? createdBookingId;
  final String? errorMessage;

  const BookingWizardState({
    this.currentStep = 0,
    this.profile,
    this.selectedPackageId,
    required this.selectedDate,
    this.selectedTimeSlot,
    this.availabilityMap = const {},
    this.contactName = '',
    this.contactPhone = '',
    this.city = 'TP. Hồ Chí Minh',
    this.addressDetail = '',
    this.note = '',
    this.saveAsDefault = false,
    this.isAutofilled = false,
    this.agreedToTerms = false,
    this.isSubmitting = false,
    this.createdBookingId,
    this.errorMessage,
  });

  ProfilePackage? get selectedPackage {
    if (profile == null || selectedPackageId == null) return null;
    try {
      return profile!.packages.firstWhere((p) => p.id == selectedPackageId);
    } catch (_) {
      return profile!.packages.isNotEmpty ? profile!.packages.first : null;
    }
  }

  double get durationHours {
    final pkg = selectedPackage;
    if (pkg == null) return 2.0;
    // Parse duration: e.g. "1.5 Giờ" -> 1.5, "3 Giờ" -> 3.0, "5 Giờ" -> 5.0
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(pkg.duration);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '2.0') ?? 2.0;
    }
    return 2.0;
  }

  int get price => selectedPackage?.price ?? profile?.startingPrice ?? 2800000;

  int get depositAmount => (price * 0.3).round();

  int get remainingAmount => price - depositAmount;

  // Standard Cities
  static const List<String> standardCities = [
    "Hà Nội",
    "TP. Hồ Chí Minh",
    "Đà Nẵng",
    "Đà Lạt",
    "Cần Thơ",
    "Hải Phòng",
  ];

  // Validation
  bool get isPhoneValid {
    return RegExp(r'^(0|\+84)\d{8,10}$').hasMatch(contactPhone.trim());
  }

  bool get isNameValid => contactName.trim().length >= 2;

  bool get isCityValid => standardCities.contains(city.trim());

  bool get isStep1Valid =>
      selectedPackageId != null &&
      selectedTimeSlot != null &&
      selectedTimeSlot!.isNotEmpty;

  bool get isStep2Valid => isNameValid && isPhoneValid && isCityValid;

  bool get isStep3Valid => isStep1Valid && isStep2Valid && agreedToTerms;

  BookingWizardState copyWith({
    int? currentStep,
    PhotographerProfile? profile,
    String? selectedPackageId,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    Map<String, DayAvailability>? availabilityMap,
    String? contactName,
    String? contactPhone,
    String? city,
    String? addressDetail,
    String? note,
    bool? saveAsDefault,
    bool? isAutofilled,
    bool? agreedToTerms,
    bool? isSubmitting,
    String? createdBookingId,
    String? errorMessage,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      profile: profile ?? this.profile,
      selectedPackageId: selectedPackageId ?? this.selectedPackageId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      availabilityMap: availabilityMap ?? this.availabilityMap,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      city: city ?? this.city,
      addressDetail: addressDetail ?? this.addressDetail,
      note: note ?? this.note,
      saveAsDefault: saveAsDefault ?? this.saveAsDefault,
      isAutofilled: isAutofilled ?? this.isAutofilled,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdBookingId: createdBookingId ?? this.createdBookingId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
