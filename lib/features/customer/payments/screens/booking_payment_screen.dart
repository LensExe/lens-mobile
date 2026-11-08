import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lens_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bookings/controllers/customer_bookings_controller.dart';
import '../../bookings/models/booking_model.dart';
import '../repositories/payment_repository.dart';

class BookingPaymentScreen extends ConsumerStatefulWidget {
  const BookingPaymentScreen({
    super.key,
    required this.bookingId,
    required this.type,
  });

  final String bookingId;
  final BookingPaymentType type;

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen>
    with WidgetsBindingObserver {
  Booking? _booking;
  bool _isOpeningCheckout = false;
  bool _checkoutOpened = false;
  bool _isCheckingPayment = false;
  bool _paymentReceived = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_openCheckout);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_verifyPayment());
    }
  }

  Future<void> _openCheckout() async {
    if (_isOpeningCheckout || _checkoutOpened) return;
    setState(() {
      _isOpeningCheckout = true;
      _errorMessage = null;
    });
    try {
      final booking = await ref
          .read(customerBookingsControllerProvider.notifier)
          .loadBookingIfMissing(widget.bookingId);
      if (!mounted) return;
      if (booking == null) {
        throw StateError('Không tìm thấy lịch đặt trong tài khoản hiện tại.');
      }
      _booking = booking;

      final checkoutUrl = await ref
          .read(bookingPaymentRepositoryProvider)
          .createMobileCheckoutHandoff(
            bookingId: widget.bookingId,
            type: widget.type,
          );
      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          !['https', 'http'].contains(uri.scheme)) {
        throw StateError('Backend trả về đường dẫn thanh toán không hợp lệ.');
      }
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw StateError('Không mở được trang thanh toán trên trình duyệt.');
      }
      if (!mounted) return;
      setState(() => _checkoutOpened = true);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isOpeningCheckout = false);
    }
  }

  Future<void> _verifyPayment() async {
    if (_isCheckingPayment || _paymentReceived) return;
    setState(() => _isCheckingPayment = true);
    try {
      final booking =
          _booking ??
          await ref
              .read(customerBookingsControllerProvider.notifier)
              .loadBookingIfMissing(widget.bookingId);
      if (!mounted || booking == null) return;
      _booking = booking;

      final paidTotalProvider = bookingPaidTotalProvider(widget.bookingId);
      ref.invalidate(paidTotalProvider);
      final paidTotal = await ref.read(paidTotalProvider.future);
      final requiredAmount = widget.type == BookingPaymentType.deposit
          ? booking.depositAmount
          : booking.price;
      if (paidTotal < requiredAmount) return;

      _paymentReceived = true;
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .loadBookings();
      if (mounted) context.go('/customer_home/bookings');
    } catch (_) {
      // A temporarily unavailable payment history is not proof of payment.
    } finally {
      if (mounted) setState(() => _isCheckingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.type == BookingPaymentType.deposit
        ? 'Thanh toán đặt cọc'
        : 'Thanh toán phần còn lại';
    final amount = _booking == null
        ? null
        : widget.type == BookingPaymentType.deposit
        ? _booking!.depositAmount
        : (_booking!.price - _booking!.depositAmount).clamp(0, _booking!.price);

    return LensPage(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại lịch đặt',
          onPressed: () => context.go('/customer_home/bookings'),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
        ),
        title: Text(
          heading,
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.pageHorizontal),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(LucideIcons.globe, size: 46, color: AppColors.ember),
                const SizedBox(height: 18),
                Text(
                  _checkoutOpened ? 'Đã mở trang thanh toán' : heading,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSm(color: AppColors.obsidian),
                ),
                const SizedBox(height: 8),
                Text(
                  _checkoutOpened
                      ? 'Chọn QR/cổng thanh toán hoặc Ví Lens trên web. Sau khi thanh toán được xác nhận, bạn sẽ quay lại ứng dụng.'
                      : 'Lens đang mở trang thanh toán bảo mật trên web.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(color: AppColors.steel),
                ),
                const SizedBox(height: 24),
                if (_booking != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.snow,
                      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                      border: Border.all(color: AppColors.pebble),
                      boxShadow: const [AppTokens.surfaceShadow],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Lịch đặt', value: _booking!.id),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: heading,
                          value: amount == null
                              ? 'Đang tải...'
                              : AppTypography.formatCurrency(amount),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm(color: AppColors.destructive),
                  ),
                ],
                if (_checkoutOpened && !_paymentReceived) ...[
                  const SizedBox(height: 16),
                  Text(
                    _isCheckingPayment
                        ? 'Đang kiểm tra trạng thái thanh toán...'
                        : 'Chưa ghi nhận thanh toán. Nếu bạn đã thanh toán, đợi trong giây lát rồi thử kiểm tra lại.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm(color: AppColors.steel),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  onPressed: _isOpeningCheckout || _isCheckingPayment
                      ? null
                      : _checkoutOpened
                      ? _verifyPayment
                      : _openCheckout,
                  isLoading: _isOpeningCheckout || _isCheckingPayment,
                  text: _checkoutOpened
                      ? 'Kiểm tra thanh toán'
                      : _errorMessage == null
                      ? 'Đang mở trang thanh toán...'
                      : 'Thử mở lại trang thanh toán',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/customer_home/bookings'),
                  child: const Text('Về danh sách lịch đặt'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTypography.bodySm(color: AppColors.steel)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
    ],
  );
}
