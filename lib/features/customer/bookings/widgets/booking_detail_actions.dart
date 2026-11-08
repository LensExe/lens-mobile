import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../payments/repositories/payment_repository.dart';
import '../models/booking_model.dart';
import 'cancel_booking_dialog.dart';

class BookingDetailActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const BookingDetailActionCard({
    super.key,
    required this.icon,
    this.iconColor = AppColors.obsidian,
    this.iconBgColor = AppColors.fog,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMd(
                        fontSize: 15,
                        color: AppColors.obsidian,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTypography.bodySm(
                        fontSize: 12.5,
                        color: AppColors.steel,
                      ).copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primaryAction != null) ...[
            const SizedBox(height: 16),
            primaryAction!,
          ],
          if (secondaryAction != null) ...[
            const SizedBox(height: 8),
            Center(child: secondaryAction!),
          ],
        ],
      ),
    );
  }
}

class BookingDetailActions extends ConsumerWidget {
  final Booking booking;
  const BookingDetailActions({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPayRemaining =
        booking.status == BookingStatus.accepted ||
        booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.shot;
    final paidTotalState = canPayRemaining
        ? ref.watch(bookingPaidTotalProvider(booking.id))
        : null;
    final paidAmount = paidTotalState?.value ?? booking.paidAmount;
    final isFullyPaid = paidAmount >= booking.price;
    final isCheckingPayment =
        canPayRemaining &&
        (paidTotalState?.isLoading == true || paidTotalState?.hasValue != true);
    final paymentCheckFailed =
        canPayRemaining && paidTotalState?.hasError == true;
    final paymentAmountVerified =
        canPayRemaining &&
        paidTotalState?.hasValue == true &&
        paidTotalState?.isLoading == false &&
        paidTotalState?.hasError == false;
    final outstanding = paidAmount >= booking.price
        ? 0
        : booking.price - paidAmount;
    final isWaitingForDelivery =
        booking.status == BookingStatus.inProgress ||
        booking.backendStatus == 'in_progress';
    final shouldOfferRemainingPayment =
        canPayRemaining && paymentAmountVerified && paidAmount < booking.price;

    Widget retryPaymentCheck() => OutlinedButton.icon(
      onPressed: () => ref.invalidate(bookingPaidTotalProvider(booking.id)),
      icon: const Icon(LucideIcons.refreshCw, size: 17),
      label: const Text('Kiểm tra lại thanh toán'),
    );

    switch (booking.status) {
      case BookingStatus.awaiting_deposit:
        return BookingDetailActionCard(
          icon: LucideIcons.creditCard,
          iconColor: AppColors.ember,
          iconBgColor: AppColors.ember.withValues(alpha: 0.1),
          title: 'Chờ đặt cọc giữ lịch',
          message: 'Đặt cọc 30% để giữ lịch chụp. Yêu cầu sẽ được chuyển tới nhiếp ảnh gia ngay sau khi thanh toán.',
          primaryAction: PrimaryButton(
            text:
                'Đặt cọc ngay · ${AppTypography.formatCurrency(booking.depositAmount)}',
            height: 48,
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/deposit'),
          ),
          secondaryAction: TextButton(
            onPressed: () => _cancel(context, ref),
            child: Text(
              'Huỷ lịch chụp',
              style: AppTypography.labelMd(color: AppColors.crimson),
            ),
          ),
        );

      case BookingStatus.pending:
        return BookingDetailActionCard(
          icon: LucideIcons.clock3,
          iconColor: AppColors.ember,
          iconBgColor: AppColors.ember.withValues(alpha: 0.1),
          title: 'Đang chờ nhiếp ảnh gia xác nhận',
          message: 'Tiền cọc đã được ghi nhận. Yêu cầu đang chờ nhiếp ảnh gia xác nhận lịch.',
          secondaryAction: TextButton(
            onPressed: () => _cancel(context, ref),
            child: Text(
              'Hủy yêu cầu',
              style: AppTypography.labelMd(color: AppColors.crimson),
            ),
          ),
        );

      case BookingStatus.accepted:
      case BookingStatus.confirmed:
        return BookingDetailActionCard(
          icon: LucideIcons.creditCard,
          iconColor: AppColors.emerald,
          iconBgColor: AppColors.emerald.withValues(alpha: 0.1),
          title: 'Lịch chụp đã được xác nhận',
          message: shouldOfferRemainingPayment
              ? 'Backend xác nhận còn ${AppTypography.formatCurrency(outstanding)} cần thanh toán.'
              : paymentCheckFailed
              ? 'Chưa xác minh được lịch sử thanh toán. Tạm ẩn nút thanh toán để tránh trả trùng.'
              : isCheckingPayment
              ? 'Đang xác minh các khoản đã thanh toán với Backend.'
              : 'Backend đã ghi nhận đủ khoản thanh toán cho booking này.',
          primaryAction: shouldOfferRemainingPayment
              ? PrimaryButton(
                  text:
                      'Thanh toán còn lại · ${AppTypography.formatCurrency(outstanding)}',
                  height: 48,
                  onPressed: () =>
                      context.push('/customer_home/bookings/${booking.id}/pay'),
                )
              : paymentCheckFailed
              ? retryPaymentCheck()
              : null,
          secondaryAction: TextButton(
            onPressed: () => _cancel(context, ref),
            child: Text(
              'Huỷ lịch chụp',
              style: AppTypography.labelMd(color: AppColors.crimson),
            ),
          ),
        );

      case BookingStatus.inProgress:
      case BookingStatus.held:
        return BookingDetailActionCard(
          icon: LucideIcons.shieldCheck,
          iconColor: AppColors.emerald,
          iconBgColor: AppColors.emerald.withValues(alpha: 0.1),
          title: 'Buổi chụp đang được thực hiện',
          message: shouldOfferRemainingPayment
              ? 'Backend xác nhận còn ${AppTypography.formatCurrency(outstanding)} cần thanh toán sau khi buổi chụp hoàn tất.'
              : isWaitingForDelivery && !isFullyPaid
              ? 'Buổi chụp đang diễn ra. Thanh toán phần còn lại sau khi nhiếp ảnh gia đánh dấu đã chụp.'
              : isFullyPaid
              ? 'Backend đã ghi nhận đủ khoản thanh toán. Gallery sẽ xuất hiện sau khi photographer công bố ảnh.'
              : 'Khoản thanh toán còn lại cần hoàn tất trước khi photographer công bố gallery.',
          primaryAction: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (shouldOfferRemainingPayment) ...[
                PrimaryButton(
                  text:
                      'Thanh toán còn lại · ${AppTypography.formatCurrency(outstanding)}',
                  height: 48,
                  onPressed: () =>
                      context.push('/customer_home/bookings/${booking.id}/pay'),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push(
                        '/customer_home/bookings/${booking.id}/gallery',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.pebble),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.pillRadius,
                          ),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        'Mở bộ ảnh',
                        style: AppTypography.labelMd(color: AppColors.obsidian),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Kiểm tra ảnh',
                      height: 48,
                      onPressed: () => context.push(
                        '/customer_home/bookings/${booking.id}/gallery',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          secondaryAction: _canCancel(booking)
              ? TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: Text(
                    'Huỷ lịch / Khiếu nại',
                    style: AppTypography.labelMd(color: AppColors.crimson),
                  ),
                )
              : null,
        );

      case BookingStatus.shot:
        return BookingDetailActionCard(
          icon: LucideIcons.images,
          iconColor: AppColors.lagoon,
          iconBgColor: AppColors.lagoon.withValues(alpha: 0.1),
          title: 'Buổi chụp đã hoàn tất',
          message: booking.galleryPublishedAt == null
              ? shouldOfferRemainingPayment
                    ? 'Backend xác nhận còn ${AppTypography.formatCurrency(outstanding)} cần thanh toán để nhiếp ảnh gia có thể công bố gallery.'
                    : paymentCheckFailed
                    ? 'Chưa xác minh được lịch sử thanh toán. Hãy kiểm tra lại trước khi thanh toán hoặc nghiệm thu ảnh.'
                    : isCheckingPayment
                    ? 'Đang xác minh khoản thanh toán với Backend.'
                    : 'Đã thanh toán đủ. Nhiếp ảnh gia có thể công bố gallery.'
              : 'Mở gallery đã được Backend công khai để xem ảnh và xác nhận đã nhận.',
          primaryAction:
              shouldOfferRemainingPayment ||
                  paymentCheckFailed ||
                  booking.galleryPublishedAt != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (shouldOfferRemainingPayment) ...[
                      PrimaryButton(
                        text:
                            'Thanh toán còn lại · ${AppTypography.formatCurrency(outstanding)}',
                        height: 48,
                        onPressed: () => context.push(
                          '/customer_home/bookings/${booking.id}/pay',
                        ),
                      ),
                      if (booking.galleryPublishedAt != null)
                        const SizedBox(height: 8),
                    ],
                    if (paymentCheckFailed) ...[
                      retryPaymentCheck(),
                      if (booking.galleryPublishedAt != null)
                        const SizedBox(height: 8),
                    ],
                    if (booking.galleryPublishedAt != null)
                      OutlinedButton(
                        onPressed: () => context.push(
                          '/customer_home/bookings/${booking.id}/gallery',
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.pebble),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTokens.pillRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Mở bộ ảnh',
                          style: AppTypography.labelMd(
                            color: AppColors.obsidian,
                          ),
                        ),
                      ),
                  ],
                )
              : null,
        );

      case BookingStatus.completed:
      case BookingStatus.released:
        return BookingDetailActionCard(
          icon: LucideIcons.checkCircle2,
          iconColor: AppColors.emerald,
          iconBgColor: AppColors.emerald.withValues(alpha: 0.1),
          title: 'Buổi chụp hoàn tất',
          message: 'Ảnh đã nghiệm thu thành công. Toàn bộ tiền đã được giải ngân an toàn cho nhiếp ảnh gia.',
          primaryAction: PrimaryButton(
            text: 'Xem lại bộ sưu tập ảnh',
            height: 48,
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/gallery'),
          ),
        );

      case BookingStatus.cancelled:
        return const BookingDetailActionCard(
          icon: LucideIcons.circleX,
          iconColor: AppColors.crimson,
          iconBgColor: Color(0x1AE11D48),
          title: 'Lịch đặt chụp đã huỷ',
          message: 'Lịch chụp này đã được huỷ bỏ theo chính sách hoàn tiền.',
        );

      case BookingStatus.rejected:
        return const BookingDetailActionCard(
          icon: LucideIcons.circleX,
          iconColor: AppColors.crimson,
          iconBgColor: Color(0x1AE11D48),
          title: 'Yêu cầu bị từ chối',
          message: 'Backend đã ghi nhận trạng thái từ chối cho booking này.',
        );

      case BookingStatus.expired:
        return const BookingDetailActionCard(
          icon: LucideIcons.clockAlert,
          iconColor: AppColors.steel,
          iconBgColor: AppColors.fog,
          title: 'Yêu cầu đã hết hạn',
          message: 'Backend đã đóng yêu cầu booking này.',
        );
    }
  }

  bool _canCancel(Booking booking) =>
      [
        BookingStatus.awaiting_deposit,
        BookingStatus.pending,
        BookingStatus.confirmed,
      ].contains(booking.flowStatus) ||
      (booking.backendStatus == null &&
          booking.status == BookingStatus.accepted);

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await CancelBookingDialog.show(context, booking);
  }
}
