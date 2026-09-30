import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
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
          // Review Table Card
          Container(
            width: double.infinity,
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
                Text(
                  'Kiểm tra lại thông tin',
                  style: AppTypography.titleMd(
                    fontSize: 17,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 14),

                // Row 1: Gói chụp -> Sửa step 0
                _ReviewRow(
                  icon: LucideIcons.package,
                  label: 'Gói chụp',
                  value:
                      '${pkg?.name ?? "Gói cơ bản"} · ${state.durationHours} giờ chụp\nTổng tiền: ${AppTypography.formatCurrency(state.price)}',
                  onEdit: () => onJumpToStep(0),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),

                // Row 2: Ngày & giờ -> Sửa step 0
                _ReviewRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày & giờ',
                  value: timeStr,
                  onEdit: () => onJumpToStep(0),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),

                // Row 3: Địa điểm -> Sửa step 1
                _ReviewRow(
                  icon: LucideIcons.mapPin,
                  label: 'Địa điểm',
                  value: locationStr,
                  onEdit: () => onJumpToStep(1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),

                // Row 4: Liên hệ -> Sửa step 1
                _ReviewRow(
                  icon: LucideIcons.userCheck,
                  label: 'Người liên hệ',
                  value: '${state.contactName} · ${state.contactPhone}',
                  onEdit: () => onJumpToStep(1),
                ),

                if (state.note.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.pebble),
                  ),
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
              color: AppColors.fog,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.ember.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.shieldCheck,
                        size: 20,
                        color: AppColors.ember,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chính sách đặt cọc & hoàn tiền Escrow',
                        style: AppTypography.titleMd(
                          fontSize: 14.5,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PolicyBullet(
                  text:
                      'Đặt cọc 30% (${AppTypography.formatCurrency(state.depositAmount)}) ngay sau bước này để bảo đảm lịch và gửi yêu cầu cho nhiếp ảnh gia.',
                ),
                _PolicyBullet(
                  text:
                      'Huỷ trước khi nhiếp ảnh gia duyệt, hoặc trước buổi chụp từ 7 ngày: hoàn tiền 100%. Nếu nhiếp ảnh gia từ chối: hoàn 100% tự động.',
                ),
                _PolicyBullet(
                  text:
                      'Phần còn lại 70% (${AppTypography.formatCurrency(state.remainingAmount)}) thanh toán sau khi lịch chụp được xác nhận.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mandatory Agreement Checkbox
          InkWell(
            onTap: () => onToggleAgreement(!state.agreedToTerms),
            borderRadius: BorderRadius.circular(12),
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
                  Expanded(
                    child: Text(
                      'Tôi đồng ý với điều khoản đặt lịch và chính sách bảo vệ Escrow của Lens.',
                      style: AppTypography.bodySm(
                        fontSize: 13,
                        color: AppColors.obsidian,
                      ).copyWith(fontWeight: FontWeight.w500),
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
        Icon(icon, size: 16, color: AppColors.steel),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSm(
                  fontSize: 11,
                  color: AppColors.steel,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTypography.bodySm(
                  fontSize: 13,
                  color: AppColors.obsidian,
                ).copyWith(fontWeight: FontWeight.w600, height: 1.35),
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
          child: Text(
            'Sửa',
            style: AppTypography.labelMd(
              fontSize: 12,
              color: AppColors.ember,
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
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.steel,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm(
                fontSize: 12,
                color: AppColors.steel,
              ).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
