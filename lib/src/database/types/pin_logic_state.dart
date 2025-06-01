import 'package:pig_common/pig_common.dart';

/// Represents the status of a GPIO pin.
enum PinLogicState {
  on,
  off;

  /// Determines the status of a pin based on its activation type and state.
  static PinLogicState getStatus(EndPoint pin, {required bool isHigh}) {
    if (pin.activationType == PinActivationType.lowIsOn) {
      return isHigh ? PinLogicState.off : PinLogicState.on;
    } else {
      return isHigh ? PinLogicState.on : PinLogicState.off;
    }
  }
}
