import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
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
        return 'Th 2';
      case DateTime.tuesday:
        return 'Th 3';
      case DateTime.wednesday:
        return 'Th 4';
      case DateTime.thursday:
        return 'Th 5';
      case DateTime.friday:
        return 'Th 6';
      case DateTime.saturday:
        return 'Th 7';
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

    // Tạo 14 ngày bắt đầu từ hôm nay hoặc ngày mai
    final List<DateTime> days = List.generate(
      21,
      (index) => today.add(Duration(days: index)),
    );

    final monthLabel =
        'Tháng ${_displayedMonth.month}, ${_displayedMonth.year}';

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
          // Header: "2. Chọn Ngày Chụp" & Month label & Chevron buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Chọn Ngày Chụp',
                    style: TextStyle(
                      color: Color(0xFF1A1C1D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      color: Color(0xFF5F5E60),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _MonthNavButton(
                    icon: LucideIcons.chevronLeft,
                    onTap: _prevMonth,
                  ),
                  const SizedBox(width: 8),
                  _MonthNavButton(
                    icon: LucideIcons.chevronRight,
                    onTap: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Date Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: days.map((date) {
                final isSelected =
                    widget.selectedDate.year == date.year &&
                    widget.selectedDate.month == date.month &&
                    widget.selectedDate.day == date.day;
                final isPast = date.isBefore(today);
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final dayAvail = widget.availabilityMap[dateKey];
                final hasSlots =
                    dayAvail != null && dayAvail.slots.any((s) => s.isFree);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
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
                    borderRadius: BorderRadius.circular(48),
                    child: Opacity(
                      opacity: isPast ? 0.35 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.ember
                              : (hasSlots
                                    ? const Color(0xFFF7F7F8)
                                    : const Color(0xFFF1F1F2)),
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x33EE5A00),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.ember
                                : (hasSlots
                                      ? const Color(0xFFE8E8E9)
                                      : Colors.transparent),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDayOfWeek(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF5F5E60),
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1A1C1D),
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Dot indicator
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (hasSlots
                                          ? AppColors.ember
                                          : const Color(0xFFD4D4D8)),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E8E9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1A1C1D)),
      ),
    );
  }
}
