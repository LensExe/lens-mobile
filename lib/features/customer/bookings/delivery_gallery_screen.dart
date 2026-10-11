import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import '../../customer/payments/payment_repository.dart';
import 'controllers/customer_bookings_controller.dart';
import 'models/booking_model.dart';
import 'repositories/booking_gallery_repository.dart';
import 'repositories/delivery_media_repository.dart';

class DeliveryGalleryScreen extends ConsumerStatefulWidget {
  const DeliveryGalleryScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<DeliveryGalleryScreen> createState() =>
      _DeliveryGalleryScreenState();
}

class _DeliveryGalleryScreenState extends ConsumerState<DeliveryGalleryScreen> {
  bool _isConfirming = false;
  final Set<int> _savingPhotos = {};

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(customerBookingsControllerProvider);
    Booking? booking;
    for (final item in bookingsState.allBookings) {
      if (item.id == widget.bookingId) {
        booking = item;
        break;
      }
    }

    if (booking == null) {
      return LensPage(
        appBar: AppBar(title: const Text('Bộ ảnh bàn giao')),
        body: bookingsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            : LensEmptyState(
                icon: LucideIcons.images,
                title: 'Không tìm thấy booking',
                message:
                    bookingsState.errorMessage ?? 'Booking không còn khả dụng.',
                actionLabel: 'Về lịch đặt',
                onAction: () => context.go('/customer_home/bookings'),
              ),
      );
    }

    final galleryState = ref.watch(bookingGalleryProvider(booking.id));
    final paidTotalState = ref.watch(bookingPaidTotalProvider(booking.id));
    final publishedGallery = galleryState.value;
    final paidTotal = paidTotalState.value;
    final isPublished = publishedGallery?.publishedAt?.isNotEmpty == true;
    final canConfirmReceipt =
        booking.status == BookingStatus.shot &&
        isPublished &&
        paidTotal != null &&
        paidTotal >= booking.price;

    return LensPage(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
        ),
        title: Text('Bộ ảnh bàn giao', style: AppTypography.titleMd()),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          12,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          _BookingHeader(booking: booking),
          const SizedBox(height: 14),
          galleryState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              ),
            ),
            error: (error, _) => _MessageCard(
              icon: LucideIcons.lockKeyhole,
              title: 'Gallery chưa thể xem',
              message:
                  'Backend chưa cho phép truy cập gallery này hoặc gallery chưa được publish. Chi tiết: $error',
            ),
            data: (gallery) => gallery.items.isEmpty
                ? _MessageCard(
                    icon: LucideIcons.images,
                    title: 'Gallery chưa có ảnh',
                    message: 'Backend chưa trả về ảnh được bàn giao cho booking này.',
                  )
                : _GalleryGrid(
                    items: gallery.items,
                    saving: _savingPhotos,
                    onDownload: _savePhoto,
                  ),
          ),
          if (booking.status == BookingStatus.shot && isPublished) ...[
            const SizedBox(height: 14),
            if (paidTotalState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (paidTotalState.hasError)
              _MessageCard(
                icon: LucideIcons.circleAlert,
                title: 'Chưa xác minh khoản thanh toán',
                message: 'Ứng dụng không thể kiểm tra lịch sử thanh toán từ Backend nên chưa bật xác nhận nhận ảnh.',
              )
            else if (paidTotal != null && paidTotal < booking.price)
              _MessageCard(
                icon: LucideIcons.creditCard,
                title: 'Booking chưa được thanh toán đủ',
                message:
                    'Backend ghi nhận ${AppTypography.formatCurrency(paidTotal)} / ${AppTypography.formatCurrency(booking.price)} VND đã thanh toán.',
              )
            else if (canConfirmReceipt)
              PrimaryButton(
                text: 'Xác nhận đã nhận ảnh',
                height: 50,
                isLoading: _isConfirming,
                onPressed: _isConfirming ? null : _confirmReceipt,
              ),
          ],
          const SizedBox(height: 12),
          Text(
            'Chỉ ảnh và trạng thái do Backend trả về mới hiển thị. Link tải là link có thời hạn do Backend cấp.',
            style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhoto(String mediaId, int index) async {
    if (_savingPhotos.contains(index)) return;
    setState(() => _savingPhotos.add(index));
    try {
      final url = await ref
          .read(bookingGalleryRepositoryProvider)
          .getDownloadUrl(bookingId: widget.bookingId, mediaId: mediaId);
      await ref
          .read(deliveryMediaRepositoryProvider)
          .saveImage(url: url, name: 'lens-${widget.bookingId}-${index + 1}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu ảnh #${index + 1} vào thiết bị.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend không thể tải ảnh này: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPhotos.remove(index));
    }
  }

  Future<void> _confirmReceipt() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .confirmReceipt(widget.bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend đã xác nhận nhận ảnh.')),
      );
      context.go('/customer_home/bookings');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend chưa thể xác nhận nhận ảnh: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }
}

class _BookingHeader extends StatelessWidget {
  const _BookingHeader({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.pebble),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking.photographerName.isEmpty
              ? 'Nhiếp ảnh gia'
              : booking.photographerName,
          style: AppTypography.titleMd(),
        ),
        const SizedBox(height: 4),
        Text(
          '${booking.date} · ${booking.location}',
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
      ],
    ),
  );
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.items,
    required this.saving,
    required this.onDownload,
  });

  final List<BookingGalleryItem> items;
  final Set<int> saving;
  final Future<void> Function(String mediaId, int index) onDownload;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ảnh đã publish (${items.length})',
        style: AppTypography.headlineSm(),
      ),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _GalleryTile(
            item: item,
            index: index,
            isSaving: saving.contains(index),
            onDownload: () => onDownload(item.mediaId, index),
          );
        },
      ),
    ],
  );
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.item,
    required this.index,
    required this.isSaving,
    required this.onDownload,
  });

  final BookingGalleryItem item;
  final int index;
  final bool isSaving;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          item.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppColors.fog,
            child: Icon(LucideIcons.imageOff, color: AppColors.steel),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Text(
            '#${index + 1}',
            style: AppTypography.labelMd(color: Colors.white),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: IconButton.filledTonal(
            onPressed: isSaving ? null : onDownload,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.download, size: 16),
          ),
        ),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.snow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.pebble),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.steel),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMd(fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                message,
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
