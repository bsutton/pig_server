import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_logic_state.dart';
import '../logger.dart';
import 'gpio_manager.dart';

class GpioManagerMock implements GpioManager {
  static GpioManagerMock? _instance;

  /// Simulated pin states for mock mode
  final Map<int, PinVoltage> _mockPinStates = {};

  factory GpioManagerMock() {
    _instance ??= GpioManagerMock._();
    return _instance!;
  }

  GpioManagerMock._() {
    qlog(red('Starting in rPI mock mode'));
  }

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
      qlog('''
Mock provisioned GPIO pin $pinNo with initial state: ${_mockPinStates[pinNo.gpioPin]}''');
    }

    _qlogPinStates();
  }

  @override
  void shutdown() {
    _mockPinStates.clear();
    qlog('Mock GPIO Manager shutdown complete.');
  }

  /// Set the state of a GPIO pin.
  @override
  void setEndPointState(
      {required EndPoint endPoint, required PinLogicState pinState}) {
    if (endPoint.gpioPinNo < 0) {
      return;
    }
    final pinVoltage = DaoEndPoint().voltageForState(endPoint, pinState);
    qlog('$endPoint set to $pinState voltage: $pinVoltage');
    _setPinVoltage(pinNo: endPoint.gpioPinNo, pinVoltage: pinVoltage);
  }

  void _setPinVoltage({required int pinNo, required PinVoltage pinVoltage}) {
    if (pinNo < 0) {
      return;
    }
    _mockPinStates[pinNo] = pinVoltage;
    _qlogPinStates();
  }

  @override
  PinLogicState getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (pinNo < 0) {
      return PinLogicState.off;
    }
    if (!_mockPinStates.containsKey(pinNo)) {
      qlog('Mock error: GPIO pin $pinNo has not been provisioned.');
      return PinLogicState.off;
    }
    final pinVoltage = _mockPinStates[pinNo]!;
    return PinLogicState.getStatus(endPoint, pinVoltage: pinVoltage);
  }

  @override
  Future<void> pulsePin({
    required int pinNo,
    required PinActivationType activationType,
    required Duration duration,
  }) async {
    if (pinNo < 0) {
      return;
    }
    qlog(
      'Mock pulse pin $pinNo: activation=${activationType.name}, '
      'duration=${duration.inMilliseconds}ms, '
      'on=${activationType.onState.name}, off=${activationType.offState.name}',
    );
    _setPinVoltage(pinNo: pinNo, pinVoltage: activationType.onState);
    await Future<void>.delayed(duration);
    _setPinVoltage(pinNo: pinNo, pinVoltage: activationType.offState);
    qlog('Mock pulse pin $pinNo complete.');
  }

  void _qlogPinStates() {
    final buffer = StringBuffer();
    _mockPinStates.forEach((pin, pinVoltage) {
      buffer.write('p$pin:${pinVoltage.name} ');
    });
    qlog(buffer);
  }

  @override
  List<GPIOPinAssignment> get availablePins =>
      GPIOPinAssignment.values
          .where((pin) => pin != GPIOPinAssignment.none)
          .toList();
}
