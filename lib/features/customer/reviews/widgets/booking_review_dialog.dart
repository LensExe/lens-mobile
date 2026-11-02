import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../bookings/models/booking_model.dart';
import '../controllers/customer_reviews_controller.dart';
import '../models/customer_review_model.dart';

class RatingSelector extends StatelessWidget {
  const RatingSelector({
    super.key,
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool readOnly;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.labelMd(color: AppColors.obsidian),
        ),
      ),
      for (var score = 1; score <= 5; score++)
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
          onPressed: readOnly ? null : () => onChanged(score),
          icon: Icon(
            score <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 25,
            color: score <= value ? const Color(0xFFF59E0B) : AppColors.pebble,
          ),
        ),
    ],
  );
}

class BookingReviewDialog extends ConsumerStatefulWidget {
  final Booking? booking;
  final SubmittedCustomerReview? review;
  final bool isReadOnly;

  const BookingReviewDialog({super.key, required this.booking})
    : review = null,
      isReadOnly = false;

  const BookingReviewDialog.readOnly({super.key, required this.review})
    : booking = null,
      isReadOnly = true;

  @override
  ConsumerState<BookingReviewDialog> createState() =>
      _BookingReviewDialogState();
}

class _BookingReviewDialogState extends ConsumerState<BookingReviewDialog> {
  double _rating = 5.0;
  int _punctualityRating = 5;
  int _attitudeRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly && widget.review != null) {
      _rating = widget.review!.rating;
      _punctualityRating = widget.review!.punctualityRating;
      _attitudeRating = widget.review!.attitudeRating;
      _commentController.text = widget.review!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating >= 5) return 'Tuyệt vời';
    if (_rating >= 4) return 'Rất tốt';
    if (_rating >= 3) return 'Hài lòng';
    if (_rating >= 2) return 'Cần cải thiện';
    return 'Không hài lòng';
  }

  @override
  Widget build(BuildContext context) {
    final photographerName = widget.isReadOnly
        ? widget.review!.photographerName
        : widget.booking!.photographerName;
    final style = widget.isReadOnly
        ? widget.review!.style
        : widget.booking!.style;
    final date = widget.isReadOnly ? widget.review!.date : widget.booking!.date;

    final commentLength = _commentController.text.trim().length;
    final canSubmit =
        !widget.isReadOnly &&
        _rating >= 1 &&
        _punctualityRating >= 1 &&
        _attitudeRating >= 1 &&
        commentLength <= 10000;

    return Dialog(
      backgroundColor: AppColors.snow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isReadOnly
                            ? 'Đánh giá đã gửi'
                            : 'Viết đánh giá buổi chụp',
                        style: AppTypography.headlineSm(
                          fontSize: 17,
                          color: AppColors.obsidian,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$photographerName · $style',
                        style: AppTypography.bodySm(
                          fontSize: 12,
                          color: AppColors.steel,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.fog,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppColors.steel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Date & Info badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.steel,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ngày chụp: ${_dateLabel(date)}',
                    style: AppTypography.bodySm(
                      fontSize: 12,
                      color: AppColors.obsidian,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _ratingLabel,
              style: AppTypography.titleMd(
                fontSize: 15,
                color: AppColors.ember,
              ),
            ),
            const SizedBox(height: 10),
            RatingSelector(
              label: 'Đánh giá tổng thể',
              value: _rating.round(),
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _rating = value.toDouble()),
            ),
            const SizedBox(height: 8),
            RatingSelector(
              label: 'Đúng giờ',
              value: _punctualityRating,
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _punctualityRating = value),
            ),
            const SizedBox(height: 8),
            RatingSelector(
              label: 'Thái độ phục vụ',
              value: _attitudeRating,
              readOnly: widget.isReadOnly,
              onChanged: (value) => setState(() => _attitudeRating = value),
            ),
            const SizedBox(height: 20),

            // Comment Section
            Text(
              'Nhận xét của bạn',
              style: AppTypography.labelMd(color: AppColors.obsidian),
            ),
            const SizedBox(height: 8),
            if (widget.isReadOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fog,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.pebble),
                ),
                child: Text(
                  widget.review!.comment.isEmpty
                      ? 'Không có nhận xét.'
                      : widget.review!.comment,
                  style: AppTypography.bodySm(
                    color: AppColors.obsidian,
                    fontSize: 13,
                  ),
                ),
              )
            else
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 10000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ về sự chuyên nghiệp, đúng giờ, nhiệt tình của thợ và chất lượng bộ ảnh nhận được...',
                  hintStyle: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: AppColors.fog,
                  counterText: '$commentLength/10.000 ký tự · Không bắt buộc',
                  counterStyle: AppTypography.bodySm(
                    fontSize: 11,
                    color: commentLength <= 10000
                        ? AppColors.steel
                        : AppColors.ember,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.pebble),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.pebble),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.obsidian,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action Button
            if (widget.isReadOnly)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.pebble),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: Text('Đóng', style: AppTypography.labelMd()),
              )
            else
              PrimaryButton(
                text: 'Gửi đánh giá',
                height: 48,
                isLoading: _isSubmitting,
                onPressed: canSubmit ? _submitReview : () {},
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final booking = widget.booking!;

    try {
      await ref
          .read(customerReviewsProvider.notifier)
          .submitReview(
            bookingId: booking.id,
            photographerId: booking.photographerId,
            photographerName: booking.photographerName,
            photographerAvatar: booking.photographerAvatar ?? '',
            style: booking.style,
            date: booking.date,
            rating: _rating.round(),
            punctualityRating: _punctualityRating,
            attitudeRating: _attitudeRating,
            comment: _commentController.text.trim(),
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backend đã ghi nhận đánh giá cho ${booking.photographerName}.',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Không thể gửi đánh giá. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  static String _dateLabel(String value) {
    final parts = value.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : value;
  }
}

