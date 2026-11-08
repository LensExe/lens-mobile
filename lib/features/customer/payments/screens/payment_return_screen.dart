import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lens_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../payments/repositories/payment_repository.dart';

class PaymentReturnScreen extends ConsumerStatefulWidget {
  const PaymentReturnScreen({
    super.key,
    required this.bookingId,
    required this.paymentPurpose,
  });

  final String bookingId;
  final String paymentPurpose;

  @override
  ConsumerState<PaymentReturnScreen> createState() =>
      _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends ConsumerState<PaymentReturnScreen> {
  bool _checking = true;
  bool _verified = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    Future.microtask(_verifyAndReturn);
  }

  Future<void> _verifyAndReturn() async {
    if (!mounted) return;
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      if (!['deposit', 'remaining'].contains(widget.paymentPurpose)) {
        throw StateError('Liên kết quay về không hợp lệ.');
      }
      final controller = ref.read(customerBookingsControllerProvider.notifier);
      final booking = await controller.loadBookingIfMissing(widget.bookingId);
      if (booking == null) {
        throw StateError('Không tìm thấy lịch đặt trong tài khoản hiện tại.');
      }
      final paidProvider = bookingPaidTotalProvider(widget.bookingId);
      ref.invalidate(paidProvider);
      final paidTotal = await ref.read(paidProvider.future);
      final requiredAmount = widget.paymentPurpose == 'deposit'
          ? booking.depositAmount
          : booking.price;
      if (paidTotal < requiredAmount) {
        setState(() {
          _verified = false;
          _message = 'Backend chưa ghi nhận đủ khoản thanh toán. Hãy thử kiểm tra lại sau ít phút.';
        });
        return;
      }

      _verified = true;
      await controller.loadBookings();
      if (mounted) context.go('/customer_home/bookings');
    } catch (error) {
      if (mounted) {
        setState(() => _message = error.toString());
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LensPage(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _verified
                      ? LucideIcons.checkCircle2
                      : LucideIcons.shieldCheck,
                  size: 48,
                  color: _verified ? AppColors.success : AppColors.ember,
                ),
                const SizedBox(height: 18),
                Text(
                  _verified
                      ? 'Thanh toán đã được xác nhận'
                      : 'Đang xác nhận thanh toán',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSm(),
                ),
                const SizedBox(height: 8),
                Text(
                  _checking
                      ? 'Lens đang kiểm tra giao dịch với Backend.'
                      : _message ?? 'Bạn có thể quay lại danh sách lịch đặt.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(color: AppColors.steel),
                ),
                if (_checking) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.ember),
                ] else if (!_verified) ...[
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Kiểm tra lại',
                    isLoading: false,
                    onPressed: _verifyAndReturn,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/customer_home/bookings'),
                    child: const Text('Về danh sách lịch đặt'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
