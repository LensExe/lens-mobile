import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import 'repositories/booking_report_repository.dart';

Future<BookingReportReceipt?> showBookingReportSheet(
  BuildContext context, {
  required String bookingId,
}) {
  return showModalBottomSheet<BookingReportReceipt>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BookingReportSheet(bookingId: bookingId),
  );
}

class _BookingReportSheet extends ConsumerStatefulWidget {
  const _BookingReportSheet({required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<_BookingReportSheet> createState() =>
      _BookingReportSheetState();
}

class _BookingReportSheetState extends ConsumerState<_BookingReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _evidence = [];
  BookingReportCategory? _category;
  String? _errorMessage;
  bool _isSubmitting = false;
  int _uploadingEvidence = 0;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.pebble,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Báo vấn đề với buổi chụp',
                        style: AppTypography.headlineSm(
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn nội dung phù hợp và mô tả cụ thể để Lens Care xem xét booking này.',
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<BookingReportCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Vấn đề bạn gặp phải',
                    border: OutlineInputBorder(),
                  ),
                  items: BookingReportCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn loại vấn đề.' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reasonController,
                  enabled: !_isSubmitting,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 10000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    hintText: 'Điều gì đã xảy ra với buổi chụp hoặc bộ ảnh?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng mô tả vấn đề.'
                      : null,
                ),
                const SizedBox(height: 6),
                _evidencePicker(),
                if (_isSubmitting && _evidence.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _uploadingEvidence / _evidence.length,
                    color: AppColors.ember,
                    backgroundColor: AppColors.fog,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đang tải bằng chứng $_uploadingEvidence/${_evidence.length}…',
                    style: AppTypography.bodySm(color: AppColors.steel),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorNotice(message: _errorMessage!),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Gửi report',
                  height: 50,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                  leadingIcon: const Icon(LucideIcons.send, size: 17),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gửi report không tự hủy booking hoặc tạo yêu cầu hoàn tiền. Lens Care sẽ xem xét riêng trường hợp của bạn.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm(
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _evidencePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed:
              _isSubmitting ||
                  _evidence.length >= BookingReportRepository.maxEvidenceCount
              ? null
              : _pickEvidence,
          icon: const Icon(LucideIcons.imagePlus, size: 18),
          label: Text('Thêm ảnh bằng chứng (${_evidence.length}/5)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.obsidian,
            side: const BorderSide(color: AppColors.pebble),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.pillRadius),
            ),
          ),
        ),
        if (_evidence.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(_evidence.length, (index) {
            final file = _evidence[index];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.image, color: AppColors.lagoon),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(color: AppColors.obsidian),
              ),
              trailing: IconButton(
                tooltip: 'Xóa ảnh',
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _evidence.removeAt(index)),
                icon: const Icon(LucideIcons.x, size: 18),
              ),
            );
          }),
        ],
        const SizedBox(height: 4),
        Text(
          'Có thể tải tối đa 5 ảnh, mỗi ảnh dưới 12 MB. Ảnh được tải riêng để làm bằng chứng.',
          style: AppTypography.bodySm(fontSize: 12, color: AppColors.steel),
        ),
      ],
    );
  }

  Future<void> _pickEvidence() async {
    setState(() => _errorMessage = null);
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1920,
      );
      if (!mounted || picked.isEmpty) return;
      final remaining =
          BookingReportRepository.maxEvidenceCount - _evidence.length;
      setState(() {
        _evidence.addAll(picked.take(remaining));
        if (picked.length > remaining) {
          _errorMessage = 'Chỉ có thể đính kèm tối đa 5 ảnh.';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Không chọn được ảnh: $error');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _uploadingEvidence = 0;
    });

    try {
      final repository = ref.read(bookingReportRepositoryProvider);
      final evidenceIds = <String>[];
      for (final file in _evidence) {
        evidenceIds.add(await repository.uploadEvidence(file));
        if (!mounted) return;
        setState(() => _uploadingEvidence++);
      }
      final report = await repository.createReport(
        bookingId: widget.bookingId,
        category: _category!,
        reason: _reasonController.text,
        evidenceMediaIds: evidenceIds,
      );
      if (mounted) Navigator.of(context).pop(report);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.crimson.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.crimson.withValues(alpha: 0.25)),
    ),
    child: Text(message, style: AppTypography.bodySm(color: AppColors.crimson)),
  );
}
