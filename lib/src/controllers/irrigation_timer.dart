// timer.dart

import 'dart:async';

import 'package:pig_common/pig_common.dart';

import '../util/delay.dart';
import 'timer_control.dart';
import 'timer_notification.dart';

/// A controller that manages a timed operation for a [GardenFeature].
class IrrigationTimer {
  IrrigationTimer({
    required this.feature,
    required this.description,
    required this.duration,
    required this.completionAction,
    this.timerNotification,
  });
  final GardenFeature feature;
  final String description;
  final Duration duration;
  final TimerNotification? timerNotification;
  final Future<void> Function(GardenFeature) completionAction;

  DateTime? _startTime;
  Delay<GardenFeature>? _timerFuture;

  /// Starts the timer and schedules the completion action.
  Future<void> start() async {
    _startTime = DateTime.now();

    _timerFuture = Delay<GardenFeature>(
      description: description,
      duration: duration,
      feature: feature,
      callback: (_) async => applyCompletionAction(),
    );
    await _timerFuture!.start();
  }

  /// Called when the timer completes normally.
  FutureOr<void> applyCompletionAction() {
    _timerFuture = null;
    TimerControl.removeTimer(feature);
    return completionAction(feature);
  }

  /// Cancels the timer prematurely. The completion action is not called.
  void cancel() {
    if (_timerFuture != null) {
      _timerFuture!.cancel();
      _timerFuture = null;

      TimerControl.removeTimer(feature);
      timerNotification?.timerFinished(feature);
    }
  }

  /// Checks if the timer is still running.
  bool isTimerRunning() => _timerFuture != null;

  /// Calculates the remaining time before the timer completes.
  Duration timeRemaining() {
    if (_startTime == null) {
      return Duration.zero;
    }
    final expectedEndTime = _startTime!.add(duration);
    final now = DateTime.now();
    if (now.isAfter(expectedEndTime)) {
      return Duration.zero;
    }
    return expectedEndTime.difference(now);
  }
}
