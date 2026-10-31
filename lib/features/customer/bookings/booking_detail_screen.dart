import 'package:cached_network_image/cached_network_image.dart';
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
import 'controllers/customer_bookings_controller.dart';
import 'models/booking_model.dart';
import '../payments/payment_repository.dart';
import 'booking_report_entry.dart';
import 'widgets/booking_progress_stepper.dart';
import 'widgets/booking_status_pill.dart';
import 'widgets/cancel_booking_dialog.dart';
import 'widgets/booking_report_panel.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerBookingsControllerProvider);
    final matches = state.allBookings
        .where((item) => item.id == bookingId)
        .toList();
    final booking = matches.isEmpty ? null : matches.first;

    if (state.isLoading && booking == null) {
      return const LensPage(
        body: Center(child: CircularProgressIndicator(color: AppColors.ember)),
      );
    }
    if (booking == null) {
      return LensPage(
        appBar: AppBar(
          title: Text(
            'Chi tiết lịch đặt',
            style: AppTypography.headlineSm(color: AppColors.obsidian),
          ),
        ),
        body: LensEmptyState(
          icon: LucideIcons.calendarX2,
          title: 'Không tìm thấy lịch đặt',
          message: 'Lịch đặt có thể đã bị xoá hoặc không còn khả dụng.',
          actionLabel: 'Về lịch đặt',
          onAction: () => context.go('/customer_home/bookings'),
        ),
      );
    }

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
        if (didPop) return;
        context.go('/customer_home/bookings');
      },
      child: LensPage(
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: InkWell(
                onTap: handleBack,
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.snow,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pebble),
                    boxShadow: const [AppTokens.surfaceShadow],
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Chi tiết lịch đặt',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
          actions: [
            IconButton(
              tooltip: 'Tải hoá đơn VAT',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Yêu cầu xuất hoá đơn VAT điện tử đã được gửi tới hệ thống LENS Care.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.receipt,
                  size: 16,
                  color: AppColors.obsidian,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Chia sẻ',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: '/customer_home/bookings/${booking.id}'),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép liên kết lịch chụp'),
                  ),
                );
              },
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.share2,
                  size: 16,
                  color: AppColors.obsidian,
                ),
              ),
            ),
            const SizedBox(width: AppTokens.pageHorizontal),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.ember,
          onRefresh: () async {
            await ref
                .read(customerBookingsControllerProvider.notifier)
                .loadBookings();
            ref.invalidate(bookingPaidTotalProvider(booking.id));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pageHorizontal,
              12,
              AppTokens.pageHorizontal,
              60,
            ),
            children: [
              _BookingHeading(booking: booking),
              const SizedBox(height: 14),
              _BookingSummary(booking: booking),
              const SizedBox(height: 12),
              _BookingCost(booking: booking),
              const SizedBox(height: 12),
              _BookingActions(booking: booking),
              if ([
                BookingStatus.inProgress,
                BookingStatus.held,
                BookingStatus.shot,
                BookingStatus.completed,
                BookingStatus.released,
              ].contains(booking.status)) ...[
                const SizedBox(height: 12),
                BookingReportEntry(bookingId: booking.id),
              ],
              const SizedBox(height: 12),
              if (booking.status == BookingStatus.held ||
                  booking.status == BookingStatus.released ||
                  (booking.status == BookingStatus.shot &&
                      booking.galleryPublishedAt != null)) ...[
                _EmbeddedGalleryPanel(booking: booking),
                const SizedBox(height: 12),
              ],
              BookingReportPanel(booking: booking),
              const SizedBox(height: 12),
              _EscrowNotice(),
              const SizedBox(height: 12),
              _TimelineCard(booking: booking),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingHeading extends StatelessWidget {
  final Booking booking;
  const _BookingHeading({required this.booking});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Buổi chụp #${booking.displayCode}',
        style: AppTypography.headlineSm(
          fontSize: 20,
          color: AppColors.obsidian,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${_dateLabel(booking.date)} · Mã đặt: ${booking.id}',
        style: AppTypography.bodySm(color: AppColors.steel),
      ),
      const SizedBox(height: 8),
      BookingStatusPill(
        status: booking.flowStatus,
        paymentDue: booking.paymentDue,
      ),
    ],
  );
}

