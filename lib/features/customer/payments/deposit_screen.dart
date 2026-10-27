import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/models/booking_model.dart';
import '../bookings/repositories/booking_gallery_repository.dart';
import 'payment_method.dart';
import 'payment_repository.dart';

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => _BookingPaymentScreen(
    bookingId: bookingId,
    type: BookingPaymentType.deposit,
  );
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => _BookingPaymentScreen(
    bookingId: bookingId,
    type: BookingPaymentType.remaining,
  );
}

class _BookingPaymentScreen extends ConsumerStatefulWidget {
  const _BookingPaymentScreen({required this.bookingId, required this.type});
  final String bookingId;
  final BookingPaymentType type;

  @override
  ConsumerState<_BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<_BookingPaymentScreen>
    with WidgetsBindingObserver {
  PaymentMethod _method = PaymentMethod.bank;
  PaymentIntent? _intent;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  bool _isRestoringPayment = true;
  bool _successHandled = false;
  bool _successRefreshInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_restoreExistingPayment);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(bookingPaidTotalProvider(widget.bookingId));
    if (_intent != null && _intent!.status != 'paid') {
      unawaited(_refreshPayment(showPendingStatus: false));
    }
  }

  bool _canPay(Booking booking, int paidAmount) {
    if (widget.type == BookingPaymentType.deposit) {
      return booking.flowStatus == BookingStatus.awaiting_deposit &&
          paidAmount < booking.depositAmount;
    }
    return [
          BookingStatus.accepted,
          BookingStatus.confirmed,
          BookingStatus.shot,
        ].contains(booking.status) &&
        paidAmount < booking.price;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(customerBookingsControllerProvider);
    final paidTotalState = ref.watch(
      bookingPaidTotalProvider(widget.bookingId),
    );
    Booking? booking;
    for (final item in bookingsState.allBookings) {
      if (item.id == widget.bookingId) {
        booking = item;
        break;
      }
    }

    ref.listen<AsyncValue<int>>(bookingPaidTotalProvider(widget.bookingId), (
      _,
      next,
    ) {
      final currentBooking = booking;
      final paidAmount = next.value;
      if (currentBooking == null ||
          next.isLoading ||
          next.hasError ||
          paidAmount == null) {
        return;
      }
      final requiredAmount = widget.type == BookingPaymentType.deposit
          ? currentBooking.depositAmount
          : currentBooking.price;
      if (paidAmount >= requiredAmount) {
        unawaited(_handlePaymentConfirmed());
      }
    });

    if (booking == null) {
      return LensPage(
        appBar: AppBar(title: const Text('Thanh toán booking')),
        body: bookingsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            : LensEmptyState(
                icon: LucideIcons.calendarX2,
                title: 'Không tìm thấy lịch đặt',
                message:
                    bookingsState.errorMessage ??
                    'Lịch đặt không còn khả dụng.',
                actionLabel: 'Về lịch đặt',
                onAction: () => context.go('/customer_home/bookings'),
              ),
      );
    }

    final paidAmount = paidTotalState.value ?? booking.paidAmount;
    final paymentStatusVerified =
        paidTotalState.hasValue &&
        !paidTotalState.isLoading &&
        !paidTotalState.hasError;
    final amount = widget.type == BookingPaymentType.deposit
        ? (paidAmount >= booking.depositAmount
              ? 0
              : booking.depositAmount - paidAmount)
        : (paidAmount >= booking.price ? 0 : booking.price - paidAmount);
    final heading = widget.type == BookingPaymentType.deposit
        ? 'Thanh toán đặt cọc'
        : 'Thanh toán phần còn lại';

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/customer_home/bookings');
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/customer_home/bookings');
        }
      },
      child: LensPage(
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: handleBack,
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          ),
          actions: [
            IconButton(
              tooltip: 'Về trang chủ',
              onPressed: () => context.go('/customer_home'),
              icon: const Icon(LucideIcons.home, color: AppColors.obsidian),
            ),
          ],
          title: Text(heading, style: AppTypography.titleMd()),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            16,
            AppTokens.pageHorizontal,
            40,
          ),
          children: [
            _PaymentSummary(booking: booking, amount: amount),
            const SizedBox(height: 14),
            if (paidTotalState.hasError)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusNotice(
                    icon: LucideIcons.circleAlert,
                    title: 'Chưa xác minh được thanh toán',
                    message: 'Ứng dụng chưa tải được lịch sử thanh toán từ Backend. Tạm thời không tạo thêm yêu cầu để tránh thanh toán trùng.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(
                      bookingPaidTotalProvider(widget.bookingId),
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 17),
                    label: const Text('Kiểm tra lại thanh toán'),
                  ),
                ],
              )
            else if (!paymentStatusVerified)
              const _StatusNotice(
                icon: LucideIcons.clock3,
                title: 'Đang xác minh thanh toán',
                message: 'Đợi Backend đối soát các khoản đã thanh toán trước khi tạo yêu cầu mới.',
              )
            else if (!_canPay(booking, paidAmount))
              _StatusNotice(
                icon: LucideIcons.info,
                title: _paymentIsComplete(booking, paidAmount)
                    ? 'Đã thanh toán đủ'
                    : widget.type == BookingPaymentType.deposit
                    ? 'Booking đã qua bước đặt cọc'
                    : 'Booking chưa ở trạng thái thanh toán này',
                message: _paymentIsComplete(booking, paidAmount)
                    ? 'Backend đã ghi nhận khoản thanh toán này. Bạn không cần thanh toán thêm.'
                    : widget.type == BookingPaymentType.deposit
                    ? 'Tiền cọc đã được ghi nhận hoặc yêu cầu không còn chờ cọc. Hãy kiểm tra trạng thái booking.'
                    : 'Trạng thái hiện tại: ${_statusLabel(booking.status)}. Phần còn lại được thanh toán sau khi nhiếp ảnh gia xác nhận lịch.',
              )
            else ...[
              _methodSelector(),
              const SizedBox(height: 14),
              if (_intent != null) ...[
                _PaymentIntentPanel(
                  intent: _intent!,
                  isRefreshing: _isRefreshing,
                  onRefresh: _refreshPayment,
                  onNavigateToBookings: () =>
                      context.go('/customer_home/bookings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/customer_home'),
                  icon: const Icon(LucideIcons.home, size: 18),
                  label: const Text('Về trang chủ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: AppColors.pebble),
                    foregroundColor: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              PrimaryButton(
                text: _intent == null
                    ? 'Tạo yêu cầu thanh toán'
                    : _intent!.status == 'paid'
                    ? 'Thanh toán thành công · Về lịch đặt'
                    : 'Làm mới mã / kiểm tra thanh toán',
                height: 52,
                isLoading: _isSubmitting || _isRestoringPayment,
                onPressed:
                    _isSubmitting ||
                        _isRestoringPayment ||
                        _intent?.status == 'failed'
                    ? null
                    : _intent?.status == 'paid'
                    ? () => context.go('/customer_home/bookings')
                    : _intent == null
                    ? () => _createPayment(booking!)
                    : _refreshPayment,
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Số tiền được xác định từ booking trên Backend. Tạo yêu cầu thanh toán chưa đồng nghĩa với việc giao dịch đã được thanh toán.',
              style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
            ),
          ],
        ),
      ),
    );
  }

  bool _paymentIsComplete(Booking booking, int paidAmount) =>
      widget.type == BookingPaymentType.deposit
      ? paidAmount >= booking.depositAmount
      : paidAmount >= booking.price;

  Widget _methodSelector() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phương thức', style: AppTypography.titleMd()),
        const SizedBox(height: 12),
        for (final method in PaymentMethod.values)
          _PaymentOption(
            method: method,
            selected: _method == method,
            onTap: _intent != null || _isRestoringPayment
                ? null
                : () => setState(() => _method = method),
          ),
      ],
    ),
  );

  Future<void> _restoreExistingPayment() async {
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .loadBookingIfMissing(widget.bookingId);
      final history = await ref
          .read(bookingPaymentRepositoryProvider)
          .getBookingHistory(widget.bookingId);
      PaymentIntent? existing;
      for (final payment in history.items.reversed) {
        if (payment.type == widget.type.name) {
          existing = payment;
          break;
        }
      }
      if (existing == null) return;

      final intent = await _loadCheckoutDetails(existing);
      if (!mounted) return;
      setState(() {
        _intent = intent;
        if (intent.paymentGateway == 'wallet_internal') {
          _method = PaymentMethod.wallet;
        } else if (intent.paymentGateway != null) {
          _method = PaymentMethod.bank;
        }
      });
      if (intent.status == 'paid') {
        await _refreshBookingAfterPayment();
        _showPaymentSuccess();
      }
    } on Object {
      // Payment history is a recovery aid. The user can still create or
      // retrieve the idempotent intent if this read is temporarily unavailable.
    } finally {
      if (mounted) setState(() => _isRestoringPayment = false);
    }
  }

  Future<void> _createPayment(Booking booking) async {
    final paidTotalState = ref.read(bookingPaidTotalProvider(booking.id));
    if (_isSubmitting ||
        paidTotalState.isLoading ||
        paidTotalState.hasError ||
        !paidTotalState.hasValue ||
        !_canPay(booking, paidTotalState.value!)) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      var intent = await ref
          .read(bookingPaymentRepositoryProvider)
          .createIntent(
            bookingId: booking.id,
            type: widget.type,
            method: _method == PaymentMethod.wallet
                ? BookingPaymentMethod.wallet
                : BookingPaymentMethod.gateway,
          );
      intent = await _loadCheckoutDetails(intent);
      if (!mounted) return;
      setState(() => _intent = intent);
      if (intent.status == 'paid') {
        await _refreshBookingAfterPayment();
        _showPaymentSuccess();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend không thể tạo payment intent: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _refreshPayment({bool showPendingStatus = true}) async {
    final current = _intent;
    if (current == null || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      var updated = await ref
          .read(bookingPaymentRepositoryProvider)
          .getPayment(current.id);
      updated = await _loadCheckoutDetails(updated);
      if (!mounted) return;
      setState(() => _intent = updated);
      if (updated.status == 'paid') {
        await _refreshBookingAfterPayment();
        _showPaymentSuccess();
      } else if (showPendingStatus) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Trạng thái hiện tại: ${updated.status}. Chưa ghi nhận thanh toán.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải trạng thái từ Backend: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshBookingAfterPayment() async {
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .loadBookings();
    } on Object {
      // The settled payment history is authoritative for the success message;
      // a separate booking refresh failure should not hide that confirmation.
    }
    if (!mounted) return;
    ref.invalidate(bookingPaidTotalProvider(widget.bookingId));
    ref.invalidate(bookingGalleryProvider(widget.bookingId));
  }

  Future<void> _handlePaymentConfirmed() async {
    if (!mounted || _successHandled || _successRefreshInProgress) return;
    _successRefreshInProgress = true;
    try {
      await _refreshBookingAfterPayment();
    } finally {
      _successRefreshInProgress = false;
    }
    _showPaymentSuccess();
  }

  void _showPaymentSuccess() {
    if (!mounted || _successHandled) return;
    _successHandled = true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Thanh toán thành công! Backend đã xác nhận giao dịch.',
          ),
          backgroundColor: AppColors.emerald,
          duration: Duration(seconds: 3),
        ),
      );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/customer_home/bookings');
    });
  }

  Future<PaymentIntent> _loadCheckoutDetails(PaymentIntent intent) async {
    if (intent.status != 'pending' ||
        intent.checkoutUrl != null ||
        intent.qrCode != null) {
      return intent;
    }
    try {
      final qr = await ref
          .read(bookingPaymentRepositoryProvider)
          .getPaymentQr(intent.id);
      return _mergeQrDetails(intent, qr);
    } on Object {
      // Keep the intent visible; refresh can retry checkout preparation.
      return intent;
    }
  }
}

