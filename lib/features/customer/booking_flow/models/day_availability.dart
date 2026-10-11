class TimeSlotAvailability {
  const TimeSlotAvailability({
    required this.time,
    required this.status,
    required this.availableUntil,
  });

  final String time;
  final String status;
  final DateTime availableUntil;

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

  /// Availability API returns continuous ranges, not a slot interval.
  /// This accepts only a Backend range boundary, without inventing a grid.
  bool canStartAt(String startTime, double durationHours) {
    if (!isBookable) return false;
    final matching = slots.where(
      (slot) => slot.time == startTime && slot.isFree,
    );
    if (matching.isEmpty) return false;
    final slot = matching.first;
    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]),
    );
    return slot.availableUntil.difference(startsAt).inMinutes >=
        (durationHours * 60).ceil();
  }
}
