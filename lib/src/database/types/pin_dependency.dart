import 'dart:async';

import '../dao/dao_endpoint.dart';
import '../entity/endpoint.dart';

/// Enum representing the type of dependency between pins.
enum DependencyType {
  leadingDelay,
  lagDelay,
}

/// Represents a pin dependency relationship.
class PinDependency {
  PinDependency({
    required this.primaryPin,
    required this.dependency,
    required this.relatedPins,
    required this.interval,
  });

  /// The primary pin in the dependency relationship.
  final EndPoint primaryPin;

  /// The dependency type: either leading or lagging.
  final DependencyType dependency;

  /// The list of related pins that the primary pin depends on.
  final List<EndPoint> relatedPins;

  /// The duration of the delay in the dependency.
  final Duration interval;

  /// Activates the pins based on the dependency type and interval.
  void setOn() {
    switch (dependency) {
      case DependencyType.lagDelay:
        _lagDelayActivation();
      case DependencyType.leadingDelay:
        _leadingDelayActivation();
    }
  }

  /// Handles activation with a lag delay.
  Future<void> _lagDelayActivation() async {
    DaoEndPoint().hardOn(primaryPin);
    primaryPin.hardOn();
    await Future.delayed(interval);

    for (final pin in relatedPins) {
      pin.hardOn();
    }
  }

  /// Handles activation with a leading delay.
  Future<void> _leadingDelayActivation() async {
    for (final pin in relatedPins) {
      pin.hardOn();
    }

    await Future.delayed(interval);
    primaryPin.hardOn();
  }
}