PaymentIntent _mergeQrDetails(PaymentIntent payment, PaymentIntent qr) =>
    PaymentIntent(
      id: payment.id,
      status: qr.status,
      amount: payment.amount,
      currency: payment.currency,
      type: payment.type,
      paymentGateway: payment.paymentGateway,
      checkoutUrl: qr.checkoutUrl ?? payment.checkoutUrl,
      qrCode: qr.qrCode ?? payment.qrCode,
      checkoutExpiresAt: qr.checkoutExpiresAt ?? payment.checkoutExpiresAt,
    );

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.booking, required this.amount});
  final Booking booking;
  final int amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.pebble),
      boxShadow: const [AppTokens.surfaceShadow],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chi tiết booking', style: AppTypography.titleMd()),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Nhiếp ảnh gia', value: booking.photographerName),
        _SummaryRow(label: 'Địa điểm', value: booking.location),
        _SummaryRow(
          label: 'Tổng giá trị',
          value: AppTypography.formatCurrency(booking.price),
        ),
        _SummaryRow(
          label: 'Tiền cọc Backend xác định',
          value: AppTypography.formatCurrency(booking.depositAmount),
        ),
        const Divider(height: 22),
        Text(
          AppTypography.formatCurrency(amount),
          style: AppTypography.priceDisplay(fontSize: 26),
        ),
        Text(
          'Số tiền của đợt thanh toán này',
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
      ],
    ),
  );
}

