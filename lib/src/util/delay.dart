import 'dart:async';

import '../logger.dart';

/// A utility class for handling delays with optional cancellation
/// and callbacks.
class Delay<F> {
  /// The description of the delay.
  final String description;

  /// The duration of the delay.
  final Duration duration;

  /// The feature associated with the delay.
  final F feature;

  /// The callback function to execute after the delay.
  // Keep the contravariant callback private and invoke it through a typed
  // method so the public generic class remains safe.
  // ignore: unsafe_variance
  final Future<void> Function(F) _callback;

  /// A flag to indicate whether the delay has been canceled.
  var _isCancelled = false;

  /// Constructor to initialize the delay.
  Delay({
    required this.description,
    required this.duration,
    required this.feature,
    required Future<void> Function(F) callback,
  }) : _callback = callback;

  Future<void> callback(F feature) => _callback(feature);

  /// Starts the delay and executes the callback after the duration,
  /// unless canceled.
  Future<void> start() async {
    qlog("Delay starting '$description'. Duration: $duration for: $feature");

    try {
      await Future.delayed(duration, () {});
      if (!_isCancelled) {
        qlog("""
Delay completing normally '$description'. Duration: $duration for: $feature""");
        await callback(feature);
      } else {
        qlog(
            "Delay canceled '$description'. Duration: $duration for: $feature");
      }
    } catch (e) {
      qlog("Error during delay '$description': $e");
    }
  }

  /// Cancels the delay, preventing the callback from being executed.
  void cancel() {
    _isCancelled = true;
    qlog("Delay canceled '$description'. Duration: $duration for: $feature");
  }
}
