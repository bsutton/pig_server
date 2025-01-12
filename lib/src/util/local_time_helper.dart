import 'package:intl/intl.dart';

import 'contants.dart';

/// A helper class for handling [DateTime] comparisons, checks, and formatting.
class LocalDateTimeHelper {
  /// Formatter for `DateTime` objects with the pattern `yyyy-MM-dd HH:mm`.
  static final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

  /// Returns the later of two [DateTime] objects.
  /// If either is null, the non-null value is returned.
  static DateTime? max(DateTime? lhs, DateTime? rhs) {
    if (lhs == null) {
      return rhs;
    }
    if (rhs == null) {
      return lhs;
    }
    return lhs.isAfter(rhs) ? lhs : rhs;
  }

  /// Returns the earlier of two [DateTime] objects.
  /// If either is null, the non-null value is returned.
  static DateTime? min(DateTime? lhs, DateTime? rhs) {
    if (lhs == null) {
      return rhs;
    }
    if (rhs == null) {
      return lhs;
    }
    return lhs.isBefore(rhs) ? lhs : rhs;
  }

  /// Checks if the given [dateTime] is null or represents the zero datetime (1/1/1970 00:00:00).
  static bool isEmpty(DateTime? dateTime) =>
      dateTime == null || dateTime == Constants.dateTimeZero;

  /// Formats the given [dateTime] to the pattern `yyyy-MM-dd HH:mm`.
  static String format(DateTime dateTime) => formatter.format(dateTime);
}
