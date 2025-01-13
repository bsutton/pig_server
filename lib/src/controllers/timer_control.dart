// timer_control.dart

import 'dart:async';

import '../database/entity/garden_feature.dart';
import 'irrigation_timer.dart';
import 'timer_notification.dart';

/// Manages a list of running [IrrigationTimer] instances 
/// for [GardenFeature] objects.
class TimerControl {
  static final Map<int, IrrigationTimer> _timers = {};

  /// Starts a timer for [feature] with [description], [duration],
  /// and [completionAction]. It removes any existing timer for the 
  /// same [feature] first.
  static Future<void> startTimer(
    GardenFeature feature,
    String description,
    Duration duration,
    Future<void> Function(GardenFeature) completionAction, {
    TimerNotification? timerNotification,
  }) async {
    removeTimer(feature);

    final irrigationTimer = IrrigationTimer(
      feature: feature,
      description: description,
      duration: duration,
      completionAction: completionAction,
      timerNotification: timerNotification,
    );

    _timers[feature.id] = irrigationTimer;
    await irrigationTimer.start();
  }

  /// Removes the timer associated with [feature], if any.
  static void removeTimer(GardenFeature feature) {
    final timer = getTimer(feature);
    if (timer != null) {
      _timers.remove(feature.id);
      timer.cancel();
    }
  }

  /// Retrieves the timer associated with [feature], or null if none exists.
  static IrrigationTimer? getTimer(GardenFeature feature) =>
      _timers[feature.id];

  /// Checks if a timer is running for [feature].
  static bool isTimerRunning(GardenFeature feature) {
    final timer = getTimer(feature);
    return timer?.isTimerRunning() ?? false;
  }

  /// Returns the remaining duration of the timer for [feature],
  /// or [Duration.zero] if no timer is running.
  static Duration timeRemaining(GardenFeature feature) {
    final timer = getTimer(feature);
    return timer?.timeRemaining() ?? Duration.zero;
  }
}
