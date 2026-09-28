import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/data_providers.dart';
import '../../../domain/models/models.dart';
import '../../../data/mock_database.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    final booking = bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => bookings.first,
    );

    final photographer = MockDatabase.photographers.firstWhere(
      (p) => p.id == booking.photographerId,
      orElse: () => MockDatabase.photographers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Chi tiết lịch đặt',
          style: TextStyle(color: AppColors.obsidian, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGeneralInfo(booking, photographer),
            const SizedBox(height: 24),
            _buildActionArea(context, ref, booking),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo(Booking booking, Photographer photographer) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(photographer.avatar),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.photographerName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.obsidian),
                    ),
                    const SizedBox(height: 4),
                    const Text('Nhiếp ảnh gia', style: TextStyle(color: AppColors.steel, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(LucideIcons.calendar, 'Thời gian', booking.date),
          const SizedBox(height: 16),
          _buildInfoRow(LucideIcons.mapPin, 'Địa điểm', booking.location),
          const SizedBox(height: 16),
          _buildInfoRow(LucideIcons.camera, 'Gói chụp', booking.style),
          const SizedBox(height: 24),
          const Divider(color: AppColors.pebble),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền', style: TextStyle(color: AppColors.steel, fontSize: 16, fontWeight: FontWeight.w500)),
              Text(
                '${_formatCurrency(booking.price)} đ',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.obsidian),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.ash),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.steel, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.obsidian, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionArea(BuildContext context, WidgetRef ref, Booking booking) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Column(
          children: [
            const Text(
              'Đang chờ nhiếp ảnh gia phản hồi.',
              style: TextStyle(color: AppColors.steel, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(asyncBookingsProvider.notifier).updateBookingStatus(booking.id, BookingStatus.cancelled);
                  context.pop();
                },
                child: const Text('Hủy yêu cầu', style: TextStyle(color: AppColors.destructive)),
              ),
            ),
          ],
        );
      case BookingStatus.confirmed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withAlpha(50)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.warning, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yêu cầu đã được chấp nhận! Vui lòng thanh toán 100% để giữ lịch.',
                      style: TextStyle(color: AppColors.obsidian, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Thanh toán ngay',
                  onPressed: () {
                    // Navigate to Mock Payment or just update status for now
                    ref.read(asyncBookingsProvider.notifier).updateBookingStatus(booking.id, BookingStatus.held);
                  },
                ),
              ),
            ],
          ),
        );
      case BookingStatus.held:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đã thanh toán an toàn. Tiền của bạn đang được Ký quỹ (Escrow) cho đến khi bạn nhận được ảnh.',
                      style: TextStyle(color: AppColors.obsidian, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Xem ảnh & Xác nhận hoàn tất',
                  onPressed: () {
                    context.push('/customer_home/bookings/${booking.id}/gallery');
                  },
                ),
              ),
            ],
          ),
        );
      case BookingStatus.released:
        return Column(
          children: [
            const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành. Cảm ơn bạn đã sử dụng dịch vụ!',
              style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case BookingStatus.cancelled:
        return const Center(
          child: Text(
            'Lịch đặt đã bị hủy.',
            style: TextStyle(color: AppColors.destructive, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
