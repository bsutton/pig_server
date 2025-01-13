import 'dart:async';

/// A utility class for handling delays with optional cancellation
/// and callbacks.
class Delay<F> {
  /// Constructor to initialize the delay.
  Delay({
    required this.description,
    required this.duration,
    required this.feature,
    required this.callback,
  });

  /// The description of the delay.
  final String description;

  /// The duration of the delay.
  final Duration duration;

  /// The feature associated with the delay.
  final F feature;

  /// The callback function to execute after the delay.
  final Future<void> Function(F) callback;

  /// A flag to indicate whether the delay has been canceled.
  bool _isCancelled = false;

  /// Starts the delay and executes the callback after the duration,
  /// unless canceled.
  Future<void> start() async {
    print("Delay starting '$description'. Duration: $duration for: $feature");

    try {
      await Future.delayed(duration, () {});
      if (!_isCancelled) {
        print("""
Delay completing normally '$description'. Duration: $duration for: $feature""");
        await callback(feature);
      } else {
        print(
            "Delay canceled '$description'. Duration: $duration for: $feature");
      }
    } catch (e) {
      print("Error during delay '$description': $e");
    }
  }

  /// Cancels the delay, preventing the callback from being executed.
  void cancel() {
    _isCancelled = true;
    print("Delay canceled '$description'. Duration: $duration for: $feature");
  }
}
