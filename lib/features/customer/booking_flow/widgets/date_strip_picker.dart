import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/day_availability.dart';

class DateStripPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<String, DayAvailability> availabilityMap;

  const DateStripPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availabilityMap,
  });

  @override
  State<DateStripPicker> createState() => _DateStripPickerState();
}

class _DateStripPickerState extends State<DateStripPicker> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
  }

  String _formatDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(21, (index) => today.add(Duration(days: index)));
    final monthLabel =
        'Tháng ${_displayedMonth.month}, ${_displayedMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2. Chọn ngày chụp', style: AppTypography.headlineSm()),
                  const SizedBox(height: 3),
                  Text(monthLabel, style: AppTypography.bodySm()),
                ],
              ),
            ),
            _MonthNavButton(icon: LucideIcons.chevronLeft, onTap: _prevMonth),
            const SizedBox(width: 8),
            _MonthNavButton(icon: LucideIcons.chevronRight, onTap: _nextMonth),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = days[index];
              final isSelected =
                  widget.selectedDate.year == date.year &&
                  widget.selectedDate.month == date.month &&
                  widget.selectedDate.day == date.day;
              final isPast = date.isBefore(today);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final dayAvailability = widget.availabilityMap[dateKey];
              final hasSlots =
                  dayAvailability != null &&
                  dayAvailability.slots.any((slot) => slot.isFree);

              return Semantics(
                button: true,
                selected: isSelected,
                label: '${_formatDayOfWeek(date)} ${date.day}',
                child: Opacity(
                  opacity: isPast ? .4 : 1,
                  child: InkWell(
                    onTap: isPast
                        ? null
                        : () {
                            widget.onDateSelected(date);
                            setState(() {
                              _displayedMonth = DateTime(
                                date.year,
                                date.month,
                                1,
                              );
                            });
                          },
                    borderRadius: BorderRadius.circular(17),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.obsidian : AppColors.snow,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.obsidian
                              : AppColors.pebble,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDayOfWeek(date),
                            style: AppTypography.labelSm(
                              color: isSelected
                                  ? AppColors.snow
                                  : AppColors.steel,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: AppTypography.numeric(
                              color: isSelected
                                  ? AppColors.snow
                                  : AppColors.obsidian,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.snow
                                  : hasSlots
                                  ? AppColors.ember
                                  : AppColors.pebble,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.snow,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pebble),
          ),
          child: Icon(icon, size: 17, color: AppColors.obsidian),
        ),
      ),
    );
  }
}
