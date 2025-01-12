import 'package:intl/intl.dart';

/// Utility class for formatting dates, times, and durations.
class Formatters {
  /// Formatter for dates (dd/MM/yyyy).
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  /// Formatter for date and time (dd/MM/yyyy hh:mma).
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy hh:mma');

  /// Formats a [DateTime] object to a date string.
  static String formatDate(DateTime? date) =>
      date == null ? '' : dateFormat.format(date);

  /// Formats a [DateTime] object to a date and time string.
  static String formatDateTime(DateTime? dateTime) =>
      dateTime == null ? '' : dateTimeFormat.format(dateTime);

  /// Formats a [Duration] to a string in H:mm or seconds format.
  static String formatDuration(Duration? duration) {
    if (duration == null) return '';

    if (duration.inMilliseconds >= 60000) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds} secs';
    }
  }

  /// Formats a [Duration] using a custom format.
  /// Custom format is simulated using Dart's string manipulation.
  /// Supported format: "H:mm:ss", "H:mm", etc.
  static String formatDurationCustom(Duration? duration,
      {String format = 'H:mm:ss'}) {
    if (duration == null) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    switch (format) {
      case 'H:mm:ss':
        return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      case 'H:mm':
        return '$hours:${minutes.toString().padLeft(2, '0')}';
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }
}
