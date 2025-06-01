import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_logic_state.dart';
import '../logger.dart';
import 'gpio_manager.dart';

class GpioManagerMock implements GpioManager {
  factory GpioManagerMock() {
    _instance ??= GpioManagerMock._();
    return _instance!;
  }

  GpioManagerMock._() {
    qlog(red('Starting in rPI mock mode'));
  }
  static GpioManagerMock? _instance;

  /// Simulated pin states for mock mode
  final Map<int, PinVoltage> _mockPinStates = {};

  @override
  Future<void> provisionPins() async {
    final daoEndPoint = DaoEndPoint();

    for (final pinNo in availablePins) {
      final endPoint = await daoEndPoint.getByPin(pinNo.gpioPin);
      if (endPoint == null) {
        _mockPinStates[pinNo.gpioPin] = PinVoltage.low;
      } else {
        _mockPinStates[pinNo.gpioPin] = endPoint.activationType.offState;
      }
      print('''
Mock provisioned GPIO pin $pinNo with initial state: ${_mockPinStates[pinNo.gpioPin]}''');
    }

    _printPinStates();
  }

  @override
  void shutdown() {
    _mockPinStates.clear();
    print('Mock GPIO Manager shutdown complete.');
  }

  /// Set the state of a GPIO pin.
  @override
  void setEndPointState(
      {required EndPoint endPoint, required PinLogicState pinState}) {
    final pinVoltage = DaoEndPoint().voltageForState(endPoint, pinState);
       print('$endPoint set to $pinState voltage: $pinVoltage');
    setPinVoltage(pinNo: endPoint.gpioPinNo, pinVoltage: pinVoltage);
  }

  @override
  void setPinVoltage({required int pinNo, required PinVoltage pinVoltage}) {
    _mockPinStates[pinNo] = pinVoltage;
    _printPinStates();
  }

  @override
  PinLogicState getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (!_mockPinStates.containsKey(pinNo)) {
      print('Mock error: GPIO pin $pinNo has not been provisioned.');
      return PinLogicState.off;
    }
    final isHigh = _mockPinStates[pinNo]!;
    return PinLogicState.getStatus(endPoint, isHigh: isHigh == PinVoltage.high);
  }

  void _printPinStates() {
    final buffer = StringBuffer();
    _mockPinStates.forEach((pin, pinState) {
      buffer.write('p$pin:${pinState == PinVoltage.high ? 'high' : 'low'} ');
    });
    print(buffer);
  }

  @override
  List<GPIOPinAssignment> get availablePins => GPIOPinAssignment.values;
}