class _PaymentIntentPanel extends StatelessWidget {
  const _PaymentIntentPanel({
    required this.intent,
    required this.isRefreshing,
    required this.onRefresh,
    this.onNavigateToBookings,
  });

  final PaymentIntent intent;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback? onNavigateToBookings;

  @override
  Widget build(BuildContext context) {
    final paid = intent.status == 'paid';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paid ? AppColors.emerald.withValues(alpha: 0.08) : AppColors.fog,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                paid ? LucideIcons.circleCheck : LucideIcons.clock3,
                color: paid ? AppColors.emerald : AppColors.ember,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  paid
                      ? 'Backend xác nhận đã thanh toán'
                      : 'Payment intent đã tạo',
                  style: AppTypography.titleMd(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Trạng thái: ${intent.status} · ${AppTypography.formatCurrency(intent.amount)} ${intent.currency}',
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
          if (intent.qrCode case final qr? when qr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Mã QR do Backend trả về', style: AppTypography.labelMd()),
            const SizedBox(height: 10),
            Center(child: _BackendQrCode(value: qr)),
            const SizedBox(height: 12),
            Center(
              child: _DownloadQrButton(
                qrData: qr,
                name:
                    'lens_qr_${intent.id.length > 8 ? intent.id.substring(0, 8) : intent.id}',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kiểm tra đúng số tiền và nội dung chuyển khoản trong ứng dụng ngân hàng trước khi xác nhận.',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
          ],
          if (intent.status == 'failed')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Payment intent này đã thất bại. Backend hiện không cho phép tạo lại intent trên cùng booking; vui lòng liên hệ hỗ trợ để xử lý.',
                style: AppTypography.bodySm(color: AppColors.ember),
              ),
            ),
          if (!paid)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 15),
                label: const Text('Kiểm tra trạng thái'),
              ),
            )
          else if (onNavigateToBookings != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PrimaryButton(
                text: 'Xem danh sách lịch đặt',
                height: 44,
                onPressed: onNavigateToBookings,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(
      method == PaymentMethod.wallet
          ? LucideIcons.wallet
          : LucideIcons.landmark,
      color: selected ? AppColors.ember : AppColors.steel,
    ),
    title: Text(method.label, style: AppTypography.labelMd()),
    subtitle: Text(
      method.hint,
      style: AppTypography.bodySm(color: AppColors.steel),
    ),
    trailing: Icon(
      selected ? LucideIcons.circleCheck : LucideIcons.circle,
      color: selected ? AppColors.ember : AppColors.steel,
    ),
  );
}

