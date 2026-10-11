/// Date and time helpers for Lens booking flows, which use Asia/Ho_Chi_Minh.
///
/// Calendar values returned by [today] and [fromInstant] are UTC DateTimes
/// whose fields represent Vietnam wall-clock time. Keep them as calendar
/// values and serialize them with [toApiIso]; do not convert them to local time.
abstract final class VietnamTime {
  static const Duration offset = Duration(hours: 7);
  static const int halfHourMilliseconds = 30 * 60 * 1000;
  static const int offsetMilliseconds = 7 * 60 * 60 * 1000;

  static DateTime now() {
    final vietnam = DateTime.now().toUtc().add(offset);
    return DateTime.utc(
      vietnam.year,
      vietnam.month,
      vietnam.day,
      vietnam.hour,
      vietnam.minute,
      vietnam.second,
      vietnam.millisecond,
      vietnam.microsecond,
    );
  }

  static DateTime today() {
    final current = now();
    return DateTime.utc(current.year, current.month, current.day);
  }

  static DateTime fromInstant(DateTime value) {
    final vietnam = value.toUtc().add(offset);
    return DateTime.utc(
      vietnam.year,
      vietnam.month,
      vietnam.day,
      vietnam.hour,
      vietnam.minute,
      vietnam.second,
      vietnam.millisecond,
      vietnam.microsecond,
    );
  }

  static DateTime parseDateKey(String value) {
    final parts = value.split('-').map(int.parse).toList();
    if (parts.length != 3) throw FormatException('Invalid date key: $value');
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  static int nextHalfHour(int utcMilliseconds) {
    final vietnamMilliseconds = utcMilliseconds + offsetMilliseconds;
    final rounded =
        ((vietnamMilliseconds + halfHourMilliseconds - 1) ~/
            halfHourMilliseconds) *
        halfHourMilliseconds;
    return rounded - offsetMilliseconds;
  }

  /// Serialize a DateTime's calendar fields as Vietnam local time.
  static String toApiIso(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    final date =
        '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}';
    final time = '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
    return '${date}T$time+07:00';
  }
}
