import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/types/pin_status.dart';
import 'gpio_manager_mock.dart';
import 'gpio_manager_rasp.dart';

abstract class GpioManager {
  /// Factory method to create the correct instance
  factory GpioManager() =>
      _isRaspberryPi() ? GpioManagerRaspPi() : GpioManagerMock();

  List<GPIOPinAssignment> get availablePins;

  /// Provision GPIO pins based on the database configuration.
  Future<void> provisionPins();

  /// Release GPIO resources and shut down gracefully.
  void shutdown();

  /// Set the state of a GPIO pin.
  void setEndPointState({required EndPoint endPoint, required bool turnOn}) {
    setPinState(
        pinNo: endPoint.gpioPinNo,
        activationType: endPoint.activationType,
        turnOn: turnOn);
  }

  /// Set the state of a GPIO pin.
  void setPinState(
      {required int pinNo,
      required PinActivationType activationType,
      required bool turnOn});

  /// Get the current status of a GPIO pin.
  PinStatus getCurrentStatus(EndPoint endPoint);

  /// Detect if running on a Raspberry Pi
  static bool _isRaspberryPi() {
    const cpuInfoFile = '/proc/cpuinfo';
    if (!exists(cpuInfoFile)) {
      return false;
    }
    final cpuInfo = read(cpuInfoFile).toParagraph();
    return cpuInfo.contains('BCM') || cpuInfo.contains('Raspberry Pi');
  }
}
