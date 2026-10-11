import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_wizard_state.dart';

class Step2ContactLocationView extends StatefulWidget {
  final BookingWizardState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onAddressChanged;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<bool> onSaveDefaultChanged;

  const Step2ContactLocationView({
    super.key,
    required this.state,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onCityChanged,
    required this.onAddressChanged,
    required this.onNoteChanged,
    required this.onSaveDefaultChanged,
  });

  @override
  State<Step2ContactLocationView> createState() =>
      _Step2ContactLocationViewState();
}

class _Step2ContactLocationViewState extends State<Step2ContactLocationView> {
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.state.city);
    _addressController = TextEditingController(
      text: widget.state.addressDetail,
    );
  }

  @override
  void didUpdateWidget(covariant Step2ContactLocationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.city != widget.state.city &&
        _cityController.text != widget.state.city) {
      _cityController.text = widget.state.city;
    }
    if (oldWidget.state.addressDetail != widget.state.addressDetail &&
        _addressController.text != widget.state.addressDetail) {
      _addressController.text = widget.state.addressDetail;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppTokens.pageHorizontal,
      10,
      AppTokens.pageHorizontal,
      32,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Địa điểm chụp', style: AppTypography.headlineSm(fontSize: 19)),
        const SizedBox(height: 8),
        Text(
          'Backend lưu địa điểm dưới dạng một chuỗi vị trí cho yêu cầu đặt lịch.',
          style: AppTypography.bodySm(color: AppColors.steel),
        ),
        const SizedBox(height: 20),
        _LocationField(
          controller: _cityController,
          label: 'Tỉnh / thành phố',
          hint: 'Nhập khu vực',
          icon: LucideIcons.map,
          onChanged: widget.onCityChanged,
        ),
        const SizedBox(height: 16),
        _LocationField(
          controller: _addressController,
          label: 'Địa chỉ hoặc khu vực cụ thể',
          hint: 'Tên studio, đường hoặc địa điểm ngoài trời',
          icon: LucideIcons.mapPin,
          onChanged: widget.onAddressChanged,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fog,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.pebble),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 17, color: AppColors.steel),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tên liên hệ, số điện thoại, ghi chú và địa chỉ mặc định không thuộc request booking hiện tại.',
                  style: AppTypography.bodySm(
                    fontSize: 12,
                    color: AppColors.steel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.labelMd(fontSize: 12.5)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.steel),
          filled: true,
          fillColor: AppColors.fog,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.pebble),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.pebble),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.ember, width: 1.5),
          ),
        ),
      ),
    ],
  );
}
