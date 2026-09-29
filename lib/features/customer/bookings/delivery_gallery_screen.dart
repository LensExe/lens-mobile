import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import 'controllers/customer_bookings_controller.dart';
import 'models/booking_model.dart';

class DeliveryGalleryScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DeliveryGalleryScreen({super.key, required this.bookingId});
  @override
  ConsumerState<DeliveryGalleryScreen> createState() =>
      _DeliveryGalleryScreenState();
}

class _DeliveryGalleryScreenState extends ConsumerState<DeliveryGalleryScreen> {
  static const _deliveredPhotos = [
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1532712938736-59c79ae04527?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1606800052052-a08af7148866?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=900&q=80',
  ];
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerBookingsControllerProvider);
    final matches = state.allBookings
        .where((item) => item.id == widget.bookingId)
        .toList();
    final booking = matches.isEmpty ? null : matches.first;
    if (booking == null) {
      return LensPage(
        appBar: AppBar(title: const Text('Bộ ảnh')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.ember),
        ),
      );
    }
    final required =
        booking.packageSnapshot?.photoCount ?? _deliveredPhotos.length;
    final deliveredCount = booking.uploadedProofsCount > 0
        ? booking.uploadedProofsCount
        : _deliveredPhotos.length;
    final complete = deliveredCount >= required;
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: Text('Ảnh buổi chụp · ${booking.style}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          32,
        ),
        children: [
          if (booking.status == BookingStatus.held)
            LensSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.info, size: 18, color: AppColors.steel),
                      SizedBox(width: 8),
                      Text(
                        'Xác nhận nhận ảnh',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sàn chỉ giải ngân sau khi bạn kiểm tra và xác nhận đã nhận đủ ảnh theo gói.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Xác nhận đã nhận ảnh',
                    onPressed: complete ? () => _confirm(booking) : () {},
                    isLoading: _isConfirming,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$deliveredCount ảnh đã giao',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Gói yêu cầu $required ảnh',
                style: const TextStyle(color: AppColors.steel, fontSize: 12),
              ),
            ],
          ),
          if (!complete && booking.status == BookingStatus.held) ...[
            const SizedBox(height: 7),
            Text(
              'Bạn có thể xác nhận khi nhiếp ảnh gia giao đủ ảnh theo gói.',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deliveredPhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) =>
                _PhotoTile(url: _deliveredPhotos[index], index: index),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(Booking booking) async {
    setState(() => _isConfirming = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    await ref
        .read(customerBookingsControllerProvider.notifier)
        .updateStatus(booking.id, BookingStatus.released);
    if (!mounted) return;
    setState(() => _isConfirming = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xác nhận nhận ảnh. Tiền đã được giải ngân.'),
      ),
    );
    context.pop();
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final int index;
  const _PhotoTile({required this.url, required this.index});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'Không thể tải ảnh',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.fog,
          child: const Icon(LucideIcons.imageOff, color: AppColors.steel),
        ),
      ),
    ),
  );
}
