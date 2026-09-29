import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
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
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Đặt cọc giữ lịch'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          32,
        ),
        children: [
          _CheckoutHeader(
            step: 3,
            title: 'Đặt cọc',
            subtitle: 'Thanh toán an toàn để gửi yêu cầu tới nhiếp ảnh gia.',
          ),
          const SizedBox(height: 16),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt lịch chụp',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
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
                const Divider(height: 22),
                _SummaryRow(
                  label: 'Giá gói',
                  value: format.format(booking.price),
                ),
                _SummaryRow(
                  label: 'Đặt cọc (30%)',
                  value: format.format(booking.depositAmount),
                  strong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F2),
              borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  size: 18,
                  color: AppColors.lagoon,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Khoản cọc được hoàn lại nếu nhiếp ảnh gia từ chối yêu cầu. Sau khi thanh toán, Lens giữ chỗ trong 30 phút.',
                    style: TextStyle(
                      color: AppColors.lagoon,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Thanh toán cọc ${format.format(booking.depositAmount)}',
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
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final maxCoins = _coinBalance < booking.remainingAmount
        ? _coinBalance
        : booking.remainingAmount;
    final coins = _useCoins
        ? (int.tryParse(_coinsController.text) ?? 0).clamp(0, maxCoins)
        : 0;
    final cashDue = booking.remainingAmount - coins;
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Thanh toán phần còn lại'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          32,
        ),
        children: [
          _CheckoutHeader(
            step: 4,
            title: 'Thanh toán',
            subtitle: 'Hoàn tất thanh toán để Lens giữ tiền an toàn tới khi giao ảnh.',
          ),
          const SizedBox(height: 16),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số tiền cần thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  format.format(booking.remainingAmount),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gói ${booking.packageSnapshot?.name ?? booking.style}',
                  style: const TextStyle(color: AppColors.steel, fontSize: 12),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Thanh toán bằng tiền mặt',
                  value: format.format(cashDue),
                  strong: true,
                ),
                if (coins > 0)
                  _SummaryRow(
                    label: 'Lens Xu sử dụng',
                    value: '-${format.format(coins)}',
                    color: AppColors.lagoon,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.gift,
                      size: 17,
                      color: AppColors.lagoon,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Dùng Lens Xu',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Switch(
                      value: _useCoins,
                      activeThumbColor: AppColors.lagoon,
                      onChanged: (value) => setState(() => _useCoins = value),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Bạn có ${format.format(_coinBalance)} Lens Xu. 1 Xu = 1 ₫.',
                  style: const TextStyle(color: AppColors.steel, fontSize: 12),
                ),
                if (_useCoins) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _coinsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          'Số Xu muốn dùng (tối đa ${format.format(maxCoins)})',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Thanh toán ${format.format(cashDue)}',
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
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.steel, fontSize: 13),
      ),
      const SizedBox(height: 14),
      Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
              decoration: BoxDecoration(
                color: index < step ? AppColors.ember : AppColors.pebble,
                borderRadius: BorderRadius.circular(999),
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
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: selected ? AppColors.mist : AppColors.snow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.obsidian : AppColors.pebble,
        ),
      ),
      child: Row(
        children: [
          Icon(
            method == PaymentMethod.bank
                ? LucideIcons.landmark
                : method == PaymentMethod.card
                ? LucideIcons.creditCard
                : LucideIcons.walletCards,
            size: 18,
            color: selected ? AppColors.obsidian : AppColors.steel,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  method.hint,
                  style: const TextStyle(fontSize: 11, color: AppColors.steel),
                ),
              ],
            ),
          ),
          Icon(
            selected ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 19,
            color: selected ? AppColors.obsidian : AppColors.pebble,
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
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.steel, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.ink,
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
