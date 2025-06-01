import 'package:pig_common/pig_common.dart';

/// Represents the status of a GPIO pin.
enum PinLogicState {
  on,
  off;

  /// Determines the status of a pin based on its activation type and state.
  static PinLogicState getStatus(EndPoint pin,
      {required PinVoltage pinVoltage}) {
    if (pin.activationType == PinActivationType.lowIsOn) {
      return pinVoltage == PinVoltage.high
          ? PinLogicState.off
          : PinLogicState.on;
    } else {
      return pinVoltage == PinVoltage.high
          ? PinLogicState.on
          : PinLogicState.off;
    }
  }
}
