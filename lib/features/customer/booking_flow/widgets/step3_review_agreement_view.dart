import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/booking_wizard_state.dart';

class Step3ReviewAgreementView extends StatelessWidget {
  final BookingWizardState state;
  final ValueChanged<int> onJumpToStep;
  final ValueChanged<bool> onToggleAgreement;

  const Step3ReviewAgreementView({
    super.key,
    required this.state,
    required this.onJumpToStep,
    required this.onToggleAgreement,
  });

  String _formatPrice(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(amount);
  }

  String _calculateEndTime(String startTime, double hours) {
    final parts = startTime.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final totalMinutes = (h * 60 + m + (hours * 60).round());
    final endH = (totalMinutes ~/ 60) % 24;
    final endM = totalMinutes % 60;
    return '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pkg = state.selectedPackage;
    final dateStr = DateFormat('dd/MM/yyyy').format(state.selectedDate);
    final startTime = state.selectedTimeSlot ?? '14:00';
    final endTime = _calculateEndTime(startTime, state.durationHours);
    final timeStr = '$dateStr · $startTime – $endTime';
    final locationStr = state.addressDetail.isNotEmpty
        ? '${state.addressDetail}, ${state.city}'
        : state.city;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Table Card
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
                  'Kiểm tra lại thông tin',
                  style: TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Row 1: Gói chụp -> Sửa step 0
                _ReviewRow(
                  icon: LucideIcons.package,
                  label: 'Gói chụp',
                  value:
                      '${pkg?.name ?? "Gói cơ bản"} · 35 ảnh · ${state.durationHours} giờ chụp · Giao trong 3 ngày\nGiá: ${_formatPrice(state.price)}',
                  onEdit: () => onJumpToStep(0),
                ),
                const Divider(height: 20, color: Color(0xFFF1F1F2)),

                // Row 2: Ngày & giờ -> Sửa step 0
                _ReviewRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày & giờ',
                  value: timeStr,
                  onEdit: () => onJumpToStep(0),
                ),
                const Divider(height: 20, color: Color(0xFFF1F1F2)),

                // Row 3: Địa điểm -> Sửa step 1
                _ReviewRow(
                  icon: LucideIcons.mapPin,
                  label: 'Địa điểm',
                  value: locationStr,
                  onEdit: () => onJumpToStep(1),
                ),
                const Divider(height: 20, color: Color(0xFFF1F1F2)),

                // Row 4: Liên hệ -> Sửa step 1
                _ReviewRow(
                  icon: LucideIcons.userCheck,
                  label: 'Người liên hệ',
                  value: '${state.contactName} · ${state.contactPhone}',
                  onEdit: () => onJumpToStep(1),
                ),

                if (state.note.isNotEmpty) ...[
                  const Divider(height: 20, color: Color(0xFFF1F1F2)),
                  _ReviewRow(
                    icon: LucideIcons.messageSquare,
                    label: 'Ghi chú cho thợ',
                    value: state.note,
                    onEdit: () => onJumpToStep(1),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Policy Alert Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8E9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        size: 20,
                        color: AppColors.ember,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chính sách đặt cọc & hoàn tiền',
                        style: TextStyle(
                          color: Color(0xFF1A1C1D),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PolicyBullet(
                  text:
                      'Đặt cọc 30% (${_formatPrice(state.depositAmount)}) ngay sau bước này để giữ lịch và gửi yêu cầu tới NAG.',
                ),
                _PolicyBullet(
                  text: 'Huỷ trước khi NAG duyệt, hoặc trước ngày chụp từ 7 ngày trở lên: Hoàn 100%. Huỷ muộn hơn: Mất tiền cọc. NAG từ chối: Luôn hoàn 100%.',
                ),
                _PolicyBullet(
                  text:
                      'Phần còn lại 70% (${_formatPrice(state.remainingAmount)}) thanh toán sau khi NAG xác nhận.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mandatory Agreement Checkbox
          InkWell(
            onTap: () => onToggleAgreement(!state.agreedToTerms),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: state.agreedToTerms,
                      onChanged: (v) => onToggleAgreement(v ?? false),
                      activeColor: AppColors.ember,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tôi đồng ý với điều khoản đặt lịch và chính sách đặt cọc của Lens.',
                      style: TextStyle(
                        color: Color(0xFF1A1C1D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF71717A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF71717A),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1C1D),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sửa',
            style: TextStyle(
              color: AppColors.ember,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyBullet extends StatelessWidget {
  final String text;

  const _PolicyBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF71717A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF5F5E60),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
