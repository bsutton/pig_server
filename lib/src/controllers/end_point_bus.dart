import '../database/entity/endpoint.dart';
import 'end_point_change_listener.dart';

/// Singleton class to manage notifications for EndPoint changes.
class EndPointBus {
  /// Private constructor for singleton pattern.
  EndPointBus._internal();
  static final EndPointBus _instance = EndPointBus._internal();

  /// A map of EndPoints to their listeners.
  final Map<EndPoint, List<EndPointChangeListener>> _listenerMap = {};

  /// Access the singleton instance.
  static EndPointBus get instance => _instance;

  /// Add a listener for a specific EndPoint.
  void addListener(EndPoint endPoint, EndPointChangeListener listener) {
    final listeners = _listenerMap[endPoint] ?? [];
    if (listeners.contains(listener)) {
      print('Warning: Listener added twice for EndPoint: $listener');
    } else {
      listeners.add(listener);
      _listenerMap[endPoint] = listeners;
    }
  }

  /// Remove a listener for a specific EndPoint.
  void removeListener(EndPoint endPoint, EndPointChangeListener listener) {
    final listeners = _listenerMap[endPoint];
    if (listeners != null) {
      if (!listeners.remove(listener)) {
        print(
            'Warning: Attempted to remove a non-existent listener: $listener');
      }
    } else {
      print('Warning: Attempted to remove listener when no listeners exist.');
    }
  }

  /// Remove a listener from all EndPoints.
  void removeListenerFromAll(EndPointChangeListener listener) {
    for (final listeners in _listenerMap.values) {
      listeners.remove(listener);
    }
  }

  /// Notify listeners that an EndPoint was turned on.
  void notifyHardOn(EndPoint endPoint) {
    _notifyListeners(endPoint, (listener) => listener.notifyHardOn(endPoint));
  }

  /// Notify listeners that an EndPoint was turned off.
  void notifyHardOff(EndPoint endPoint) {
    _notifyListeners(endPoint, (listener) => listener.notifyHardOff(endPoint));
  }

  /// Notify listeners that a timer for an EndPoint was started.
  void timerStarted(EndPoint endPoint) {
    _notifyListeners(endPoint, (listener) => listener.timerStarted(endPoint));
  }

  /// Notify listeners that a timer for an EndPoint was finished.
  void timerFinished(EndPoint endPoint) {
    _notifyListeners(endPoint, (listener) => listener.timerFinished(endPoint));
  }

  /// Internal helper to notify all listeners for an EndPoint.
  void _notifyListeners(EndPoint endPoint,
      void Function(EndPointChangeListener listener) action) {
    final listeners = _listenerMap[endPoint];
    if (listeners != null) {
      for (final listener in listeners) {
        action(listener);
      }
    }
  }
}
