import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pig_common/pig_common.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../util/delay.dart';

/// A controller for managing timers and notifying WebSocket clients.
class TimerControl {
  /// Factory to create instances of TimerControl.
  factory TimerControl() => _instance ??= TimerControl._internal();

  TimerControl._internal();

  static TimerControl? _instance;

  /// Holds active timers, keyed by the [GardenFeature.id].
  final Map<int, FeatureTimer> _timers = {};

  /// Collection of listening WebSocket clients for real-time updates.
  final List<WebSocketSink> _listening = [];

  /// Start a timer for [feature] with [description] and [duration].
  /// [completionAction] is called when the timer completes normally.
  Future<void> startTimer(
    GardenFeature feature,
    String description,
    Duration duration,
    Future<void> Function(GardenFeature) completionAction,
  ) async {
    stopTimer(feature); // remove any existing timer first

    final entry = FeatureTimer(
      feature: feature,
      description: description,
      duration: duration,
      completionAction: (feature) {
        stopTimer(feature);
        completionAction(feature);
      },
    );
    _timers[feature.id] = entry;
    entry.start();

    _notify(Notice(
      noticeType: NoticeType.start,
      featureType: FeatureType.fromFeature(feature),
      featureId: feature.id,
      description: description,
    ));
  }

  /// Stop the timer associated with [feature], if any.
  void stopTimer(GardenFeature feature) {
    final timer = _timers.remove(feature.id);
    if (timer != null) {
      timer.cancel();
      _notify(Notice(
        noticeType: NoticeType.stop,
        featureId: feature.id,
        featureType: FeatureType.fromFeature(feature),
        description: timer.description,
      ));
    }
  }

  /// Returns the remaining duration of the timer for [feature].
  /// If no timer is running, returns [Duration.zero].
  Duration timeRemaining(GardenFeature feature) {
    final timer = getTimer(feature);
    return timer?.timeRemaining() ?? Duration.zero;
  }

  /// Check if a timer is currently running for [feature].
  bool isTimerRunning(GardenFeature feature) =>
      getTimer(feature)?.isTimerRunning() ?? false;

  FeatureTimer? getTimer(GardenFeature feature) => _timers[feature.id];

  /// Attach a [WebSocket] to receive notifications when timers
  /// start, stop, or complete.
  void monitor(WebSocketSink socket) {
    print('Adding monitor socket');
    _listening.add(socket);
  }

  /// Remove a [WebSocket] from the notification list.
  void stopMonitor(WebSocketSink socket) {
    print('Removing monitor socket');
    _listening.remove(socket);
  }

  /// Notify all listening sockets of the [notice].
  void _notify(Notice notice) {
    final message = jsonEncode(notice.toJson());
    for (final socket in _listening) {
      socket.add(message);
    }
  }
}

class FeatureTimer {
  FeatureTimer({
    required this.feature,
    required this.description,
    required this.duration,
    required this.completionAction,
  }) : startTime = DateTime.now();

  final GardenFeature feature;
  final String description;
  final Duration duration;
  final DateTime startTime;
  final void Function(GardenFeature) completionAction;

  Delay<GardenFeature>? _delay;

  /// Starts the timer and schedules [completionAction].
  void start() {
    final delay = Delay<GardenFeature>(
      description: description,
      duration: duration,
      feature: feature,
      callback: (_) async {
        cancel();
        return completionAction(feature);
      },
    );

    unawaited(delay.start());
  }

  /// Cancels the timer if running.
  void cancel() {
    _delay?.cancel();
    _delay = null;
  }

  /// Returns true if the timer is still running.
  bool isTimerRunning() => _delay != null;

  /// Remaining time until the timer completes.
  Duration timeRemaining() {
    final expectedEndTime = startTime.add(duration);
    final now = DateTime.now();
    if (now.isAfter(expectedEndTime)) {
      return Duration.zero;
    }
    return expectedEndTime.difference(now);
  }
}
