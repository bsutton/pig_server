import 'dart:async';

import 'package:pig_common/pig_common.dart';

import '../dao/dao_endpoint.dart';

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
  Future<void> setOn() async {
    switch (dependency) {
      case DependencyType.lagDelay:
        await _lagDelayActivation();
      case DependencyType.leadingDelay:
        await _leadingDelayActivation();
    }
  }

  /// Handles activation with a lag delay.
  Future<void> _lagDelayActivation() async {
    await DaoEndPoint().hardOn(primaryPin);
    await Future.delayed(interval, () {});

    for (final pin in relatedPins) {
      await DaoEndPoint().hardOn(pin);
    }
  }

  /// Handles activation with a leading delay.
  Future<void> _leadingDelayActivation() async {
    for (final pin in relatedPins) {
      await DaoEndPoint().hardOn(pin);
    }

    await Future.delayed(interval, () {});
    await DaoEndPoint().hardOn(primaryPin);
  }
}
