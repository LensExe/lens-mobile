import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_model.dart';
import '../repositories/customer_booking_report_provider.dart';

const _reportCategories = <(String, String)>[
  ('photo_quality', 'Chất lượng ảnh chưa đạt'),
  ('missing_deliverables', 'Thiếu ảnh hoặc sản phẩm bàn giao'),
  ('late_delivery', 'Giao ảnh trễ'),
  ('photographer_conduct', 'Tác phong hoặc trải nghiệm'),
  ('booking_mismatch', 'Buổi chụp khác thỏa thuận'),
  ('payment_refund', 'Thanh toán hoặc hoàn tiền'),
  ('other', 'Vấn đề khác'),
];

const _reportableStatuses = {'accepted', 'in_progress', 'shot', 'completed'};

class BookingReportPanel extends ConsumerWidget {
  const BookingReportPanel({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(customerBookingReportProvider(booking.id));
    final canReport = _reportableStatuses.contains(booking.backendStatus);

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.flag,
                  size: 18,
                  color: AppColors.ember,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportState.value == null
                          ? 'Có vấn đề với buổi chụp?'
                          : 'Report gần nhất',
                      style: AppTypography.titleMd(
                        fontSize: 14,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportState.value == null
                          ? 'Gửi mô tả và ảnh bằng chứng để Lens xem xét. Report không tự hủy booking hoặc hoàn tiền.'
                          : _statusDescription(reportState.value!.status),
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ),
              ),
              if (reportState.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ember,
                  ),
                ),
            ],
          ),
          if (reportState.value case final report?) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.pebble),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ReportStatusBadge(status: report.status),
                      if (report.issueType != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _categoryLabel(report.issueType!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(
                              fontSize: 11,
                              color: AppColors.steel,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (report.resolution != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Phản hồi từ Lens: ${report.resolution}',
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (reportState.hasError) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Không tải được trạng thái report.',
                    style: AppTypography.bodySm(
                      fontSize: 12,
                      color: AppColors.crimson,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(customerBookingReportProvider(booking.id)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ],
          if (canReport && !reportState.isLoading && !reportState.hasError) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _BookingReportDialog.show(context, bookingId: booking.id),
                icon: const Icon(LucideIcons.flag, size: 16),
                label: Text(
                  reportState.value == null
                      ? 'Báo cáo vấn đề'
                      : 'Báo thêm vấn đề',
                ),
              ),
            ),
          ] else if (!canReport && reportState.value == null) ...[
            const SizedBox(height: 10),
            Text(
              'Bạn có thể gửi report sau khi nhiếp ảnh gia xác nhận booking.',
              style: AppTypography.bodySm(
                fontSize: 11.5,
                color: AppColors.steel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'open' => ('Đang chờ xem xét', AppColors.ember),
      'escalated' => ('Đang được ưu tiên xử lý', AppColors.lagoon),
      'resolved' => ('Đã xử lý', AppColors.emerald),
      'rejected' => ('Không được chấp nhận', AppColors.steel),
      _ => (status, AppColors.steel),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm(fontSize: 10, color: color),
      ),
    );
  }
}

class _BookingReportDialog extends ConsumerStatefulWidget {
  const _BookingReportDialog({required this.bookingId});

  final String bookingId;

  static Future<void> show(BuildContext context, {required String bookingId}) =>
      showDialog<void>(
        context: context,
        builder: (_) => _BookingReportDialog(bookingId: bookingId),
      );

  @override
  ConsumerState<_BookingReportDialog> createState() =>
      _BookingReportDialogState();
}

class _BookingReportDialogState extends ConsumerState<_BookingReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _evidence = [];
  String _issueType = _reportCategories.first.$1;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.snow,
    title: Text(
      'Báo cáo vấn đề với buổi chụp',
      style: AppTypography.titleMd(color: AppColors.obsidian),
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mô tả rõ vấn đề để Lens xem xét. Report không tự động hủy booking hoặc hoàn tiền.',
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _issueType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vấn đề bạn gặp phải',
                ),
                items: [
                  for (final category in _reportCategories)
                    DropdownMenuItem(
                      value: category.$1,
                      child: Text(category.$2, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _issueType = value);
                      },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController,
                minLines: 4,
                maxLines: 7,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText: 'Nêu rõ điều gì đã xảy ra, thời điểm và mong muốn được hỗ trợ…',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final reason = value?.trim() ?? '';
                  if (reason.length < 10) {
                    return 'Mô tả cần có ít nhất 10 ký tự.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ảnh bằng chứng · tối đa 5 ảnh, 12 MB mỗi ảnh',
                      style: AppTypography.labelSm(
                        fontSize: 11,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _submitting || _evidence.length >= 5
                        ? null
                        : _pickEvidence,
                    icon: const Icon(LucideIcons.imagePlus, size: 16),
                    label: const Text('Thêm ảnh'),
                  ),
                ],
              ),
              if (_evidence.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < _evidence.length; index++)
                      _EvidenceThumbnail(
                        image: _evidence[index],
                        onRemove: _submitting
                            ? null
                            : () => setState(() => _evidence.removeAt(index)),
                      ),
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: AppTypography.bodySm(color: AppColors.crimson),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        child: const Text('Để sau'),
      ),
      FilledButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.send, size: 16),
        label: Text(_submitting ? 'Đang gửi…' : 'Gửi report'),
      ),
    ],
  );

  Future<void> _pickEvidence() async {
    try {
      final selected = await _picker.pickMultiImage(
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 90,
      );
      if (selected.isEmpty || !mounted) return;
      if (_evidence.length + selected.length > 5) {
        setState(() => _error = 'Bạn chỉ có thể đính kèm tối đa 5 ảnh.');
        return;
      }
      for (final image in selected) {
        final extension = image.path.split('.').last.toLowerCase();
        if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
          setState(() => _error = 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP.');
          return;
        }
        final size = await File(image.path).length();
        if (size <= 0 || size > 12 * 1024 * 1024) {
          setState(
            () => _error = 'Mỗi ảnh bằng chứng phải từ 1 byte đến 12 MB.',
          );
          return;
        }
      }
      setState(() {
        _evidence.addAll(selected);
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể chọn ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(customerBookingReportRepositoryProvider)
          .createReport(
            bookingId: widget.bookingId,
            issueType: _issueType,
            reason: _reasonController.text,
            evidencePaths: _evidence.map((image) => image.path).toList(),
          );
      ref.invalidate(customerBookingReportProvider(widget.bookingId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi report cho Lens xem xét.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ApiException
            ? error.message
            : 'Không thể gửi report. Vui lòng thử lại.';
      });
    }
  }
}

class _EvidenceThumbnail extends StatelessWidget {
  const _EvidenceThumbnail({required this.image, required this.onRemove});

  final XFile image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 64,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(image.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.obsidian,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    ),
  );
}

String _categoryLabel(String issueType) {
  for (final category in _reportCategories) {
    if (category.$1 == issueType) return category.$2;
  }
  return issueType;
}

String _statusDescription(String status) => switch (status) {
  'open' => 'Lens đã nhận report và sẽ cập nhật khi có kết quả.',
  'escalated' => 'Report đang được ưu tiên xử lý.',
  'resolved' => 'Lens đã hoàn tất xử lý report này.',
  'rejected' => 'Report không được chấp nhận sau khi xem xét.',
  _ => 'Trạng thái report được cập nhật tại đây.',
};
