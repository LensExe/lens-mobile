import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bookings/models/booking_model.dart';

class TodoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Color color;
  final VoidCallback? onTap;

  const TodoItem({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fog,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMd(
                      fontSize: 13,
                      color: AppColors.obsidian,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: AppTypography.bodySm(
                      fontSize: 11,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.steel,
              ),
          ],
        ),
      ),
    );
  }
}

class OverviewTodoSection extends StatelessWidget {
  final List<Booking> needsPayment;
  final List<Booking> pending;
  final int unread;

  const OverviewTodoSection({
    super.key,
    required this.needsPayment,
    required this.pending,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (needsPayment.isNotEmpty) {
      final booking = needsPayment.first;
      items.add(
        TodoItem(
          icon: LucideIcons.creditCard,
          title: booking.flowStatus == BookingStatus.awaiting_deposit
              ? 'Thanh toán tiền cọc'
              : 'Thanh toán phần còn lại',
          hint: 'Hoàn tất để giữ lịch chụp của bạn.',
          color: AppColors.ember,
          onTap: () => context.push(
            '/customer_home/bookings/${booking.id}/${booking.flowStatus == BookingStatus.awaiting_deposit ? 'deposit' : 'pay'}',
          ),
        ),
      );
    }
    if (pending.isNotEmpty) {
      items.add(
        TodoItem(
          icon: LucideIcons.clock4,
          title: 'Chờ nhiếp ảnh gia xác nhận',
          hint: '${pending.first.photographerName} đang xem yêu cầu của bạn.',
          color: AppColors.lagoon,
          onTap: () =>
              context.push('/customer_home/bookings/${pending.first.id}'),
        ),
      );
    }
    if (unread > 0) {
      items.add(
        TodoItem(
          icon: LucideIcons.messageSquare,
          title: 'Bạn có tin nhắn mới',
          hint: '$unread tin nhắn chưa đọc từ nhiếp ảnh gia.',
          color: AppColors.obsidian,
          onTap: () => context.go('/customer_home/messages'),
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const TodoItem(
          icon: LucideIcons.checkCircle2,
          title: 'Mọi việc đã sẵn sàng',
          hint: 'Hiện tại bạn không có khoản nào cần xử lý.',
          color: AppColors.emerald,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        28,
        AppTokens.pageHorizontal,
        0,
      ),
      child: Container(
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
                  LucideIcons.sparkles,
                  size: 16,
                  color: AppColors.ember,
                ),
                const SizedBox(width: 8),
                Text(
                  'Việc cần làm',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: item,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

