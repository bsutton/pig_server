/// A collection of constants used throughout the irrigation system.
class Constants {
  /// Represents the date 1/1/1970.
  static  DateTime date1970 = DateTime(1970);

  /// Represents the datetime 1/1/1970 00:00:00.
  static  DateTime dateTime1970 = DateTime(1970);

  /// Represents a zero-equivalent date (1/1/1970).
  static  DateTime dateZero = date1970;

  /// Represents a zero-equivalent datetime (1/1/1970 00:00:00).
  static  DateTime dateTimeZero = dateTime1970;

  /// Represents a duration of 15 minutes.
  static const Duration fifteenMinutes = Duration(minutes: 15);
}
