import 'package:pig_common/pig_common.dart';

/// Represents the status of a GPIO pin.
enum PinLogicStatus {
  on,
  off;

  /// Determines the status of a pin based on its activation type and state.
  static PinLogicStatus getStatus(EndPoint pin, {required bool isHigh}) {
    if (pin.activationType == PinActivationType.lowIsOn) {
      return isHigh ? PinLogicStatus.off : PinLogicStatus.on;
    } else {
      return isHigh ? PinLogicStatus.on : PinLogicStatus.off;
    }
  }
}
