import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
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
        appBar: AppBar(title: const Text('Chi tiết lịch đặt')),
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Chi tiết lịch đặt'),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép liên kết lịch chụp')),
            ),
            icon: const Icon(LucideIcons.share2),
          ),
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
            8,
            AppTokens.pageHorizontal,
            32,
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
            Text(
              'Chi tiết lịch chụp #${booking.displayCode}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              '${_dateLabel(booking.date)} · Mã đặt lịch: ${booking.id}',
              style: const TextStyle(color: AppColors.steel, fontSize: 12),
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
    return LensSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.fog,
                backgroundImage: booking.photographerAvatar == null
                    ? null
                    : NetworkImage(booking.photographerAvatar!),
                child: booking.photographerAvatar == null
                    ? Text(_initials(booking.photographerName))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.photographerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Nhiếp ảnh gia',
                      style: TextStyle(color: AppColors.steel, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _InfoRow(
            icon: LucideIcons.calendarDays,
            label: 'Thời gian',
            value:
                '${_dateLabel(booking.date)}${booking.timeSlot == null ? '' : ' · ${booking.timeSlot}'}',
          ),
          const SizedBox(height: 13),
          _InfoRow(
            icon: LucideIcons.mapPin,
            label: 'Địa điểm',
            value: booking.location,
          ),
          const SizedBox(height: 13),
          _InfoRow(
            icon: LucideIcons.package,
            label: 'Gói chụp',
            value: booking.packageSnapshot?.name ?? booking.style,
          ),
          if (booking.note != null && booking.note!.isNotEmpty) ...[
            const SizedBox(height: 13),
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
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return LensSectionCard(
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chi phí',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 13),
          _CostRow(label: 'Giá gói', amount: booking.price, format: format),
          const SizedBox(height: 8),
          _CostRow(
            label: 'Đã đặt cọc',
            amount: booking.depositAmount,
            format: format,
            strong: true,
          ),
          const SizedBox(height: 8),
          _CostRow(
            label: 'Còn lại',
            amount: booking.remainingAmount,
            format: format,
          ),
          if ((booking.coinsRedeemed ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _CostRow(
              label: 'Lens Xu đã dùng',
              amount: -(booking.coinsRedeemed ?? 0),
              format: format,
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
          message: 'Đặt cọc 30% để giữ lịch. Yêu cầu chỉ được gửi tới nhiếp ảnh gia sau khi thanh toán.',
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
          message: 'Bạn đã đặt cọc. Đang chờ nhiếp ảnh gia xác nhận; nếu bị từ chối, tiền cọc sẽ được hoàn lại.',
          action: OutlinedButton(
            onPressed: () => _cancel(context, ref),
            child: const Text('Huỷ yêu cầu'),
          ),
        );
      case BookingStatus.confirmed:
        content = _ActionRow(
          icon: LucideIcons.creditCard,
          message: 'Nhiếp ảnh gia đã xác nhận. Thanh toán phần còn lại trước buổi chụp.',
          action: PrimaryButton(
            text: 'Thanh toán nốt ${_money(booking.remainingAmount)}',
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
              message: 'Sàn đang giữ tiền an toàn. Sau khi nhận đủ ảnh, hãy mở bộ sưu tập và xác nhận.',
              action: null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/customer_home/bookings/${booking.id}/gallery',
                    ),
                    child: const Text('Mở bộ ảnh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      '/customer_home/bookings/${booking.id}/gallery',
                    ),
                    child: const Text('Xác nhận ảnh'),
                  ),
                ),
              ],
            ),
          ],
        );
      case BookingStatus.released:
        content = _ActionRow(
          icon: LucideIcons.checkCircle2,
          message: 'Buổi chụp đã hoàn thành. Bạn có thể xem lại bộ ảnh hoặc để lại đánh giá.',
          action: OutlinedButton(
            onPressed: () =>
                context.push('/customer_home/bookings/${booking.id}/gallery'),
            child: const Text('Xem bộ ảnh'),
          ),
        );
      case BookingStatus.cancelled:
        content = const _ActionRow(
          icon: LucideIcons.circleX,
          message: 'Lịch đặt này đã được huỷ.',
          action: null,
        );
    }
    return LensSectionCard(
      child: Column(
        children: [
          content,
          if (_canCancel(booking.status)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancel(context, ref),
                child: const Text(
                  'Huỷ lịch',
                  style: TextStyle(color: AppColors.destructive),
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
        title: const Text('Huỷ lịch chụp?'),
        content: const Text(
          'Bạn có chắc muốn huỷ lịch này không? Chính sách hoàn tiền sẽ được áp dụng theo trạng thái lịch.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
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
  Widget build(BuildContext context) => LensSectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tiến trình giao dịch',
              style: TextStyle(fontWeight: FontWeight.w700),
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE6F4F2),
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      border: Border.all(color: AppColors.lagoon.withValues(alpha: .25)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.lagoon),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Lens bảo vệ 100%: tiền chỉ được chuyển cho nhiếp ảnh gia sau khi bạn xác nhận đã nhận ảnh.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lagoon,
              height: 1.45,
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
      Icon(icon, size: 18, color: AppColors.steel),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.steel,
            height: 1.45,
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
      Icon(icon, size: 18, color: AppColors.ash),
      const SizedBox(width: 10),
      SizedBox(
        width: 78,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.steel, fontSize: 12),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _CostRow extends StatelessWidget {
  final String label;
  final int amount;
  final NumberFormat format;
  final bool strong;
  const _CostRow({
    required this.label,
    required this.amount,
    required this.format,
    this.strong = false,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.steel, fontSize: 13)),
      Text(
        format.format(amount),
        style: TextStyle(
          fontSize: 13,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          color: amount < 0 ? AppColors.lagoon : AppColors.ink,
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
