import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
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
      backgroundColor: Colors.white,
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
                    const Text(
                      'Chọn Tỉnh / Thành phố',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1C1D),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
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
                      color: isSelected
                          ? AppColors.ember
                          : const Color(0xFF1A1C1D),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Thông tin liên hệ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1. Thông tin liên hệ',
                      style: TextStyle(
                        color: Color(0xFF1A1C1D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (widget.state.isAutofilled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.checkCheck,
                              size: 12,
                              color: Color(0xFF0F9D58),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Đã điền từ hồ sơ của bạn',
                              style: TextStyle(
                                color: Color(0xFF0F9D58),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Họ và tên
                const Text(
                  'Họ và tên *',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                      color: Color(0xFF71717A),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  const Text(
                    'Tên phải có tối thiểu 2 ký tự',
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 14),

                // Số điện thoại
                const Text(
                  'Số điện thoại *',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                      color: Color(0xFF71717A),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  const Text(
                    'Số điện thoại không hợp lệ (VD: 0901234567)',
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Địa điểm chụp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Địa điểm chụp',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Tỉnh / Thành phố
                const Text(
                  'Tỉnh / Thành phố *',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showCityPicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8E8E9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 18,
                          color: Color(0xFF71717A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.state.city,
                            style: const TextStyle(
                              color: Color(0xFF1A1C1D),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: Color(0xFF71717A),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Địa chỉ cụ thể
                const Text(
                  'Địa chỉ cụ thể (không bắt buộc)',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                      color: Color(0xFF71717A),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9FA),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                      const Expanded(
                        child: Text(
                          'Lưu số điện thoại & địa chỉ này làm mặc định cho lần sau',
                          style: TextStyle(
                            color: Color(0xFF5F5E60),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Ghi chú cho NAG
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3. Ghi chú cho nhiếp ảnh gia',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ý tưởng concept, số người chụp, tư vấn trang phục...',
                  style: TextStyle(color: Color(0xFF5F5E60), fontSize: 12),
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
                    fillColor: const Color(0xFFF9F9FA),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
