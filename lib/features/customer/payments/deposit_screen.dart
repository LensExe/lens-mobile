import 'package:flutter/material.dart';
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

class DepositScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DepositScreen({super.key, required this.bookingId});
  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  PaymentMethod _method = PaymentMethod.bank;
  bool _isPaying = false;

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
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.ember),
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
          'Đặt cọc giữ lịch',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
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
            step: 3,
            title: 'Thanh toán tiền cọc 30%',
            subtitle: 'Khoản cọc được bảo vệ bởi Lens Escrow và giữ lịch trong 30 phút.',
          ),
          const SizedBox(height: 16),
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
                  'Tóm tắt lịch chụp',
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
                  label: 'Tiền cọc cần nạp (30%)',
                  value: AppTypography.formatCurrency(booking.depositAmount),
                  strong: true,
                  color: AppColors.ember,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
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
            text: 'Thanh toán cọc ${AppTypography.formatCurrency(booking.depositAmount)}',
            height: 52,
            onPressed: () => _pay(booking),
            isLoading: _isPaying,
          ),
        ],
      ),
    );
  }

  Future<void> _pay(Booking booking) async {
    setState(() => _isPaying = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await ref
        .read(customerBookingsControllerProvider.notifier)
        .updateStatus(booking.id, BookingStatus.pending);
    if (!mounted) return;
    setState(() => _isPaying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đặt cọc thành công. Đang chờ nhiếp ảnh gia xác nhận.'),
      ),
    );
    context.go('/customer_home/bookings/${booking.id}');
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
  final _coinsController = TextEditingController(text: '0');
  bool _isPaying = false;
  static const _coinBalance = 120000;

  @override
  void dispose() {
    _coinsController.dispose();
    super.dispose();
  }

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
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.ember),
        ),
      );
    }
    final maxCoins = _coinBalance < booking.remainingAmount
        ? _coinBalance
        : booking.remainingAmount;
    final coins = _useCoins
        ? (int.tryParse(_coinsController.text) ?? 0).clamp(0, maxCoins)
        : 0;
    final cashDue = booking.remainingAmount - coins;

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
          'Thanh toán phần còn lại',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
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
                  AppTypography.formatCurrency(booking.remainingAmount),
                  style: AppTypography.priceDisplay(
                    fontSize: 26,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gói ${booking.packageSnapshot?.name ?? booking.style}',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _SummaryRow(
                  label: 'Thanh toán bằng tiền mặt',
                  value: AppTypography.formatCurrency(cashDue),
                  strong: true,
                  color: AppColors.ember,
                ),
                if (coins > 0)
                  _SummaryRow(
                    label: 'Lens Xu sử dụng',
                    value: '-${AppTypography.formatCurrency(coins)}',
                    color: AppColors.emerald,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                      LucideIcons.gift,
                      size: 18,
                      color: AppColors.ember,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dùng Lens Xu tích luỹ',
                        style: AppTypography.titleMd(color: AppColors.obsidian),
                      ),
                    ),
                    Switch(
                      value: _useCoins,
                      activeTrackColor: AppColors.ember,
                      onChanged: (value) => setState(() => _useCoins = value),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn có ${AppTypography.formatCurrency(_coinBalance)} Lens Xu. 1 Xu = 1 ₫.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                if (_useCoins) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _coinsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          'Số Xu muốn dùng (tối đa ${AppTypography.formatCurrency(maxCoins)})',
                      filled: true,
                      fillColor: AppColors.fog,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.pebble),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Thanh toán ${AppTypography.formatCurrency(cashDue)}',
            height: 52,
            onPressed: () => _pay(booking),
            isLoading: _isPaying,
          ),
        ],
      ),
    );
  }

  Future<void> _pay(Booking booking) async {
    setState(() => _isPaying = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await ref
        .read(customerBookingsControllerProvider.notifier)
        .updateStatus(booking.id, BookingStatus.held);
    if (!mounted) return;
    setState(() => _isPaying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanh toán thành công. Lens đang giữ tiền an toàn.'),
      ),
    );
    context.go('/customer_home/bookings/${booking.id}');
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
      Text(title, style: AppTypography.headlineSm(fontSize: 22, color: AppColors.obsidian)),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: AppTypography.bodySm(color: AppColors.steel),
      ),
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
                  style: AppTypography.bodySm(fontSize: 11.5, color: AppColors.steel),
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
        Text(
          value,
          style: strong
              ? AppTypography.priceDisplay(fontSize: 15, color: color ?? AppColors.obsidian)
              : AppTypography.numeric(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.obsidian,
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
