import '../database/entity/endpoint.dart';

/// Interface to listen for changes to an [EndPoint].
abstract class EndPointChangeListener {
  /// Called when the specified [EndPoint] is turned on.
  void notifyHardOn(EndPoint endPoint);

  /// Called when the specified [EndPoint] is turned off.
  void notifyHardOff(EndPoint endPoint);

  /// Called when a timer starts for the specified [EndPoint].
  void timerStarted(EndPoint endPoint);

  /// Called when a timer finishes for the specified [EndPoint].
  void timerFinished(EndPoint endPoint);
}
