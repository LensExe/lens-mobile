import 'dart:async';
import 'dart:math';

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
import '../../../providers/data_providers.dart';
import '../bookings/controllers/customer_bookings_controller.dart';
import '../bookings/models/booking_model.dart';
import 'payment_method.dart';
import 'widgets/checkout_result_dialog.dart';

class DepositScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DepositScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  PaymentMethod _method = PaymentMethod.bank;
  bool _isPaying = false;
  bool _expiryRefreshed = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final bookings = ref.read(customerBookingsControllerProvider).allBookings;
      final matches = bookings.where((item) => item.id == widget.bookingId);
      if (!_expiryRefreshed &&
          matches.isNotEmpty &&
          matches.first.status == BookingStatus.awaiting_deposit &&
          _remainingSeconds(matches.first) == 0) {
        _expiryRefreshed = true;
        ref.read(customerBookingsControllerProvider.notifier).loadBookings();
      }
      setState(() {});
    });
  }

  int _remainingSeconds(Booking booking) {
    final deadline = DateTime.tryParse(booking.depositDeadline ?? '');
    if (deadline == null) return 30 * 60;
    return max(0, deadline.difference(DateTime.now()).inSeconds);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingsControllerProvider);
    final booking =
        state.allBookings.where((item) => item.id == widget.bookingId).isEmpty
        ? null
        : state.allBookings.firstWhere((item) => item.id == widget.bookingId);

    if (booking == null) {
      return LensPage(
        appBar: AppBar(title: const Text('Đặt cọc')),
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            : LensEmptyState(
                icon: LucideIcons.calendarX2,
                title: 'Không tìm thấy lịch đặt',
                message: state.errorMessage ?? 'Lịch đặt không còn khả dụng.',
                actionLabel: 'Về lịch đặt',
                onAction: () => context.go('/customer_home/bookings'),
              ),
      );
    }

    final secondsRemaining = _remainingSeconds(booking);
    if (booking.status == BookingStatus.cancelled || secondsRemaining <= 0) {
      return LensPage(
        appBar: _buildAppBar(context, 'Hết hạn giữ chỗ'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.ember.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clockAlert,
                    color: AppColors.ember,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Lịch đặt đã hết hạn giữ chỗ',
                  style: AppTypography.headlineSm(
                    fontSize: 18,
                    color: AppColors.obsidian,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Khung giờ này đã được giải phóng do quá thời hạn 30 phút giữ chỗ. Bạn có thể chọn lại lịch hoặc liên hệ nhiếp ảnh gia.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Đặt lại lịch chụp',
                  height: 48,
                  onPressed: () => context.push(
                    '/customer_home/photographer/${booking.photographerId}/book',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/customer_home/bookings'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.pebble),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: Text(
                    'Về danh sách lịch đặt',
                    style: AppTypography.labelMd(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State check 2: Đã cọc rồi (status != awaiting_deposit)
    if (booking.status != BookingStatus.awaiting_deposit) {
      return LensPage(
        appBar: _buildAppBar(context, 'Đặt cọc giữ lịch'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle2,
                    color: AppColors.emerald,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Lịch đặt này đã được đặt cọc',
                  style: AppTypography.headlineSm(
                    fontSize: 18,
                    color: AppColors.obsidian,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Khoản cọc 30% đã được ghi nhận. Bạn có thể theo dõi tiến độ duyệt lịch của nhiếp ảnh gia.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Xem chi tiết lịch đặt',
                  height: 48,
                  onPressed: () =>
                      context.go('/customer_home/bookings/${booking.id}'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LensPage(
      appBar: _buildAppBar(context, 'Đặt cọc giữ lịch'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          // Hold Countdown Banner
          _HoldCountdownBanner(secondsRemaining: secondsRemaining),
          const SizedBox(height: 14),

          const _CheckoutHeader(
            step: 3,
            title: 'Thanh toán tiền cọc 30%',
            subtitle: 'Khoản cọc được bảo vệ bởi Lens Escrow và giữ lịch trong 30 phút.',
          ),
          const SizedBox(height: 16),

          // Cost Summary
          Container(
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
                  'Tóm tắt chi phí',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 14),
                _SummaryRow(
                  label: 'Nhiếp ảnh gia',
                  value: booking.photographerName,
                ),
                _SummaryRow(
                  label: 'Ngày chụp',
                  value: _dateLabel(booking.date),
                ),
                _SummaryRow(
                  label: 'Gói chụp',
                  value: booking.packageSnapshot?.name ?? booking.style,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _SummaryRow(
                  label: 'Tổng giá gói',
                  value: AppTypography.formatCurrency(booking.price),
                ),
                _SummaryRow(
                  label: 'Tiền cọc cần nạp ngay (30%)',
                  value: AppTypography.formatCurrency(booking.depositAmount),
                  strong: true,
                  color: AppColors.ember,
                ),
                _SummaryRow(
                  label: 'Còn lại thanh toán sau (70%)',
                  value: AppTypography.formatCurrency(booking.remainingAmount),
                  color: AppColors.steel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Payment Methods
          Container(
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
                  'Phương thức thanh toán',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 12),
                ...PaymentMethod.values.map(
                  (method) => _PaymentOption(
                    method: method,
                    selected: _method == method,
                    onTap: () => setState(() => _method = method),
                  ),
                ),
                if (_method == PaymentMethod.bank) ...[
                  const SizedBox(height: 12),
                  _VietQRTransferBox(
                    bookingId: booking.id,
                    amount: booking.depositAmount,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Escrow protection guarantee
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.pebble.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 20,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Khoản cọc được hoàn 100% tự động nếu nhiếp ảnh gia từ chối hoặc bận lịch. Hệ thống giữ chỗ ngay sau khi nạp.',
                    style: AppTypography.bodySm(
                      fontSize: 12.5,
                      color: AppColors.steel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            text:
                'Xác nhận đặt cọc ${AppTypography.formatCurrency(booking.depositAmount)}',
            height: 52,
            onPressed: () => _pay(booking),
            isLoading: _isPaying,
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/customer_home/bookings/${widget.bookingId}');
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: InkWell(
            onTap: () => _handleBack(context),
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
        title,
        style: AppTypography.titleMd(color: AppColors.obsidian),
      ),
    );
  }

  Future<void> _pay(Booking booking) async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .updateStatus(booking.id, BookingStatus.pending);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt cọc thất bại. Vui lòng thử lại: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPaying = false);

    CheckoutResultDialog.show(
      context,
      title: 'Đặt cọc thành công!',
      message: 'Yêu cầu lịch chụp đã được gửi tới nhiếp ảnh gia. Vui lòng theo dõi phản hồi trong vòng 24 giờ.',
      bookingId: booking.id,
      photographerId: booking.photographerId,
      photographerName: booking.photographerName,
      isDeposit: true,
    );
  }
}

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.bank;
  bool _useCoins = false;
  double _sliderCoins = 0;
  bool _isPaying = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingsControllerProvider);
    final matches = state.allBookings
        .where((item) => item.id == widget.bookingId)
        .toList();
    final booking = matches.isEmpty ? null : matches.first;

    if (booking == null) {
      return LensPage(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            : LensEmptyState(
                icon: LucideIcons.calendarX2,
                title: 'Không tìm thấy lịch đặt',
                message: state.errorMessage ?? 'Lịch đặt không còn khả dụng.',
                actionLabel: 'Về lịch đặt',
                onAction: () => context.go('/customer_home/bookings'),
              ),
      );
    }

    // State check: Chỉ thanh toán đợt 2 khi status == confirmed
    if (booking.status != BookingStatus.confirmed) {
      final isAlreadyPaid =
          booking.status == BookingStatus.held ||
          booking.status == BookingStatus.released;
      return LensPage(
        appBar: _buildAppBar(context, 'Thanh toán hoàn tất'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: (isAlreadyPaid ? AppColors.emerald : AppColors.ember)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAlreadyPaid ? LucideIcons.checkCheck : LucideIcons.info,
                    color: isAlreadyPaid ? AppColors.emerald : AppColors.ember,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAlreadyPaid
                      ? 'Lịch đặt đã được thanh toán đầy đủ 100%'
                      : 'Chưa thể thanh toán đợt 2',
                  style: AppTypography.headlineSm(
                    fontSize: 18,
                    color: AppColors.obsidian,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isAlreadyPaid
                      ? 'Sàn Lens đang giữ tiền an toàn trong Escrow. Buổi chụp đã sẵn sàng diễn ra.'
                      : 'Nhiếp ảnh gia cần chấp nhận đơn trước khi bạn thanh toán 70% còn lại.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Xem chi tiết lịch đặt',
                  height: 48,
                  onPressed: () =>
                      context.go('/customer_home/bookings/${booking.id}'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Read real wallet data
    final wallet = ref.watch(customerWalletProvider).value;
    final availableCoins = wallet?.coinBalance ?? 0;

    // Quy định: Tối đa 20% giá trị gói
    final maxByPercent = (booking.price * 0.20).round();
    final maxRedeemable = min(
      min(availableCoins, maxByPercent),
      booking.remainingAmount,
    );

    final coinsUsed = _useCoins
        ? _sliderCoins.round().clamp(0, maxRedeemable)
        : 0;
    final cashDue = max(0, booking.remainingAmount - coinsUsed);

    return LensPage(
      appBar: _buildAppBar(context, 'Thanh toán 70% còn lại'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          const _CheckoutHeader(
            step: 4,
            title: 'Thanh toán hoàn tất',
            subtitle: 'Hoàn tất thanh toán để Lens giữ tiền an toàn tới khi nghiệm thu ảnh.',
          ),
          const SizedBox(height: 16),

          // Total & Due Summary
          Container(
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
                  'Số tiền cần thanh toán',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTypography.formatCurrency(cashDue),
                  style: AppTypography.priceDisplay(
                    fontSize: 26,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gói ${booking.packageSnapshot?.name ?? booking.style} · Đã cọc 30%',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _SummaryRow(
                  label: 'Tổng giá gói',
                  value: AppTypography.formatCurrency(booking.price),
                ),
                _SummaryRow(
                  label: 'Đã đặt cọc (30%)',
                  value: AppTypography.formatCurrency(booking.depositAmount),
                  color: AppColors.steel,
                ),
                _SummaryRow(
                  label: 'Phần còn lại (70%)',
                  value: AppTypography.formatCurrency(booking.remainingAmount),
                ),
                if (coinsUsed > 0)
                  _SummaryRow(
                    label: 'Lens Xu áp dụng',
                    value: '-${AppTypography.formatCurrency(coinsUsed)}',
                    color: AppColors.emerald,
                    strong: true,
                  ),
                _SummaryRow(
                  label: 'Thực trả tiền mặt',
                  value: AppTypography.formatCurrency(cashDue),
                  strong: true,
                  color: AppColors.ember,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lens Xu Redemption Box with Slider
          Container(
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
                    const Icon(
                      LucideIcons.coins,
                      size: 20,
                      color: AppColors.ember,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dùng Lens Xu để trừ tiền',
                        style: AppTypography.titleMd(color: AppColors.obsidian),
                      ),
                    ),
                    Switch(
                      value: _useCoins,
                      activeTrackColor: AppColors.ember,
                      onChanged: maxRedeemable > 0
                          ? (value) {
                              setState(() {
                                _useCoins = value;
                                if (value && _sliderCoins == 0) {
                                  _sliderCoins = maxRedeemable.toDouble();
                                }
                              });
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Số dư: ${AppTypography.formatCurrency(availableCoins)} Xu (1 Xu = 1 ₫). Tối đa áp dụng 20% gói (${AppTypography.formatCurrency(maxByPercent)} Xu).',
                  style: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 12,
                  ),
                ),
                if (_useCoins && maxRedeemable > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fog,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số Xu muốn tiêu:',
                              style: AppTypography.labelMd(
                                color: AppColors.obsidian,
                              ),
                            ),
                            Text(
                              '-${AppTypography.formatCurrency(coinsUsed)}',
                              style: AppTypography.numeric(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _sliderCoins.clamp(
                            0,
                            maxRedeemable.toDouble(),
                          ),
                          min: 0,
                          max: maxRedeemable.toDouble(),
                          divisions: max(1, (maxRedeemable / 10000).ceil()),
                          activeColor: AppColors.ember,
                          inactiveColor: AppColors.pebble,
                          onChanged: (val) {
                            setState(() => _sliderCoins = val);
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0 Xu',
                              style: AppTypography.bodySm(
                                fontSize: 11,
                                color: AppColors.steel,
                              ),
                            ),
                            Text(
                              'Tối đa: ${AppTypography.formatCurrency(maxRedeemable)} Xu',
                              style: AppTypography.bodySm(
                                fontSize: 11,
                                color: AppColors.steel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Payment Methods
          Container(
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
                  'Phương thức thanh toán',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 12),
                ...PaymentMethod.values.map(
                  (method) => _PaymentOption(
                    method: method,
                    selected: _method == method,
                    onTap: () => setState(() => _method = method),
                  ),
                ),
                if (_method == PaymentMethod.bank) ...[
                  const SizedBox(height: 12),
                  _VietQRTransferBox(bookingId: booking.id, amount: cashDue),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Escrow Reassurance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.pebble.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 20,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lens Escrow bảo vệ 100% tiền của bạn. Nhiếp ảnh gia chỉ nhận được thanh toán sau khi bạn nghiệm thu hài lòng với bộ ảnh.',
                    style: AppTypography.bodySm(
                      fontSize: 12.5,
                      color: AppColors.steel,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            text: 'Thanh toán ${AppTypography.formatCurrency(cashDue)}',
            height: 52,
            onPressed: () => _pay(booking, coinsUsed),
            isLoading: _isPaying,
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/customer_home/bookings/${widget.bookingId}');
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: InkWell(
            onTap: () => _handleBack(context),
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
        title,
        style: AppTypography.titleMd(color: AppColors.obsidian),
      ),
    );
  }

  Future<void> _pay(Booking booking, int coinsUsed) async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      final balance = ref.read(customerWalletProvider).value?.coinBalance ?? 0;
      if (coinsUsed > balance) throw StateError('Số dư Lens Xu không đủ.');
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .payRemaining(booking.id, coinsUsed);
      if (coinsUsed > 0) {
        await ref
            .read(customerWalletProvider.notifier)
            .redeemCoins(coins: coinsUsed, bookingId: booking.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanh toán thất bại. Vui lòng thử lại: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPaying = false);

    CheckoutResultDialog.show(
      context,
      title: 'Thanh toán thành công!',
      message: 'Sàn Lens đang giữ 100% tiền an toàn trong tài khoản Escrow. Buổi chụp đã sẵn sàng diễn ra!',
      bookingId: booking.id,
      photographerId: booking.photographerId,
      photographerName: booking.photographerName,
      isDeposit: false,
    );
  }
}

class _HoldCountdownBanner extends StatelessWidget {
  final int secondsRemaining;
  const _HoldCountdownBanner({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ember.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.timer, size: 18, color: AppColors.ember),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thời gian giữ chỗ còn lại:',
              style: AppTypography.bodySm(
                fontSize: 12.5,
                color: AppColors.obsidian,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.ember,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeStr,
              style: AppTypography.numeric(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VietQRTransferBox extends StatelessWidget {
  final String bookingId;
  final int amount;

  const _VietQRTransferBox({required this.bookingId, required this.amount});

  @override
  Widget build(BuildContext context) {
    final content = 'LS ${bookingId.replaceAll('-', '').toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fog,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.qrCode, size: 16, color: AppColors.ember),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Thông tin chuyển khoản VietQR',
                  style: AppTypography.labelMd(color: AppColors.obsidian),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CopyableRow(label: 'Ngân hàng', value: 'MB Bank (Quân Đội)'),
          _CopyableRow(
            label: 'Số tài khoản',
            value: '0988123456',
            canCopy: true,
          ),
          _CopyableRow(label: 'Chủ tài khoản', value: 'LENS VIET NAM CORP'),
          _CopyableRow(
            label: 'Số tiền',
            value: AppTypography.formatCurrency(amount),
            color: AppColors.ember,
          ),
          _CopyableRow(
            label: 'Nội dung CK',
            value: content,
            canCopy: true,
            color: AppColors.obsidian,
          ),
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;
  final Color? color;

  const _CopyableRow({
    required this.label,
    required this.value,
    this.canCopy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.numeric(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppColors.obsidian,
                    ),
                  ),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép $label'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        LucideIcons.copy,
                        size: 14,
                        color: AppColors.steel,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  const _CheckoutHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTypography.headlineSm(
          fontSize: 22,
          color: AppColors.obsidian,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: AppTypography.bodySm(color: AppColors.steel)),
      const SizedBox(height: 14),
      Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
              decoration: BoxDecoration(
                color: index < step ? AppColors.ember : AppColors.fog,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.fog : AppColors.snow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.obsidian : AppColors.pebble,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? AppColors.obsidian : AppColors.fog,
              shape: BoxShape.circle,
            ),
            child: Icon(
              method == PaymentMethod.bank
                  ? LucideIcons.landmark
                  : method == PaymentMethod.card
                  ? LucideIcons.creditCard
                  : LucideIcons.walletCards,
              size: 17,
              color: selected ? AppColors.snow : AppColors.steel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label,
                  style: AppTypography.titleMd(
                    fontSize: 13.5,
                    color: AppColors.obsidian,
                  ),
                ),
                Text(
                  method.hint,
                  style: AppTypography.bodySm(
                    fontSize: 11.5,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 19,
            color: selected ? AppColors.ember : AppColors.pebble,
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm(fontSize: 13, color: AppColors.steel),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            textAlign: TextAlign.right,
            style: strong
                ? AppTypography.priceDisplay(
                    fontSize: 15,
                    color: color ?? AppColors.obsidian,
                  )
                : AppTypography.numeric(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.obsidian,
                  ),
          ),
        ),
      ],
    ),
  );
}

String _dateLabel(String value) {
  final parts = value.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
}
