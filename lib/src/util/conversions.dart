import 'package:timezone/timezone.dart' as tz;

/// Provides utility methods for date and time conversions.
class Conversions {
  /// Converts a Unix timestamp (seconds since epoch) to a `DateTime` 
  /// in the system's local timezone.
  /// If `timestamp` is 0, returns `DateTime(1970, 1, 1)`.
  static DateTime toLocalDateTime(int timestamp) {
    if (timestamp == 0) {
      return DateTime(1970);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
        .toLocal();
  }

  /// Converts a Unix timestamp (seconds since epoch) to a `DateTime` 
  /// (date only) in the system's local timezone.
  /// If `timestamp` is 0, returns `DateTime(1970, 1, 1)`.
  static DateTime toLocalDate(int timestamp) {
    final dateTime = toLocalDateTime(timestamp);
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Converts a `DateTime` to a Unix timestamp (seconds since epoch).
  static int toUnixTimestamp(DateTime dateTime) =>
      (dateTime.toUtc().millisecondsSinceEpoch / 1000).round();

  /// Converts a `DateTime` to a `DateTime` with the time set to midnight.
  static DateTime toStartOfDay(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// Converts a `DateTime` to another `DateTime` in the specified timezone.
  static DateTime toTimeZone(DateTime dateTime, String timeZone) {
    final location = tz.getLocation(timeZone);
    final tzDateTime = tz.TZDateTime.from(dateTime, location);
    return tzDateTime;
  }

  /// Converts a `DateTime` to a `DateTime` with UTC timezone.
  static DateTime toUtcDateTime(DateTime dateTime) => dateTime.toUtc();
}
