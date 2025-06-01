import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/types/pin_logic_state.dart';
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

  /// Set the state of a GPIO pin. for the passed [endPoint].
  void setEndPointState(
      {required EndPoint endPoint, required PinLogicState pinState});

  /// Get the current status of a GPIO pin.
  PinLogicState getCurrentStatus(EndPoint endPoint);

  static bool? _isPi;

  /// Detect if running on a Raspberry Pi
  static bool _isRaspberryPi() {
    if (_isPi == null) {
      const cpuInfoFile = '/proc/cpuinfo';
      if (!exists(cpuInfoFile)) {
        return false;
      }
      final cpuInfo = read(cpuInfoFile).toParagraph();
      _isPi = cpuInfo.contains('BCM') || cpuInfo.contains('Raspberry Pi');
    }
    return _isPi!;
  }
}
