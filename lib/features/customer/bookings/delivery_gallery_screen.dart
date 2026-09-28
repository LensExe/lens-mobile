import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/data_providers.dart';
import '../../../domain/models/models.dart';

class DeliveryGalleryScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const DeliveryGalleryScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DeliveryGalleryScreen> createState() => _DeliveryGalleryScreenState();
}

class _DeliveryGalleryScreenState extends ConsumerState<DeliveryGalleryScreen> {
  bool _isLoading = false;

  // Mock delivered photos
  final List<String> _deliveredPhotos = [
    'https://images.unsplash.com/photo-1511285560929-80b456fea0bc',
    'https://images.unsplash.com/photo-1519741497674-611481863552',
    'https://images.unsplash.com/photo-1542038784456-1ea8e935640e',
    'https://images.unsplash.com/photo-1532712938736-59c79ae04527',
    'https://images.unsplash.com/photo-1606800052052-a08af7148866',
  ];

  Future<void> _confirmReceipt(Booking booking) async {
    setState(() => _isLoading = true);
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    ref.read(asyncBookingsProvider.notifier).updateBookingStatus(booking.id, BookingStatus.released);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã xác nhận · Nhận +${(booking.price * 0.05).toInt()} Lens Xu hoàn lại',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final booking = bookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => bookings.first,
    );

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.snow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.obsidian),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Ảnh buổi chụp ${booking.style}',
          style: const TextStyle(color: AppColors.obsidian, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          if (booking.status == BookingStatus.held)
            _buildConfirmReceiptBox(booking),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _deliveredPhotos.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _deliveredPhotos[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmReceiptBox(Booking booking) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fog,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pebble),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.info, color: AppColors.steel, size: 20),
              SizedBox(width: 8),
              Text(
                'Xác nhận nhận ảnh',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.obsidian),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sau khi xác nhận, sàn sẽ giải ngân ${_formatCurrency(booking.price)} đ cho nhiếp ảnh gia và hoàn Lens Xu cho bạn.',
            style: const TextStyle(color: AppColors.steel, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.obsidian))
                : PrimaryButton(
                    text: 'Xác nhận đã nhận ảnh',
                    onPressed: () => _confirmReceipt(booking),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
