import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/lens_page.dart';
import '../../payments/repositories/payment_repository.dart';
import '../controllers/customer_bookings_controller.dart';
import '../models/booking_model.dart';
import '../widgets/booking_detail_actions.dart';
import '../widgets/booking_detail_cost.dart';
import '../widgets/booking_detail_gallery_panel.dart';
import '../widgets/booking_detail_heading.dart';
import '../widgets/booking_detail_summary.dart';
import '../widgets/booking_detail_timeline.dart';
import '../widgets/booking_report_entry.dart';
import '../widgets/booking_report_panel.dart';

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

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/customer_home/bookings');
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/customer_home/bookings');
      },
      child: LensPage(
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: InkWell(
                onTap: handleBack,
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
              tooltip: 'Tải hoá đơn VAT',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Yêu cầu xuất hoá đơn VAT điện tử đã được gửi tới hệ thống LENS Care.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
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
                  LucideIcons.receipt,
                  size: 16,
                  color: AppColors.obsidian,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Chia sẻ',
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: '/customer_home/bookings/${booking.id}'),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép liên kết lịch chụp'),
                  ),
                );
              },
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
          onRefresh: () async {
            await ref
                .read(customerBookingsControllerProvider.notifier)
                .loadBookings();
            ref.invalidate(bookingPaidTotalProvider(booking.id));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pageHorizontal,
              12,
              AppTokens.pageHorizontal,
              60,
            ),
            children: [
              BookingDetailHeading(booking: booking),
              const SizedBox(height: 14),
              BookingDetailSummary(booking: booking),
              const SizedBox(height: 12),
              BookingDetailCost(booking: booking),
              const SizedBox(height: 12),
              BookingDetailActions(booking: booking),
              if ([
                BookingStatus.inProgress,
                BookingStatus.held,
                BookingStatus.shot,
                BookingStatus.completed,
                BookingStatus.released,
              ].contains(booking.status)) ...[
                const SizedBox(height: 12),
                BookingReportEntry(bookingId: booking.id),
              ],
              const SizedBox(height: 12),
              if (booking.status == BookingStatus.held ||
                  booking.status == BookingStatus.released ||
                  (booking.status == BookingStatus.shot &&
                      booking.galleryPublishedAt != null)) ...[
                BookingDetailGalleryPanel(booking: booking),
                const SizedBox(height: 12),
              ],
              BookingReportPanel(booking: booking),
              const SizedBox(height: 12),
              const BookingDetailEscrowNotice(),
              const SizedBox(height: 12),
              BookingDetailTimeline(booking: booking),
            ],
          ),
        ),
      ),
    );
  }
}
