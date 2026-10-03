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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.contactName);
    _phoneController = TextEditingController(text: widget.state.contactPhone);
    _addressController = TextEditingController(
      text: widget.state.addressDetail,
    );
    _noteController = TextEditingController(text: widget.state.note);
  }

  @override
  void didUpdateWidget(covariant Step2ContactLocationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.contactName != widget.state.contactName &&
        _nameController.text != widget.state.contactName) {
      _nameController.text = widget.state.contactName;
    }
    if (oldWidget.state.contactPhone != widget.state.contactPhone &&
        _phoneController.text != widget.state.contactPhone) {
      _phoneController.text = widget.state.contactPhone;
    }
    if (oldWidget.state.addressDetail != widget.state.addressDetail &&
        _addressController.text != widget.state.addressDetail) {
      _addressController.text = widget.state.addressDetail;
    }
    if (oldWidget.state.note != widget.state.note &&
        _noteController.text != widget.state.note) {
      _noteController.text = widget.state.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Chọn Tỉnh / Thành phố',
                      style: AppTypography.titleMd(color: AppColors.obsidian),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.pebble),
              ...BookingWizardState.standardCities.map((city) {
                final isSelected = widget.state.city == city;
                return ListTile(
                  title: Text(
                    city,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? AppColors.ember : AppColors.obsidian,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          LucideIcons.check,
                          color: AppColors.ember,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    widget.onCityChanged(city);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          // Section 1: Thông tin liên hệ
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1. Thông tin liên hệ',
                      style: AppTypography.headlineSm(fontSize: 18),
                    ),
                    if (widget.state.isAutofilled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.checkCheck,
                              size: 12,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đã điền từ hồ sơ của bạn',
                              style: AppTypography.numeric(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Họ và tên
                Text(
                  'Họ và tên *',
                  style: AppTypography.labelMd(
                    fontSize: 12.5,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  onChanged: widget.onNameChanged,
                  decoration: InputDecoration(
                    hintText: 'Người liên hệ',
                    prefixIcon: const Icon(
                      LucideIcons.user,
                      size: 18,
                      color: AppColors.steel,
                    ),
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
                      borderSide: const BorderSide(
                        color: AppColors.ember,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (!widget.state.isNameValid &&
                    widget.state.contactName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tên phải có tối thiểu 2 ký tự',
                    style: AppTypography.bodySm(
                      color: AppColors.crimson,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Số điện thoại
                Text(
                  'Số điện thoại *',
                  style: AppTypography.labelMd(
                    fontSize: 12.5,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: widget.onPhoneChanged,
                  decoration: InputDecoration(
                    hintText: 'VD: 0901234567',
                    prefixIcon: const Icon(
                      LucideIcons.phone,
                      size: 18,
                      color: AppColors.steel,
                    ),
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
                      borderSide: const BorderSide(
                        color: AppColors.ember,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (!widget.state.isPhoneValid &&
                    widget.state.contactPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Số điện thoại không hợp lệ (VD: 0901234567)',
                    style: AppTypography.bodySm(
                      color: AppColors.crimson,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Section 2: Địa điểm chụp
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Địa điểm chụp',
                  style: AppTypography.headlineSm(fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Tỉnh / Thành phố
                Text(
                  'Tỉnh / Thành phố *',
                  style: AppTypography.labelMd(
                    fontSize: 12.5,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showCityPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fog,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.pebble),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 18,
                          color: AppColors.steel,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.state.city,
                            style: AppTypography.bodySm(
                              fontSize: 14,
                              color: AppColors.obsidian,
                            ).copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: AppColors.steel,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Địa chỉ cụ thể
                Text(
                  'Địa chỉ cụ thể (không bắt buộc)',
                  style: AppTypography.labelMd(
                    fontSize: 12.5,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressController,
                  maxLength: 120,
                  onChanged: widget.onAddressChanged,
                  decoration: InputDecoration(
                    hintText: 'VD: Hồ Tây, phim trường Santorini, quán cafe...',
                    prefixIcon: const Icon(
                      LucideIcons.building,
                      size: 18,
                      color: AppColors.steel,
                    ),
                    filled: true,
                    fillColor: AppColors.fog,
                    counterText: '',
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
                      borderSide: const BorderSide(
                        color: AppColors.ember,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Checkbox: Lưu làm mặc định
                InkWell(
                  onTap: () =>
                      widget.onSaveDefaultChanged(!widget.state.saveAsDefault),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: widget.state.saveAsDefault,
                          onChanged: (v) =>
                              widget.onSaveDefaultChanged(v ?? false),
                          activeColor: AppColors.ember,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lưu số điện thoại & địa chỉ này làm mặc định cho lần sau',
                          style: AppTypography.bodySm(
                            fontSize: 12.5,
                            color: AppColors.steel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),

          // Section 3: Ghi chú cho NAG
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Ghi chú cho nhiếp ảnh gia',
                  style: AppTypography.headlineSm(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ý tưởng concept, số người chụp, tư vấn trang phục...',
                  style: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: widget.onNoteChanged,
                  decoration: InputDecoration(
                    hintText: 'VD: Chụp gia đình 4 người, tông màu ấm, có bé 2 tuổi, cần tư vấn trang phục...',
                    filled: true,
                    fillColor: AppColors.fog,
                    contentPadding: const EdgeInsets.all(14),
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
                      borderSide: const BorderSide(
                        color: AppColors.ember,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
