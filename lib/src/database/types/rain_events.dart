/// Represents a rain event with the date and amount of rainfall.
class RainEvent {

  /// Creates a [RainEvent] with the specified [date] and [millimeters].
  RainEvent({
    required this.date,
    required this.millimeters,
  });
  /// The date of the rain event.
  final DateTime date;

  /// The amount of rainfall in millimeters.
  final int millimeters;

  /// Converts the [RainEvent] to a string representation.
  @override
  String toString() => 'RainEvent(date: $date, millimeters: $millimeters)';
}
