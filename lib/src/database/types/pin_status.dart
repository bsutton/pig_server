import 'package:pig_common/pig_common.dart';

/// Represents the status of a GPIO pin.
enum PinStatus {
  on,
  off;

  /// Determines the status of a pin based on its activation type and state.
  static PinStatus getStatus(EndPoint pin, {required bool isHigh}) {
    if (pin.activationType == PinActivationType.lowIsOn) {
      return isHigh ? PinStatus.off : PinStatus.on;
    } else {
      return isHigh ? PinStatus.on : PinStatus.off;
    }
  }
}
