import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../payments/repositories/payment_repository.dart';
import '../models/booking_model.dart';

class BookingDetailCostRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isStrong;
  final Color? highlightColor;

  const BookingDetailCostRow({
    super.key,
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

class BookingDetailEscrowNotice extends StatelessWidget {
  const BookingDetailEscrowNotice({super.key});

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

class BookingDetailCost extends ConsumerWidget {
  final Booking booking;
  const BookingDetailCost({super.key, required this.booking});

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
          BookingDetailCostRow(label: 'Tổng giá gói', amount: booking.price),
          const SizedBox(height: 10),
          BookingDetailCostRow(
            label: 'Tiền cọc theo booking (30%)',
            amount: booking.depositAmount,
            highlightColor: AppColors.steel,
          ),
          const SizedBox(height: 10),
          BookingDetailCostRow(
            label: 'Backend ghi nhận đã thanh toán',
            amount: paidAmount,
            highlightColor: AppColors.emerald,
          ),
          const SizedBox(height: 10),
          BookingDetailCostRow(
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
            BookingDetailCostRow(
              label: 'Lens Xu đã dùng',
              amount: -(booking.coinsRedeemed ?? 0),
              highlightColor: AppColors.ember,
            ),
          ],
          const SizedBox(height: 10),
          BookingDetailCostRow(
            label: 'Lens Xu hoàn lại tích luỹ (+5%)',
            amount: (booking.price * 0.05).round(),
            highlightColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}

