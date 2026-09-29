import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/booking_wizard_controller.dart';
import '../widgets/booking_stepper_header.dart';
import '../widgets/step1_package_schedule_view.dart';
import '../widgets/step2_contact_location_view.dart';
import '../widgets/step3_review_agreement_view.dart';

class BookingWizardScreen extends ConsumerStatefulWidget {
  final String photographerId;

  const BookingWizardScreen({super.key, required this.photographerId});

  @override
  ConsumerState<BookingWizardScreen> createState() =>
      _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  DateTime? _lastSubmitTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(bookingWizardControllerProvider.notifier)
          .init(widget.photographerId);
    });
  }

  void _onNext() {
    final controller = ref.read(bookingWizardControllerProvider.notifier);
    final state = ref.read(bookingWizardControllerProvider);

    if (state.currentStep == 0) {
      if (!state.isStep1Valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn đầy đủ gói chụp và khung giờ bắt đầu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      controller.nextStep();
    } else if (state.currentStep == 1) {
      if (!state.isStep2Valid) {
        String msg = 'Vui lòng kiểm tra lại thông tin liên hệ';
        if (!state.isNameValid) {
          msg = 'Họ và tên phải có ít nhất 2 ký tự';
        } else if (!state.isPhoneValid) {
          msg = 'Số điện thoại không hợp lệ (VD: 0901234567)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      controller.nextStep();
    } else if (state.currentStep == 2) {
      _onSubmit();
    }
  }

  void _onBack() {
    final controller = ref.read(bookingWizardControllerProvider.notifier);
    final state = ref.read(bookingWizardControllerProvider);

    if (state.currentStep > 0) {
      controller.prevStep();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/customer_home/discovery');
      }
    }
  }

  Future<void> _onSubmit() async {
    // Chống bấm đúp nhanh 400ms theo tài liệu nghiệp vụ
    final now = DateTime.now();
    if (_lastSubmitTime != null &&
        now.difference(_lastSubmitTime!).inMilliseconds < 400) {
      return;
    }
    _lastSubmitTime = now;

    final controller = ref.read(bookingWizardControllerProvider.notifier);
    final state = ref.read(bookingWizardControllerProvider);

    if (!state.agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng đồng ý với điều khoản đặt lịch và chính sách đặt cọc',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final booking = await controller.submitBooking();
    if (!mounted) return;

    if (booking != null) {
      // Chuyển thẳng sang Bước 4: Màn hình Đặt cọc dùng chung với booking detail.
      context.go('/customer_home/bookings/${booking.id}/deposit');
    } else {
      final error =
          state.errorMessage ?? 'Không thể tạo đơn đặt lịch, vui lòng thử lại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingWizardControllerProvider);
    final controller = ref.read(bookingWizardControllerProvider.notifier);

    bool isCtaEnabled = false;
    String ctaText = 'Tiếp tục';

    if (state.currentStep == 0) {
      isCtaEnabled = state.isStep1Valid;
      ctaText = 'Tiếp tục: Điền thông tin';
    } else if (state.currentStep == 1) {
      isCtaEnabled = state.isStep2Valid;
      ctaText = 'Tiếp tục: Xem lại & Cam kết';
    } else if (state.currentStep == 2) {
      isCtaEnabled = state.agreedToTerms && !state.isSubmitting;
      ctaText = 'Xác nhận & đặt cọc 30%';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stepper Header
            BookingStepperHeader(
              currentStep: state.currentStep,
              onBack: _onBack,
            ),

            // Step Content
            Expanded(
              child: IndexedStack(
                index: state.currentStep,
                children: [
                  Step1PackageScheduleView(
                    state: state,
                    onSelectPackage: controller.selectPackage,
                    onSelectDate: controller.selectDate,
                    onSelectTimeSlot: controller.selectTimeSlot,
                  ),
                  Step2ContactLocationView(
                    state: state,
                    onNameChanged: controller.updateContactName,
                    onPhoneChanged: controller.updateContactPhone,
                    onCityChanged: controller.updateCity,
                    onAddressChanged: controller.updateAddressDetail,
                    onNoteChanged: controller.updateNote,
                    onSaveDefaultChanged: controller.toggleSaveAsDefault,
                  ),
                  Step3ReviewAgreementView(
                    state: state,
                    onJumpToStep: controller.goToStep,
                    onToggleAgreement: controller.toggleAgreedToTerms,
                  ),
                ],
              ),
            ),

            // Bottom CTA Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isCtaEnabled ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ember,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8E8E9),
                    disabledForegroundColor: const Color(0xFF8E8E93),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          ctaText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
