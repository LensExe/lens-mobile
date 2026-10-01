import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

class CheckoutResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final String bookingId;
  final String photographerId;
  final String photographerName;
  final bool isDeposit;

  const CheckoutResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.bookingId,
    required this.photographerId,
    required this.photographerName,
    required this.isDeposit,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String bookingId,
    required String photographerId,
    required String photographerName,
    required bool isDeposit,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckoutResultDialog(
        title: title,
        message: message,
        bookingId: bookingId,
        photographerId: photographerId,
        photographerName: photographerName,
        isDeposit: isDeposit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCheck,
              color: AppColors.emerald,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm(
              fontSize: 18,
              color: AppColors.obsidian,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(
              color: AppColors.steel,
              fontSize: 13,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),

          // Next steps box
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
                Text(
                  isDeposit ? 'Lộ trình tiếp theo:' : 'Cam kết từ LENS Care:',
                  style: AppTypography.labelSm(
                    color: AppColors.steel,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                _StepRow(
                  number: '1',
                  text: isDeposit
                      ? 'Nhiếp ảnh gia sẽ phản hồi xác nhận lịch trong 24 giờ.'
                      : 'Toàn bộ tiền được bảo vệ an toàn trong tài khoản Escrow.',
                ),
                const SizedBox(height: 6),
                _StepRow(
                  number: '2',
                  text: isDeposit
                      ? 'Sau khi thợ nhận, bạn thanh toán 70% còn lại trước ngày chụp.'
                      : 'Chỉ giải ngân cho thợ sau khi bạn nghiệm thu hài lòng với bộ ảnh.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Action 1: Nhắn tin với thợ
          PrimaryButton(
            text: 'Nhắn tin với $photographerName',
            height: 48,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/customer_home/messages/$photographerId');
            },
          ),
          const SizedBox(height: 10),

          // Action 2: Xem chi tiết lịch đặt
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/customer_home/bookings/$bookingId');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.pebble),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(
              'Xem chi tiết lịch đặt',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
          ),
          const SizedBox(height: 6),

          // Action 3: Về danh sách lịch đặt
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/customer_home/bookings');
            },
            child: Text(
              'Về danh sách lịch đặt',
              style: AppTypography.labelSm(color: AppColors.steel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            color: AppColors.ember,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.numeric(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm(
              fontSize: 12,
              color: AppColors.obsidian,
            ),
          ),
        ),
      ],
    );
  }
}
