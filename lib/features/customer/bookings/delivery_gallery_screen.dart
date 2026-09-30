import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
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
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bộ ảnh nghiệm thu',
              style: AppTypography.titleMd(color: AppColors.obsidian),
            ),
            Text(
              booking.style,
              style: AppTypography.bodySm(fontSize: 11, color: AppColors.steel),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTokens.pageHorizontal),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
            ),
            child: Text(
              '$deliveredCount / $required ảnh',
              style: AppTypography.numeric(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.obsidian,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          12,
          AppTokens.pageHorizontal,
          48,
        ),
        children: [
          if (booking.status == BookingStatus.held)
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 16),
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
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 18,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nghiệm thu & Giải ngân Escrow',
                        style: AppTypography.titleMd(color: AppColors.obsidian),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Số tiền sẽ chỉ được giải ngân cho nhiếp ảnh gia sau khi bạn kiểm tra và xác nhận hài lòng với toàn bộ ảnh chụp.',
                    style: AppTypography.bodySm(color: AppColors.steel),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Xác nhận đã nhận đủ ảnh',
                    height: 50,
                    onPressed: complete ? () => _confirm(booking) : () {},
                    isLoading: _isConfirming,
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ảnh đã được bàn giao',
                style: AppTypography.headlineSm(fontSize: 16, color: AppColors.obsidian),
              ),
              Text(
                'Nhấn vào ảnh để xem nét',
                style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
              ),
            ],
          ),
          if (!complete && booking.status == BookingStatus.held) ...[
            const SizedBox(height: 6),
            Text(
              'Nhiếp ảnh gia đang tải thêm ảnh cho buổi chụp của bạn.',
              style: AppTypography.bodySm(fontSize: 12, color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deliveredPhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
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
        content: Text('Đã xác nhận nhận ảnh. Tiền đã được giải ngân an toàn.'),
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
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Không thể tải ảnh chất lượng cao',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 48,
              right: 20,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(9999),
                child: GlassContainer.floatingControl(
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.fog,
                child: const Icon(LucideIcons.imageOff, color: AppColors.steel),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: GlassContainer.mediaBadge(
              child: Text(
                '#${index + 1}',
                style: AppTypography.numeric(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