class _BookingSummary extends StatelessWidget {
  final Booking booking;
  const _BookingSummary({required this.booking});

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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  color: AppColors.fog,
                ),
                child: ClipOval(
                  child:
                      booking.photographerAvatar != null &&
                          booking.photographerAvatar!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: booking.photographerAvatar!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Center(
                            child: Icon(
                              LucideIcons.camera,
                              color: AppColors.steel,
                              size: 20,
                            ),
                          ),
                          errorWidget: (_, _, _) => Center(
                            child: Text(
                              _initials(booking.photographerName),
                              style: AppTypography.titleMd(),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(booking.photographerName),
                            style: AppTypography.titleMd(),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.photographerName,
                      style: AppTypography.titleMd(
                        fontSize: 16,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nhiếp ảnh gia chuyên nghiệp',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => context.push(
                      '/customer_home/messages/${booking.photographerId}',
                    ),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pebble.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.messageCircle,
                        color: AppColors.obsidian,
                        size: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.pebble, height: 1),
          ),
          _InfoRow(
            icon: LucideIcons.calendarDays,
            label: 'Thời gian',
            value:
                '${_dateLabel(booking.date)}${booking.timeSlot == null ? '' : ' · ${booking.timeSlot}'}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: LucideIcons.mapPin,
            label: 'Địa điểm',
            value: booking.location,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: LucideIcons.camera,
            label: 'Gói chụp',
            value: booking.packageSnapshot?.name ?? booking.style,
          ),
          if (booking.note != null && booking.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: LucideIcons.stickyNote,
              label: 'Ghi chú',
              value: booking.note!,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingCost extends ConsumerWidget {
  final Booking booking;
  const _BookingCost({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(bookingPaidTotalProvider(booking.id));
    final paidAmount = paymentState.value ?? booking.paidAmount;
    final outstanding = paidAmount >= booking.price
        ? 0
        : booking.price - paidAmount;
    final outstandingLabel = paymentState.isLoading
        ? 'Đang xác minh số dư'
        : paymentState.hasError
        ? 'Chưa xác minh số dư'
        : outstanding == 0
        ? 'Đã thanh toán đủ'
        : 'Còn phải thanh toán';

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
          Text(
            'Chi phí & Thanh toán',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
          const SizedBox(height: 14),
          _CostRow(label: 'Tổng giá gói', amount: booking.price),
          const SizedBox(height: 10),
          _CostRow(
            label: 'Tiền cọc theo booking (30%)',
            amount: booking.depositAmount,
            highlightColor: AppColors.steel,
          ),
          const SizedBox(height: 10),
          _CostRow(
            label: 'Backend ghi nhận đã thanh toán',
            amount: paidAmount,
            highlightColor: AppColors.emerald,
          ),
          const SizedBox(height: 10),
          _CostRow(
            label: outstandingLabel,
            amount: outstanding,
            isStrong: true,
          ),
          if (paymentState.isLoading || paymentState.hasError) ...[
            const SizedBox(height: 6),
            Text(
              paymentState.hasError
                  ? 'Không tải được lịch sử thanh toán. Số dư sẽ được cập nhật sau khi kiểm tra lại.'
                  : 'Đang đối soát lịch sử thanh toán từ Backend.',
              style: AppTypography.bodySm(fontSize: 11, color: AppColors.steel),
            ),
          ],
          if ((booking.coinsRedeemed ?? 0) > 0) ...[
            const SizedBox(height: 10),
            _CostRow(
              label: 'Lens Xu đã dùng',
              amount: -(booking.coinsRedeemed ?? 0),
              highlightColor: AppColors.ember,
            ),
          ],
          const SizedBox(height: 10),
          _CostRow(
            label: 'Lens Xu hoàn lại tích luỹ (+5%)',
            amount: (booking.price * 0.05).round(),
            highlightColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _BookingActions extends ConsumerWidget {
  final Booking booking;
  const _BookingActions({required this.booking});

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
        return _ActionCard(
          icon: LucideIcons.walletCards,
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
        return _ActionCard(
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
        return _ActionCard(
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
        return _ActionCard(
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
        return _ActionCard(
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
        return _ActionCard(
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
        return const _ActionCard(
          icon: LucideIcons.circleX,
          iconColor: AppColors.crimson,
          iconBgColor: Color(0x1AE11D48),
          title: 'Lịch đặt chụp đã huỷ',
          message: 'Lịch chụp này đã được huỷ bỏ theo chính sách hoàn tiền.',
        );

      case BookingStatus.rejected:
        return const _ActionCard(
          icon: LucideIcons.circleX,
          iconColor: AppColors.crimson,
          iconBgColor: Color(0x1AE11D48),
          title: 'Yêu cầu bị từ chối',
          message: 'Backend đã ghi nhận trạng thái từ chối cho booking này.',
        );

      case BookingStatus.expired:
        return const _ActionCard(
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

class _TimelineCard extends StatelessWidget {
  final Booking booking;
  const _TimelineCard({required this.booking});

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiến trình thực hiện',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            BookingStatusPill(
              status: booking.flowStatus,
              paymentDue: booking.paymentDue,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        BookingProgressStepper(booking: booking),
      ],
    ),
  );
}

class _EscrowNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.fog,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.shieldCheck, size: 20, color: AppColors.emerald),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Lens bảo vệ 100% Escrow: Khoản thanh toán chỉ được giải ngân cho nhiếp ảnh gia sau khi bạn xác nhận đã nhận ảnh.',
            style: AppTypography.bodySm(fontSize: 12.5, color: AppColors.steel),
          ),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  const _ActionCard({
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: AppColors.steel),
      const SizedBox(width: 10),
      SizedBox(
        width: 78,
        child: Text(
          label,
          style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: AppTypography.titleMd(fontSize: 13, color: AppColors.obsidian),
        ),
      ),
    ],
  );
}

class _CostRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isStrong;
  final Color? highlightColor;

  const _CostRow({
    required this.label,
    required this.amount,
    this.isStrong = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.bodySm(
            fontSize: 13,
            color: isStrong ? AppColors.obsidian : AppColors.steel,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        AppTypography.formatCurrency(amount),
        style: isStrong
            ? AppTypography.priceDisplay(
                fontSize: 16,
                color: AppColors.obsidian,
              )
            : AppTypography.numeric(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlightColor ?? AppColors.obsidian,
              ),
      ),
    ],
  );
}

String _dateLabel(String value) {
  final parts = value.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
}

String _initials(String value) => value
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.substring(0, 1))
    .join()
    .toUpperCase();

class _EmbeddedGalleryPanel extends StatelessWidget {
  final Booking booking;
  const _EmbeddedGalleryPanel({required this.booking});

  @override
  Widget build(BuildContext context) {
    final delivered = booking.uploadedProofsCount;
    final previews = booking.deliveryPhotoUrls.take(4).toList();
    final total = booking.packageSnapshot?.photoCount ?? previews.length;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.image,
                    size: 18,
                    color: AppColors.ember,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bộ sưu tập bàn giao',
                    style: AppTypography.titleMd(color: AppColors.obsidian),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: AppColors.pebble.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '$delivered / $total ảnh',
                  style: AppTypography.numeric(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4-preview grid
          if (previews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nhiếp ảnh gia chưa giao ảnh cho lịch này.'),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previews.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: previews[index],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.fog),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.fog,
                      child: const Icon(
                        LucideIcons.image,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/gallery'),
            icon: const Icon(LucideIcons.externalLink, size: 15),
            label: Text(
              'Mở toàn bộ bộ sưu tập & nghiệm thu',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pebble),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}
