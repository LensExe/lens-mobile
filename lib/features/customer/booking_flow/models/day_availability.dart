class TimeSlotAvailability {
  const TimeSlotAvailability({required this.time, required this.status});

  final String time;
  final String status;

  bool get isFree => status == 'free';
}

class DayAvailability {
  final DateTime date;
  final bool isBookable;
  final List<TimeSlotAvailability> slots;

  const DayAvailability({
    required this.date,
    required this.isBookable,
    required this.slots,
  });

  /// Availability API returns continuous ranges. The public booking flow
  /// exposes 30-minute starts between 07:00 and 23:30, only when every
  /// half-hour cell needed by the package is free.
  bool canStartAt(String startTime, double durationHours) {
    if (!isBookable || durationHours <= 0) return false;
    final parts = startTime.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || minute % 30 != 0) return false;
    final startMinutes = hour * 60 + minute;
    if (startMinutes < 7 * 60 || startMinutes >= 24 * 60) return false;

    final requiredSlots = (durationHours * 2).ceil();
    if (startMinutes + requiredSlots * 30 > 24 * 60) return false;
    final freeTimes = slots
        .where((slot) => slot.isFree)
        .map((slot) => slot.time)
        .toSet();
    return List.generate(
      requiredSlots,
      (index) => _timeAt(startMinutes + index * 30),
    ).every(freeTimes.contains);
  }

  static String _timeAt(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
