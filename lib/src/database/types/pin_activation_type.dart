/// Represents the activation type of a GPIO pin.
enum PinActivationType {
  highIsOn(
    label: 'High is On',
    onState: PinState.high,
    offState: PinState.low,
  ),
  lowIsOn(
    label: 'Low is On',
    onState: PinState.low,
    offState: PinState.high,
  );

  const PinActivationType({
    required this.label,
    required this.onState,
    required this.offState,
  });

  /// Human-readable label for the activation type.
  final String label;

  /// The state of the pin when it is considered "on".
  final PinState onState;

  /// The state of the pin when it is considered "off".
  final PinState offState;
}

/// Represents the state of a GPIO pin.
enum PinState {
  high,
  low,
}
