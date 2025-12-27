/// Represents a watering event with the date, time, and duration of watering.
class WateringEvent {
  /// The date and time the watering occurred.
  final DateTime watered;

  /// The duration of the watering event.
  final Duration duration;

  /// Creates a [WateringEvent] with the specified [watered] date/time and [duration].
  WateringEvent({
    required this.watered,
    required this.duration,
  });

  /// Converts the [WateringEvent] to a string representation.
  @override
  String toString() => '''
WateringEvent(watered: $watered, duration: ${duration.inMinutes} minutes)''';
}
