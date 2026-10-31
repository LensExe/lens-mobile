import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import 'booking_report_sheet.dart';
import 'repositories/booking_report_repository.dart';

class BookingReportEntry extends ConsumerWidget {
  const BookingReportEntry({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(bookingReportProvider(bookingId));
    final latestReport = reportState.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (latestReport != null) ...[
          _ReportStatusCard(report: latestReport),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final created = await showBookingReportSheet(
              context,
              bookingId: bookingId,
            );
            if (created == null || !context.mounted) return;
            ref.invalidate(bookingReportProvider(bookingId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report đã được gửi tới Lens Care.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(LucideIcons.flag, size: 18),
          label: Text(
            latestReport == null ? 'Báo vấn đề' : 'Báo thêm vấn đề',
            style: AppTypography.labelMd(color: AppColors.crimson),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.crimson,
            side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.35)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.pillRadius),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportStatusCard extends StatelessWidget {
  const _ReportStatusCard({required this.report});

  final BookingReportReceipt report;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (report.status) {
      'resolved' => ('Đã xử lý', AppColors.emerald),
      'rejected' => ('Đã đóng', AppColors.steel),
      'escalated' => ('Đang được xem xét thêm', AppColors.warning),
      _ => ('Đang xử lý', AppColors.statusBlue),
    };
    final reportCode = report.id.length > 8
        ? report.id.substring(0, 8).toUpperCase()
        : report.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.messageSquareWarning, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report #$reportCode · $label',
                  style: AppTypography.titleMd(fontSize: 14),
                ),
                if (report.resolution != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    report.resolution!,
                    style: AppTypography.bodySm(color: AppColors.steel),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Trạng thái xử lý sẽ được hiển thị tại đây.',
                    style: AppTypography.bodySm(color: AppColors.steel),
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
