import 'dart:async';

import '../database/entity/garden_feature.dart';
import 'timer_notification.dart';

/// Timer class to manage delayed actions for a [GardenFeature].
class TimerControl {
  TimerControl({
    required this.feature,
    required this.description,
    required this.duration,
    required this.completionAction,
    this.timerNotification,
  });
  final GardenFeature feature;
  final String description;
  final Duration duration;
  final Future<void> Function(GardenFeature feature) completionAction;
  final TimerNotification? timerNotification;

  DateTime? _startTimer;
  Timer? _timer;

  /// Start the timer.
  void start() {
    print("Starting Timer '$description' for: $feature");
    _startTimer = DateTime.now();

    _timer = Timer(duration, () async {
      await applyCompletionAction();
    });
  }

  /// Apply the completion action when the timer finishes normally.
  Future<void> applyCompletionAction() async {
    _timer = null;
    TimerControl.removeTimer(feature);
    await completionAction(feature);
  }

  /// Cancel the timer prematurely. Does not call the completion action.
  void cancel() {
    if (_timer != null) {
      print("Cancelling Timer '$description' for: $feature");
      _timer?.cancel();
      _timer = null;

      TimerControl.removeTimer(feature);
      timerNotification?.timerFinished(feature);
    }
  }

  /// Check if the timer is currently running.
  bool isTimerRunning() => _timer != null;

  /// Get the remaining time for the timer.
  Duration timeRemaining() {
    if (_startTimer == null) return Duration.zero;
    final expectedEndTime = _startTimer!.add(duration);
    return expectedEndTime.difference(DateTime.now());
  }

  /// Get the description of the timer.
  String getDescription() => description;

  /// Get the associated [GardenFeature].
  GardenFeature getFeature() => feature;
}
