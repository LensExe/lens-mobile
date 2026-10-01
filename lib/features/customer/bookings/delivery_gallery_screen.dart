import 'dart:ui';

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
import '../../../providers/data_providers.dart';
import 'controllers/customer_bookings_controller.dart';
import 'models/booking_model.dart';
import 'repositories/delivery_media_repository.dart';

class DeliveryGalleryScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const DeliveryGalleryScreen({super.key, required this.bookingId});

  @override
  ConsumerState<DeliveryGalleryScreen> createState() =>
      _DeliveryGalleryScreenState();
}

class _DeliveryGalleryScreenState extends ConsumerState<DeliveryGalleryScreen> {
  bool _isConfirming = false;
  final Set<int> _savingPhotos = {};

  Future<void> _savePhoto(String url, int index) async {
    if (_savingPhotos.contains(index)) return;
    setState(() => _savingPhotos.add(index));
    try {
      await ref
          .read(deliveryMediaRepositoryProvider)
          .saveImage(url: url, name: 'lens-${widget.bookingId}-${index + 1}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu ảnh #${index + 1} vào thư viện thiết bị.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu ảnh. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _savingPhotos.remove(index));
    }
  }

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
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            : LensEmptyState(
                icon: LucideIcons.images,
                title: 'Không tìm thấy lịch đặt',
                message: state.errorMessage ?? 'Lịch đặt không còn khả dụng.',
                actionLabel: 'Về lịch đặt',
                onAction: () => context.go('/customer_home/bookings'),
              ),
      );
    }

    final required =
        booking.packageSnapshot?.photoCount ?? booking.deliveryPhotoUrls.length;
    final deliveredCount = booking.uploadedProofsCount;
    final complete = required > 0 && deliveredCount >= required;
    final showConfirm = booking.status == BookingStatus.held;
    final isStorageLocked = booking.isStorageLocked;
    final photos = booking.deliveryPhotoUrls.take(deliveredCount).toList();
    final cashbackCoins = (booking.price * 0.05).round();

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/customer_home/bookings/${widget.bookingId}');
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/customer_home/bookings/${widget.bookingId}');
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bộ ảnh bàn giao',
                style: AppTypography.titleMd(color: AppColors.obsidian),
              ),
              Text(
                '${booking.photographerName} · ${booking.style}',
                style: AppTypography.bodySm(
                  fontSize: 11,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: AppTokens.pageHorizontal),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: complete
                    ? AppColors.emerald.withValues(alpha: 0.1)
                    : AppColors.fog,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: complete
                      ? AppColors.emerald.withValues(alpha: 0.3)
                      : AppColors.pebble,
                ),
              ),
              child: Text(
                '$deliveredCount / $required ảnh',
                style: AppTypography.numeric(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: complete ? AppColors.emerald : AppColors.obsidian,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pageHorizontal,
            12,
            AppTokens.pageHorizontal,
            48,
          ),
          children: [
            // Storage locked warning banner
            if (isStorageLocked) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.ember.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 20,
                      color: AppColors.ember,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bộ sưu tập vượt hạn mức gói hiện tại nên tạm bị khoá. Vui lòng liên hệ nhiếp ảnh gia.',
                        style: AppTypography.bodySm(
                          fontSize: 12.5,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Delivery Progress Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.snow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.pebble),
                boxShadow: const [AppTokens.surfaceShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ giao ảnh',
                        style: AppTypography.titleMd(
                          fontSize: 13.5,
                          color: AppColors.obsidian,
                        ),
                      ),
                      Text(
                        '${(deliveredCount / (required > 0 ? required : 1) * 100).toInt()}%',
                        style: AppTypography.numeric(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ember,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: (deliveredCount / (required > 0 ? required : 1))
                          .clamp(0.0, 1.0),
                      backgroundColor: AppColors.fog,
                      color: complete ? AppColors.emerald : AppColors.ember,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complete
                        ? 'Nhiếp ảnh gia đã tải đủ số lượng ảnh theo cam kết của gói.'
                        : 'Nhiếp ảnh gia đang trong quá trình hậu kỳ và tải thêm ảnh.',
                    style: AppTypography.bodySm(
                      fontSize: 11.5,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ),
            ),

            // Escrow Acceptance & Confirm Receipt Banner (showConfirm)
            if (showConfirm)
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nghiệm thu & Giải ngân Escrow',
                                style: AppTypography.titleMd(
                                  color: AppColors.obsidian,
                                ),
                              ),
                              Text(
                                'Nhận ngay +${AppTypography.formatCurrency(cashbackCoins)} Lens Xu',
                                style: AppTypography.labelSm(
                                  color: AppColors.emerald,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Số tiền sẽ chỉ được giải ngân cho nhiếp ảnh gia sau khi bạn kiểm tra và xác nhận hài lòng với toàn bộ ảnh chụp.',
                      style: AppTypography.bodySm(color: AppColors.steel),
                    ),
                    const SizedBox(height: 16),
                    if (!complete) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.fog,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Bạn có thể xác nhận khi nhiếp ảnh gia giao đủ $required ảnh (hiện có $deliveredCount/$required).',
                          style: AppTypography.bodySm(
                            fontSize: 12,
                            color: AppColors.steel,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    PrimaryButton(
                      text: 'Xác nhận đã nhận ảnh',
                      height: 50,
                      onPressed: complete && !isStorageLocked
                          ? () => _confirm(booking, cashbackCoins)
                          : () {},
                      isLoading: _isConfirming,
                    ),
                  ],
                ),
              ),

            // If no photos delivered yet -> Empty state actions
            if (photos.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.pebble),
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.images,
                      size: 48,
                      color: AppColors.steel,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có ảnh nào được tải lên',
                      style: AppTypography.headlineSm(
                        fontSize: 16,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nhiếp ảnh gia đang chọn lọc và chỉnh sửa ảnh cho buổi chụp của bạn.',
                      style: AppTypography.bodySm(color: AppColors.steel),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã gửi thông báo nhắc nhở tới nhiếp ảnh gia ${booking.photographerName}.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.bell, size: 16),
                            label: const Text('Nhắc thợ giao'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.pebble),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAcceptanceRulesSheet(context),
                            icon: const Icon(LucideIcons.fileText, size: 16),
                            label: const Text('Quy định'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.pebble),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bộ sưu tập bàn giao',
                    style: AppTypography.headlineSm(
                      fontSize: 16,
                      color: AppColors.obsidian,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAcceptanceRulesSheet(context),
                    icon: const Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: AppColors.steel,
                    ),
                    label: Text(
                      'Quy định nghiệm thu',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) => _PhotoTile(
                  url: photos[index],
                  index: index,
                  isLocked: isStorageLocked,
                  onDownload: isStorageLocked || _savingPhotos.contains(index)
                      ? null
                      : () => _savePhoto(photos[index], index),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAcceptanceRulesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.emerald,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Quy định nghiệm thu LENS Care',
                  style: AppTypography.titleMd(
                    fontSize: 16,
                    color: AppColors.obsidian,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RuleItem(
              number: '1',
              title: 'Cam kết đủ số lượng ảnh',
              desc: 'Nhiếp ảnh gia phải tải lên đủ số lượng ảnh tối thiểu theo gói đã chọn.',
            ),
            const SizedBox(height: 10),
            _RuleItem(
              number: '2',
              title: 'Chất lượng và độ phân giải gốc',
              desc: 'Ảnh bàn giao phải là ảnh đã qua hậu kỳ, độ phân giải cao sẵn sàng in ấn.',
            ),
            const SizedBox(height: 10),
            _RuleItem(
              number: '3',
              title: 'Tự động hoàn 5% Lens Xu',
              desc: 'Ngay khi bạn bấm xác nhận nhận ảnh, 5% giá trị gói chụp được hoàn lại vào ví Lens Xu của bạn.',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Đã hiểu',
              height: 48,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(Booking booking, int cashbackCoins) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      await ref
          .read(customerBookingsControllerProvider.notifier)
          .updateStatus(booking.id, BookingStatus.released);
      await ref
          .read(customerWalletProvider.notifier)
          .addCashback(coins: cashbackCoins, bookingId: booking.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xác nhận, vui lòng thử lại: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isConfirming = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã xác nhận · nhận +${AppTypography.formatCurrency(cashbackCoins)} hoàn lại',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
    context.go('/customer_home/bookings');
  }
}

class _RuleItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _RuleItem({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.fog,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.numeric(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMd(color: AppColors.obsidian),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySm(
                  fontSize: 12,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final int index;
  final bool isLocked;
  final VoidCallback? onDownload;

  const _PhotoTile({
    required this.url,
    required this.index,
    this.isLocked = false,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: isLocked
        ? null
        : () => showDialog<void>(
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
                        child: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (onDownload != null)
                    Positioned(
                      bottom: 40,
                      right: 20,
                      child: InkWell(
                        onTap: onDownload,
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.snow,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: const [AppTokens.surfaceShadow],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.download,
                                size: 16,
                                color: AppColors.obsidian,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tải ảnh gốc',
                                style: AppTypography.labelMd(
                                  color: AppColors.obsidian,
                                ),
                              ),
                            ],
                          ),
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
            child: isLocked
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Image.network(url, fit: BoxFit.cover),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.fog,
                      child: const Icon(
                        LucideIcons.imageOff,
                        color: AppColors.steel,
                      ),
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
          if (!isLocked && onDownload != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: InkWell(
                onTap: onDownload,
                borderRadius: BorderRadius.circular(9999),
                child: GlassContainer.mediaBadge(
                  child: const Icon(
                    LucideIcons.download,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (isLocked)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.lock,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
