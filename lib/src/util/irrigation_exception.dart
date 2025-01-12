/// A custom exception class for irrigation-related errors.
class IrrigationException implements Exception {
  /// The underlying exception that caused this error.
  final Object? cause;

  /// Creates an [IrrigationException] with an optional underlying [cause].
  IrrigationException([this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'IrrigationException: $cause';
    }
    return 'IrrigationException';
  }
}
