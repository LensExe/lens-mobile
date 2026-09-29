class TimeSlotAvailability {
  final String time; // e.g. "08:00", "08:30"
  final String status; // 'free' | 'booked' | 'busy'

  const TimeSlotAvailability({required this.time, required this.status});

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

  /// Kiểm tra xem slot bắt đầu có đủ các khung giờ 30p liên tiếp còn trống hay không
  bool canStartAt(String startTime, double durationHours) {
    if (!isBookable) return false;
    final requiredSlots = (durationHours * 60 / 30).ceil();
    final startIndex = slots.indexWhere((s) => s.time == startTime);
    if (startIndex == -1) return false;
    if (startIndex + requiredSlots > slots.length) return false;

    for (int i = 0; i < requiredSlots; i++) {
      if (slots[startIndex + i].status != 'free') {
        return false;
      }
    }
    return true;
  }

  /// Helper sinh danh sách khung giờ mẫu cho 1 ngày
  static List<TimeSlotAvailability> generateDefaultSlots({
    List<String> bookedSlots = const [],
    List<String> busySlots = const [],
  }) {
    final List<TimeSlotAvailability> result = [];
    final times = [
      '07:00',
      '07:30',
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
      '17:00',
      '17:30',
      '18:00',
      '18:30',
      '19:00',
      '19:30',
      '20:00',
      '20:30',
      '21:00',
      '21:30',
    ];

    for (final t in times) {
      if (bookedSlots.contains(t)) {
        result.add(TimeSlotAvailability(time: t, status: 'booked'));
      } else if (busySlots.contains(t)) {
        result.add(TimeSlotAvailability(time: t, status: 'busy'));
      } else {
        result.add(TimeSlotAvailability(time: t, status: 'free'));
      }
    }
    return result;
  }
}
