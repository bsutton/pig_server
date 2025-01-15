import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_status.dart';
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
  final Map<int, PinState> _mockPinStates = {};

  @override
  Future<void> provisionPins() async {
    final daoEndPoint = DaoEndPoint();

    for (final pinNo in availablePins) {
      final endPoint = await daoEndPoint.getByPin(pinNo.gpioPin);
      if (endPoint == null) {
        _mockPinStates[pinNo.gpioPin] = PinState.low;
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
  void setEndPointState({required EndPoint endPoint, required bool turnOn}) {
    setPinState(
        pinNo: endPoint.gpioPinNo,
        activationType: endPoint.activationType,
        turnOn: turnOn);
  }

  @override
  void setPinState(
      {required int pinNo,
      required PinActivationType activationType,
      required bool turnOn}) {
    _mockPinStates[pinNo] =
        turnOn ? activationType.onState : activationType.offState;
    _printPinStates();
  }

  @override
  PinStatus getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (!_mockPinStates.containsKey(pinNo)) {
      print('Mock error: GPIO pin $pinNo has not been provisioned.');
      return PinStatus.off;
    }
    final isHigh = _mockPinStates[pinNo]!;
    return PinStatus.getStatus(endPoint, isHigh: isHigh == PinState.high);
  }

  void _printPinStates() {
    final buffer = StringBuffer();
    _mockPinStates.forEach((pin, pinState) {
      buffer.write('p$pin:${pinState == PinState.high ? 'high' : 'low'} ');
    });
    print(buffer);
  }

  @override
  List<GPIOPinAssignment> get availablePins => GPIOPinAssignment.values;
}
