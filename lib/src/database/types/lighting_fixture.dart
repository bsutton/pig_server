import 'transition_rules.dart';

/// Represents a light fixture that can be turned on or off.
class LightingFixture {

  /// Creates a [LightingFixture] with the specified [rules].
  LightingFixture(this.rules);
  /// Transition rules associated with the lighting fixture.
  final TransitionRules rules;
}
