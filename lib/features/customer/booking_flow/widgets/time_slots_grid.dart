import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/day_availability.dart';

class TimeSlotsGrid extends StatelessWidget {
  final DayAvailability? dayAvailability;
  final double durationHours;
  final String? selectedTimeSlot;
  final ValueChanged<String> onSelectSlot;

  const TimeSlotsGrid({
    super.key,
    required this.dayAvailability,
    required this.durationHours,
    required this.selectedTimeSlot,
    required this.onSelectSlot,
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
    final slots = dayAvailability?.slots ?? [];

    return Container(
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
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                '3. Chọn Giờ Bắt Đầu',
                style: TextStyle(
                  color: Color(0xFF1A1C1D),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Thời lượng $durationHours giờ',
                  style: const TextStyle(
                    color: AppColors.ember,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Explanatory note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8E8E9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 14,
                  color: Color(0xFF5F5E60),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hệ thống giữ liền đủ $durationHours giờ từ thời điểm bắt đầu, các lịch bị chồng sẽ tự động bị khóa.',
                    style: const TextStyle(
                      color: Color(0xFF5F5E60),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid of time slots
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có khung giờ trống cho ngày này',
                  style: TextStyle(color: Color(0xFF5F5E60), fontSize: 13),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final isBooked = !slot.isFree;
                final canStart =
                    !isBooked &&
                    (dayAvailability?.canStartAt(slot.time, durationHours) ??
                        false);
                final isSelected = selectedTimeSlot == slot.time;

                String? statusLabel;
                if (isBooked) {
                  statusLabel = 'Đã đặt';
                } else if (!canStart) {
                  statusLabel = 'Không đủ giờ';
                }

                final isEnabled = canStart && !isBooked;

                return InkWell(
                  onTap: isEnabled ? () => onSelectSlot(slot.time) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.ember
                          : (isEnabled
                                ? Colors.white
                                : const Color(0xFFF5F5F6)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.ember
                            : (isEnabled
                                  ? const Color(0xFFD4D4D8)
                                  : const Color(0xFFE8E8E9)),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x33EE5A00),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                LucideIcons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              slot.time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isEnabled
                                          ? const Color(0xFF1A1C1D)
                                          : const Color(0xFF9E9E9F)),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                decoration: !isEnabled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9F),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (isSelected) ...[
                          const SizedBox(height: 2),
                          Text(
                            'đến ${_calculateEndTime(slot.time, durationHours)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
