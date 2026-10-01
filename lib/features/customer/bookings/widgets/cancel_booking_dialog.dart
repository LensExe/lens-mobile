import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/data_providers.dart';
import '../controllers/customer_bookings_controller.dart';
import '../models/booking_model.dart';

class CancelBookingTerms {
  final int refundAmount;
  final int penaltyAmount;
  final int coinsBack;
  final String conditionTitle;
  final String refundBadge;
  final String explanation;
  final bool isFreeCancel;

  const CancelBookingTerms({
    required this.refundAmount,
    required this.penaltyAmount,
    this.coinsBack = 0,
    required this.conditionTitle,
    required this.refundBadge,
    required this.explanation,
    required this.isFreeCancel,
  });

  String get policyLabel => '$conditionTitle · $refundBadge';

  static CancelBookingTerms calculate(Booking booking) {
    if (booking.status == BookingStatus.awaiting_deposit) {
      return const CancelBookingTerms(
        refundAmount: 0,
        penaltyAmount: 0,
        conditionTitle: 'Chưa đặt cọc',
        refundBadge: 'Huỷ miễn phí',
        explanation: 'Lịch chụp chưa phát sinh thanh toán cọc. Huỷ bỏ đơn không mất bất kỳ chi phí nào.',
        isFreeCancel: true,
      );
    }

    if (booking.status == BookingStatus.pending) {
      return CancelBookingTerms(
        refundAmount: booking.depositAmount,
        penaltyAmount: 0,
        conditionTitle: 'Thợ chưa nhận lịch',
        refundBadge: 'Hoàn 100% cọc',
        explanation: 'Nhiếp ảnh gia chưa xác nhận lịch. Toàn bộ tiền cọc 30% sẽ được hoàn trả ngay lập tức vào Ví Lens của bạn.',
        isFreeCancel: true,
      );
    }

    // Status is confirmed or held
    final now = DateTime.now();
    final shootDate = DateTime.tryParse(booking.date) ?? now;
    final today = DateTime(now.year, now.month, now.day);
    final daysRemaining = DateTime(
      shootDate.year,
      shootDate.month,
      shootDate.day,
    ).difference(today).inDays;
    final coinsBack = booking.status == BookingStatus.held
        ? (booking.coinsRedeemed ?? 0)
        : 0;
    final cashPaid = booking.status == BookingStatus.held
        ? booking.price - coinsBack
        : booking.depositAmount;

    if (daysRemaining >= 7) {
      // Free cancel >= 7 days: 100% refund
      return CancelBookingTerms(
        refundAmount: cashPaid,
        penaltyAmount: 0,
        coinsBack: coinsBack,
        conditionTitle: 'Huỷ trước ≥ 7 ngày',
        refundBadge: 'Hoàn 100%',
        explanation:
            'Bạn đang huỷ trước ngày chụp $daysRemaining ngày. Theo chính sách Escrow, bạn được hoàn lại 100% toàn bộ tiền đã nạp vào Ví tiền.',
        isFreeCancel: true,
      );
    } else {
      // Late cancel < 7 days: lose 30% deposit
      final refund = booking.status == BookingStatus.held
          ? cashPaid - booking.depositAmount
          : 0;
      return CancelBookingTerms(
        refundAmount: refund,
        penaltyAmount: booking.depositAmount,
        coinsBack: coinsBack,
        conditionTitle: 'Huỷ muộn < 7 ngày',
        refundBadge: 'Mất cọc 30%',
        explanation:
            'Còn $daysRemaining ngày trước buổi chụp. Tiền cọc 30% (${AppTypography.formatCurrency(booking.depositAmount)}) được chuyển bồi thường cho nhiếp ảnh gia giữ lịch.',
        isFreeCancel: false,
      );
    }
  }
}

class CancelBookingDialog extends ConsumerStatefulWidget {
  final Booking booking;
  const CancelBookingDialog({super.key, required this.booking});

  static Future<bool?> show(BuildContext context, Booking booking) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelBookingDialog(booking: booking),
    );
  }

  @override
  ConsumerState<CancelBookingDialog> createState() =>
      _CancelBookingDialogState();
}

class _CancelBookingDialogState extends ConsumerState<CancelBookingDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final terms = CancelBookingTerms.calculate(widget.booking);

    return AlertDialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.alertTriangle,
              color: AppColors.crimson,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Xác nhận huỷ lịch chụp',
              style: AppTypography.titleMd(
                fontSize: 17,
                color: AppColors.obsidian,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shoot metadata snippet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.pebble.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.camera,
                    size: 14,
                    color: AppColors.steel,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.booking.style} · ${widget.booking.photographerName}',
                      style: AppTypography.labelSm(
                        fontSize: 12.5,
                        color: AppColors.obsidian,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Policy Breakdown Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.pebble.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top policy rule header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            terms.isFreeCancel
                                ? LucideIcons.shieldCheck
                                : LucideIcons.alertCircle,
                            size: 15,
                            color: terms.isFreeCancel
                                ? AppColors.emerald
                                : AppColors.crimson,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Quy tắc hoàn tiền',
                            style: AppTypography.labelSm(
                              color: AppColors.steel,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: terms.isFreeCancel
                              ? AppColors.emerald.withValues(alpha: 0.12)
                              : AppColors.crimson.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          terms.refundBadge,
                          style: AppTypography.numeric(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: terms.isFreeCancel
                                ? AppColors.emerald
                                : AppColors.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Condition pill tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.snow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.pebble.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.calendarCheck,
                          size: 13,
                          color: AppColors.steel,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Điều kiện: ${terms.conditionTitle}',
                            style: AppTypography.labelSm(
                              fontSize: 11.5,
                              color: AppColors.obsidian,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Explanation paragraph
                  Text(
                    terms.explanation,
                    style: AppTypography.bodySm(
                      fontSize: 12,
                      color: AppColors.steel,
                    ).copyWith(height: 1.45),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.pebble),
                  ),

                  // Financial summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Tiền hoàn vào ví Lens:',
                          style: AppTypography.labelSm(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTypography.formatCurrency(terms.refundAmount),
                        style: AppTypography.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                  if (terms.penaltyAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Phí bồi thường thợ (30% cọc):',
                            style: AppTypography.labelSm(
                              color: AppColors.crimson,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-${AppTypography.formatCurrency(terms.penaltyAmount)}',
                          style: AppTypography.numeric(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.crimson,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (terms.coinsBack > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Lens Xu hoàn lại: ${AppTypography.formatCurrency(terms.coinsBack)} Xu',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.pebble),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Giữ lịch chụp',
                  style: AppTypography.labelMd(color: AppColors.obsidian),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _isProcessing ? null : () => _confirmCancel(terms),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.pillRadius),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận huỷ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmCancel(CancelBookingTerms terms) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .updateStatus(widget.booking.id, BookingStatus.cancelled);
      if (terms.refundAmount > 0) {
        await ref
            .read(customerWalletProvider.notifier)
            .addRefund(
              amount: terms.refundAmount,
              bookingId: widget.booking.id,
              photographerName: widget.booking.photographerName,
            );
      }
      if (terms.coinsBack > 0) {
        await ref
            .read(customerWalletProvider.notifier)
            .restoreCoins(coins: terms.coinsBack, bookingId: widget.booking.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể huỷ lịch, vui lòng thử lại: $e')),
      );
      return;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);

    final msg = terms.refundAmount > 0
        ? 'Đã huỷ lịch · hoàn ${AppTypography.formatCurrency(terms.refundAmount)} vào ví'
        : 'Đã huỷ lịch chụp thành công';

    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.obsidian,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
