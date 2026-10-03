import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '3. Chọn giờ bắt đầu',
                style: AppTypography.headlineSm(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.fog,
                borderRadius: BorderRadius.circular(AppTokens.pillRadius),
              ),
              child: Text(
                '$durationHours giờ',
                style: AppTypography.labelSm(color: AppColors.graphite),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 14, color: AppColors.steel),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Chọn giờ bắt đầu có đủ thời lượng liên tục cho gói chụp.',
                style: AppTypography.bodySm(color: AppColors.steel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'Không có khung giờ trống cho ngày này',
              style: AppTypography.bodySm(color: AppColors.steel),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
                  final isBooked = !slot.isFree;
                  final canStart =
                      !isBooked &&
                      (dayAvailability?.canStartAt(slot.time, durationHours) ??
                          false);
                  final isSelected = selectedTimeSlot == slot.time;
                  final isEnabled = canStart && !isBooked;
                  final statusLabel = isBooked
                      ? 'Đã đặt'
                      : !canStart
                      ? 'Không đủ giờ'
                      : isSelected
                      ? 'Đến ${_calculateEndTime(slot.time, durationHours)}'
                      : '';

                  return SizedBox(
                    width: itemWidth,
                    child: Semantics(
                      button: true,
                      enabled: isEnabled,
                      selected: isSelected,
                      label: statusLabel.isEmpty
                          ? slot.time
                          : '${slot.time}, $statusLabel',
                      child: InkWell(
                        onTap: isEnabled ? () => onSelectSlot(slot.time) : null,
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          constraints: const BoxConstraints(minHeight: 62),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.obsidian
                                : isEnabled
                                ? AppColors.snow
                                : AppColors.fog,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.obsidian
                                  : isEnabled
                                  ? AppColors.pebble
                                  : AppColors.fog,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      LucideIcons.check,
                                      size: 13,
                                      color: AppColors.snow,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    slot.time,
                                    style: AppTypography.numeric(
                                      color: isSelected
                                          ? AppColors.snow
                                          : isEnabled
                                          ? AppColors.obsidian
                                          : AppColors.ash,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSm(
                                  color: isSelected
                                      ? AppColors.snow.withValues(alpha: .8)
                                      : AppColors.steel,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}
