import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/vietnam_time.dart';
import '../models/day_availability.dart';

class DateStripPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<String, DayAvailability> availabilityMap;
  final double durationHours;

  const DateStripPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availabilityMap,
    required this.durationHours,
  });

  @override
  State<DateStripPicker> createState() => _DateStripPickerState();
}

class _DateStripPickerState extends State<DateStripPicker> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.utc(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
  }

  @override
  void didUpdateWidget(covariant DateStripPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _displayedMonth = DateTime.utc(
        widget.selectedDate.year,
        widget.selectedDate.month,
        1,
      );
    }
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
      _displayedMonth = DateTime.utc(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime.utc(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  List<DateTime> _availableDates() {
    final parsed = <DateTime>[];
    for (final key in widget.availabilityMap.keys) {
      try {
        parsed.add(VietnamTime.parseDateKey(key));
      } on FormatException {
        continue;
      }
    }
    parsed.sort();
    if (parsed.isNotEmpty) return parsed;
    final today = VietnamTime.today();
    return List.generate(31, (index) => today.add(Duration(days: index)));
  }

  List<DateTime> _visibleDates(List<DateTime> availableDates) {
    if (availableDates.isEmpty) return const [];
    final monthStart = DateTime.utc(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final monthEnd = DateTime.utc(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );
    final start = monthStart.isBefore(availableDates.first)
        ? availableDates.first
        : monthStart;
    final end = monthEnd.isAfter(availableDates.last)
        ? availableDates.last
        : monthEnd;
    if (start.isAfter(end)) return const [];
    return List.generate(
      end.difference(start).inDays + 1,
      (index) => start.add(Duration(days: index)),
    );
  }

  bool _monthHasDates(int year, int month, List<DateTime> availableDates) =>
      availableDates.any((date) => date.year == year && date.month == month);

  @override
  Widget build(BuildContext context) {
    final today = VietnamTime.today();
    final availableDates = _availableDates();
    final days = _visibleDates(availableDates);
    final previousMonth = DateTime.utc(
      _displayedMonth.year,
      _displayedMonth.month - 1,
      1,
    );
    final nextMonth = DateTime.utc(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      1,
    );
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
            _MonthNavButton(
              icon: LucideIcons.chevronLeft,
              enabled: _monthHasDates(
                previousMonth.year,
                previousMonth.month,
                availableDates,
              ),
              onTap: _prevMonth,
            ),
            const SizedBox(width: 8),
            _MonthNavButton(
              icon: LucideIcons.chevronRight,
              enabled: _monthHasDates(
                nextMonth.year,
                nextMonth.month,
                availableDates,
              ),
              onTap: _nextMonth,
            ),
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
                  dayAvailability.slots.any(
                    (slot) => dayAvailability.canStartAt(
                      slot.time,
                      widget.durationHours,
                    ),
                  );

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
                              _displayedMonth = DateTime.utc(
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
  final bool enabled;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.snow : AppColors.fog,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pebble),
          ),
          child: Icon(
            icon,
            size: 17,
            color: enabled ? AppColors.obsidian : AppColors.ash,
          ),
        ),
      ),
    );
  }
}
