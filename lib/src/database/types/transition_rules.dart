/// Represents the set of rules to be applied when transitioning
/// the state of a device.
///
/// Transition rules are typically used to avoid power or pressure overloads.
class TransitionRules {
  /// Creates a [TransitionRules] instance with optional parameters.
  TransitionRules({
    this.delay = 0,
    this.powerSaving = false,
    this.pressureManagement = false,
  });

  /// Delay in milliseconds before transitioning the state.
  final int delay;

  /// Indicates whether power-saving mode should be applied during transitions.
  final bool powerSaving;

  /// Indicates whether pressure management rules are enforced.
  final bool pressureManagement;

  /// Converts the [TransitionRules] instance to a string representation.
  @override
  String toString() => '''
TransitionRules(delay: $delay, powerSaving: $powerSaving, pressureManagement: $pressureManagement)''';
}
