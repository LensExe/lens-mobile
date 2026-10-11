import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/models/booking_model.dart';
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

class _BookingPaymentScreenState extends ConsumerState<_BookingPaymentScreen> {
  PaymentMethod _method = PaymentMethod.bank;
  PaymentIntent? _intent;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  bool _canPay(Booking booking) => widget.type == BookingPaymentType.deposit
      ? booking.status == BookingStatus.pending
      : booking.status == BookingStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(customerBookingsControllerProvider);
    Booking? booking;
    for (final item in bookingsState.allBookings) {
      if (item.id == widget.bookingId) {
        booking = item;
        break;
      }
    }

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

    final amount = widget.type == BookingPaymentType.deposit
        ? booking.depositAmount
        : booking.remainingAmount;
    final heading = widget.type == BookingPaymentType.deposit
        ? 'Thanh toán đặt cọc'
        : 'Thanh toán phần còn lại';

    return LensPage(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
        ),
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
          if (!_canPay(booking))
            _StatusNotice(
              icon: LucideIcons.info,
              title: 'Booking chưa ở trạng thái thanh toán này',
              message:
                  'Trạng thái hiện tại: ${_statusLabel(booking.status)}. Backend chỉ nhận tiền cọc khi yêu cầu đang chờ và tiền còn lại sau khi nhiếp ảnh gia chấp nhận.',
            )
          else ...[
            _methodSelector(),
            const SizedBox(height: 14),
            if (_intent != null) ...[
              _PaymentIntentPanel(
                intent: _intent!,
                isRefreshing: _isRefreshing,
                onRefresh: _refreshPayment,
              ),
              const SizedBox(height: 14),
            ],
            PrimaryButton(
              text: _intent == null
                  ? 'Tạo yêu cầu thanh toán'
                  : _intent!.status == 'paid'
                  ? 'Backend đã xác nhận thanh toán'
                  : 'Tạo lại / kiểm tra yêu cầu thanh toán',
              height: 52,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting || _intent?.status == 'paid'
                  ? null
                  : () => _createPayment(booking!),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Số tiền được xác định từ booking trên Backend. Tạo yêu cầu thanh toán chưa đồng nghĩa với việc giao dịch đã được thanh toán.',
            style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
          ),
        ],
      ),
    );
  }

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
            onTap: () => setState(() {
              _method = method;
              _intent = null;
            }),
          ),
      ],
    ),
  );

  Future<void> _createPayment(Booking booking) async {
    if (_isSubmitting || !_canPay(booking)) return;
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
      if (intent.status == 'pending' &&
          intent.checkoutUrl == null &&
          intent.qrCode == null) {
        try {
          intent = await ref
              .read(bookingPaymentRepositoryProvider)
              .getPaymentQr(intent.id);
        } on Object {
          // Keep the confirmed intent data if the provider has not prepared a QR yet.
        }
      }
      if (!mounted) return;
      setState(() => _intent = intent);
      if (intent.status == 'paid') {
        await ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings();
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

  Future<void> _refreshPayment() async {
    final current = _intent;
    if (current == null || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final updated = await ref
          .read(bookingPaymentRepositoryProvider)
          .getPayment(current.id);
      if (!mounted) return;
      setState(() => _intent = updated);
      if (updated.status == 'paid') {
        await ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings();
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
}

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
  });

  final PaymentIntent intent;
  final bool isRefreshing;
  final VoidCallback onRefresh;

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
          if (intent.checkoutUrl case final url? when url.isNotEmpty) ...[
            const SizedBox(height: 10),
            SelectableText(url, style: AppTypography.bodySm()),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép link thanh toán.'),
                      ),
                    );
                  }
                },
                icon: const Icon(LucideIcons.copy, size: 15),
                label: const Text('Sao chép link'),
              ),
            ),
          ],
          if (intent.qrCode case final qr? when qr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Mã QR do Backend trả về', style: AppTypography.labelMd()),
            SelectableText(qr, style: AppTypography.bodySm()),
          ],
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
  final VoidCallback onTap;

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
