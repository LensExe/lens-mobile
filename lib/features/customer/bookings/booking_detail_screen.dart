import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import 'controllers/customer_bookings_controller.dart';
import 'models/booking_model.dart';
import 'widgets/booking_progress_stepper.dart';
import 'widgets/booking_status_pill.dart';

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

    return LensPage(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
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
            tooltip: 'Chia sẻ',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép liên kết lịch chụp')),
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
        onRefresh: () => ref
            .read(customerBookingsControllerProvider.notifier)
            .loadBookings(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            12,
            AppTokens.pageHorizontal,
            40,
          ),
          children: [
            _BookingHeading(booking: booking),
            const SizedBox(height: 14),
            _BookingSummary(booking: booking),
            const SizedBox(height: 12),
            _BookingCost(booking: booking),
            const SizedBox(height: 12),
            _BookingActions(booking: booking),
            const SizedBox(height: 12),
            _EscrowNotice(),
            const SizedBox(height: 12),
            _TimelineCard(booking: booking),
          ],
        ),
      ),
    );
  }
}

class _BookingHeading extends StatelessWidget {
  final Booking booking;
  const _BookingHeading({required this.booking});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Buổi chụp #${booking.displayCode}',
                  style: AppTypography.headlineSm(
                    fontSize: 20,
                    color: AppColors.obsidian,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_dateLabel(booking.date)} · Mã đặt: ${booking.id}',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
          ],
        ),
      ),
      BookingStatusPill(status: booking.status),
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
                  child: booking.photographerAvatar != null &&
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
                    border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
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

class _BookingCost extends StatelessWidget {
  final Booking booking;
  const _BookingCost({required this.booking});

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
          Text(
            'Chi phí & Thanh toán',
            style: AppTypography.titleMd(color: AppColors.obsidian),
          ),
          const SizedBox(height: 14),
          _CostRow(label: 'Tổng giá gói', amount: booking.price),
          const SizedBox(height: 10),
          _CostRow(
            label: 'Đã đặt cọc (30%)',
            amount: booking.depositAmount,
            highlightColor: AppColors.emerald,
          ),
          const SizedBox(height: 10),
          _CostRow(
            label: 'Còn lại cần thanh toán',
            amount: booking.remainingAmount,
            isStrong: true,
          ),
          if ((booking.coinsRedeemed ?? 0) > 0) ...[
            const SizedBox(height: 10),
            _CostRow(
              label: 'Lens Xu đã dùng',
              amount: -(booking.coinsRedeemed ?? 0),
              highlightColor: AppColors.ember,
            ),
          ],
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
    Widget content;
    switch (booking.status) {
      case BookingStatus.awaiting_deposit:
        content = _ActionRow(
          icon: LucideIcons.walletCards,
          message: 'Đặt cọc 30% để giữ lịch. Yêu cầu sẽ được gửi tới nhiếp ảnh gia sau khi thanh toán.',
          action: PrimaryButton(
            text: 'Đặt cọc ngay',
            expand: false,
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/deposit'),
          ),
        );
      case BookingStatus.pending:
        content = _ActionRow(
          icon: LucideIcons.clock3,
          message: 'Bạn đã đặt cọc. Đang chờ nhiếp ảnh gia xác nhận; nếu bị từ chối, tiền cọc sẽ hoàn lại.',
          action: OutlinedButton(
            onPressed: () => _cancel(context, ref),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pebble),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Huỷ yêu cầu',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
          ),
        );
      case BookingStatus.confirmed:
        content = _ActionRow(
          icon: LucideIcons.creditCard,
          message: 'Nhiếp ảnh gia đã xác nhận lịch chụp. Bạn có thể thanh toán phần còn lại.',
          action: PrimaryButton(
            text: 'Thanh toán ${_money(booking.remainingAmount)}',
            expand: false,
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/pay'),
          ),
        );
      case BookingStatus.held:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ActionRow(
              icon: LucideIcons.shieldCheck,
              message: 'Lens đang giữ tiền an toàn qua Escrow. Vui lòng mở bộ sưu tập và xác nhận nghiệm thu sau khi nhận đủ ảnh.',
              action: null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/customer_home/bookings/${booking.id}/gallery',
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.pebble),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
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
                    text: 'Nghiệm thu ảnh',
                    height: 48,
                    onPressed: () => context.push(
                      '/customer_home/bookings/${booking.id}/gallery',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case BookingStatus.released:
        content = _ActionRow(
          icon: LucideIcons.checkCircle2,
          message: 'Buổi chụp đã hoàn tất và ảnh đã nghiệm thu thành công.',
          action: PrimaryButton(
            text: 'Xem lại bộ ảnh',
            expand: false,
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/gallery'),
          ),
        );
      case BookingStatus.cancelled:
        content = const _ActionRow(
          icon: LucideIcons.circleX,
          message: 'Lịch đặt chụp này đã được huỷ bỏ.',
          action: null,
        );
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Column(
        children: [
          content,
          if (_canCancel(booking.status)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancel(context, ref),
                child: Text(
                  'Huỷ lịch chụp',
                  style: AppTypography.labelMd(color: AppColors.crimson),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canCancel(BookingStatus status) =>
      status == BookingStatus.awaiting_deposit ||
      status == BookingStatus.pending ||
      status == BookingStatus.confirmed ||
      status == BookingStatus.held;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.snow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Huỷ lịch chụp?',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
        content: Text(
          'Bạn có chắc muốn huỷ lịch này không? Chính sách bảo vệ hoàn tiền sẽ được áp dụng theo quy định của Lens.',
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              'Quay lại',
              style: AppTypography.labelMd(color: AppColors.steel),
            ),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            ),
            child: const Text('Xác nhận huỷ'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref
        .read(customerBookingsControllerProvider.notifier)
        .updateStatus(booking.id, BookingStatus.cancelled);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã huỷ lịch chụp')));
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
            BookingStatusPill(status: booking.status, compact: true),
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
            style: AppTypography.bodySm(
              fontSize: 12.5,
              color: AppColors.steel,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _ActionRow({
    required this.icon,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.obsidian),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          message,
          style: AppTypography.bodySm(
            fontSize: 13,
            color: AppColors.steel,
          ),
        ),
      ),
      if (action != null) ...[const SizedBox(width: 10), action!],
    ],
  );
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
      Text(
        label,
        style: AppTypography.bodySm(
          fontSize: 13,
          color: isStrong ? AppColors.obsidian : AppColors.steel,
        ),
      ),
      Text(
        AppTypography.formatCurrency(amount),
        style: isStrong
            ? AppTypography.priceDisplay(fontSize: 16, color: AppColors.obsidian)
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

String _money(int amount) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(amount);