class _BackendQrCode extends StatelessWidget {
  const _BackendQrCode({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(value);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'vietqr.app') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          value,
          width: 240,
          height: 240,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _qrError(),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  width: 240,
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
        ),
      );
    }

    return Container(
      width: 256,
      height: 256,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.pebble),
      ),
      child: QrImageView(
        data: value,
        version: QrVersions.auto,
        size: 232,
        backgroundColor: Colors.white,
        semanticsLabel: 'Mã QR thanh toán booking',
      ),
    );
  }

  Widget _qrError() => Container(
    width: 240,
    height: 240,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Không tải được ảnh QR từ Backend. Hãy dùng link thanh toán nếu có hoặc thử làm mới.',
      textAlign: TextAlign.center,
      style: AppTypography.bodySm(color: AppColors.steel),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.labelMd(color: AppColors.obsidian),
          ),
        ),
      ],
    ),
  );
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.pebble),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.steel),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMd(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                message,
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _statusLabel(BookingStatus status) => switch (status) {
  BookingStatus.pending => 'pending',
  BookingStatus.accepted => 'accepted',
  BookingStatus.rejected => 'rejected',
  BookingStatus.cancelled => 'cancelled',
  BookingStatus.expired => 'expired',
  BookingStatus.inProgress => 'in_progress',
  BookingStatus.shot => 'shot',
  BookingStatus.completed => 'completed',
  BookingStatus.awaiting_deposit => 'chờ cọc (demo)',
  BookingStatus.confirmed => 'đã xác nhận (demo)',
  BookingStatus.held => 'đang giữ tiền (demo)',
  BookingStatus.released => 'hoàn tất (demo)',
};

class _DownloadQrButton extends StatefulWidget {
  const _DownloadQrButton({required this.qrData, this.name});
  final String qrData;
  final String? name;

  @override
  State<_DownloadQrButton> createState() => _DownloadQrButtonState();
}

class _DownloadQrButtonState extends State<_DownloadQrButton> {
  bool _isDownloading = false;

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cấp quyền lưu ảnh vào thiết bị.'),
            ),
          );
        }
        return;
      }

      Uint8List? bytes;
      final uri = Uri.tryParse(widget.qrData);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final response = await Dio().get<List<int>>(
          widget.qrData,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = response.data;
        if (data != null && data.isNotEmpty) {
          bytes = Uint8List.fromList(data);
        }
      } else {
        final painter = QrPainter(
          data: widget.qrData,
          version: QrVersions.auto,
          gapless: true,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
        );
        final picData = await painter.toImageData(
          800,
          format: ui.ImageByteFormat.png,
        );
        if (picData != null) {
          bytes = picData.buffer.asUint8List();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw StateError('Không thể tạo hình ảnh QR.');
      }

      final fileName =
          widget.name ?? 'qr_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(bytes, album: 'LENS', name: fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tải mã QR về máy thành công.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải mã QR: $e'),
            backgroundColor: AppColors.ember,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isDownloading ? null : _download,
      icon: _isDownloading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.download, size: 16),
      label: Text(
        _isDownloading ? 'Đang tải...' : 'Tải mã QR về máy',
        style: AppTypography.labelMd(fontSize: 13, color: AppColors.obsidian),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.obsidian,
        side: const BorderSide(color: AppColors.pebble),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
