import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/customer_bookings_controller.dart';
import '../models/booking_model.dart';
import '../repositories/customer_booking_repository_provider.dart';

class CancelBookingDialog extends ConsumerStatefulWidget {
  const CancelBookingDialog({super.key, required this.booking});

  final Booking booking;

  static Future<bool?> show(BuildContext context, Booking booking) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CancelBookingDialog(booking: booking),
      );

  @override
  ConsumerState<CancelBookingDialog> createState() =>
      _CancelBookingDialogState();
}

class _CancelBookingDialogState extends ConsumerState<CancelBookingDialog> {
  final _reasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancellationPreview = ref.watch(
      bookingCancellationPreviewProvider(widget.booking.id),
    );
    return AlertDialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            color: AppColors.crimson,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hủy yêu cầu đặt lịch?',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kiểm tra ước tính khoản hoàn từ Backend trước khi gửi yêu cầu hủy.',
            style: AppTypography.bodySm(color: AppColors.steel),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pebble.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: cancellationPreview.when(
              loading: () => Text(
                'Đang tính số tiền đã thanh toán còn có thể yêu cầu hoàn…',
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
              error: (error, stackTrace) => Text(
                'Chưa tải được số tiền hoàn dự kiến. Backend sẽ tính khoản hoàn theo chính sách khi xử lý yêu cầu hủy.',
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
              data: (preview) => Text(
                'Số tiền đã thanh toán còn có thể yêu cầu hoàn: '
                '${NumberFormat.decimalPattern('vi_VN').format(preview.refundableAmountVnd)} ₫. '
                '${preview.refundRequiresAdminReview ? 'Yêu cầu hoàn tiền cần quản trị viên xem xét.' : 'Quyết định hoàn tiền sẽ theo Backend.'}',
                style: AppTypography.bodySm(color: AppColors.obsidian),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 10000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Lý do hủy',
              hintText: 'Nhập lý do để gửi đến Backend',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
                  'Giữ lịch',
                  style: AppTypography.labelMd(color: AppColors.obsidian),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed:
                    _isProcessing || _reasonController.text.trim().isEmpty
                    ? null
                    : _confirmCancel,
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
                    : const Text('Gửi yêu cầu'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmCancel() async {
    if (_isProcessing || _reasonController.text.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .cancelBooking(widget.booking.id, _reasonController.text.trim());
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend không thể hủy booking: $error')),
      );
      return;
    }

    if (mounted) Navigator.of(context).pop(true);
  }
}
