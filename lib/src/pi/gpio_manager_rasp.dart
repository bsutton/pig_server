import 'package:dart_periphery/dart_periphery.dart';
import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_logic_state.dart';
import '../logger.dart';
import 'gpio_manager.dart';

class GpioManagerRaspPi implements GpioManager {
  factory GpioManagerRaspPi() {
    _instance ??= GpioManagerRaspPi._();
    return _instance!;
  }

  GpioManagerRaspPi._() {
    qlog(red('Starting in rPI mode'));
  }
  static GpioManagerRaspPi? _instance;

  /// Map to manage GPIO pin instances
  final Map<int, GPIO> _gpioMap = {};

  /// Ensures that all pins are in an off
  /// state.
  @override
  Future<void> provisionPins() async {
    final daoEndPoint = DaoEndPoint();
    qlog(orange('Found ${availablePins.length} active GPIO pins'));

    for (final pinNo in availablePins) {
      final endPoint = await daoEndPoint.getByPin(pinNo.gpioPin);

      final GPIO pin;
      pin = _provisionPin(
        pinNo: pinNo.gpioPin,
        activationType: PinActivationType.highIsOn,
      );
      if (endPoint != null) {
        setEndPointState(endPoint: endPoint, pinState: PinLogicState.off);
      }
      _gpioMap[pinNo.gpioPin] = pin;
    }
  }

  @override
  void shutdown() {
    for (final pinNo in _gpioMap.keys) {
      final gpio = _gpioMap[pinNo];
      try {
        setPinVoltage(pinNo: pinNo, pinVoltage: PinVoltage.low);
      } catch (e) {
        qlog('Error setting pin $pinNo to low during shutdown: $e');
      } finally {
        gpio?.dispose();
        qlog('Closed GPIO pin $pinNo.');
      }
    }
    _gpioMap.clear();
    qlog('GPIO Manager shutdown complete.');
  }

  /// Set the state of a GPIO pin.
  @override
  void setEndPointState(
      {required EndPoint endPoint, required PinLogicState pinState}) {
    final pinVoltage = DaoEndPoint().voltageForState(endPoint, pinState);
    setPinVoltage(pinNo: endPoint.gpioPinNo, pinVoltage: pinVoltage);
  }

  /// Initialises the pin, and sets it to off.
  GPIO _provisionPin({
    required int pinNo,
    required PinActivationType activationType,
  }) {
    /// we initialise the pin in an off set
    final direction = activationType == PinActivationType.highIsOn
        ? GPIOdirection.gpioDirOutLow
        : GPIOdirection.gpioDirOutHigh;
    try {
      qlog('''Provisioned GPIO pin $pinNo to low (off)''');
      return GPIO(pinNo, direction);
    } on GPIOexception catch (e, st) {
      qlog(
          '''Error Setting GPIO pin state $pinNo to off : $e ${e.errorCode} ${e.errorMsg}''');
      qlog('StackTrace: $st');
      rethrow;
    }
  }

  @override
  PinLogicState getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (!_gpioMap.containsKey(pinNo)) {
      qlog('Error: GPIO pin $pinNo has not been provisioned.');
      return PinLogicState.off;
    }
    try {
      final isHigh = _gpioMap[pinNo]!.read();
      return PinLogicState.getStatus(endPoint, isHigh: isHigh);
    } catch (e) {
      qlog('Error reading GPIO pin $pinNo: $e');
      return PinLogicState.off;
    }
  }

  void _printPinStates() {
    final buffer = StringBuffer();
    _gpioMap.forEach((pin, gpio) {
      final isHigh = gpio.read();
      buffer.write('p$pin:${isHigh ? 'on' : 'off'};');
    });
    qlog(buffer);
  }

  @override
  List<GPIOPinAssignment> get availablePins => GPIOPinAssignment.values;

  @override
  void setPinVoltage({required int pinNo, required PinVoltage pinVoltage}) {
    if (_gpioMap[pinNo] == null) {
      qlog("Error: Pin $pinNo hasn't been provisioned");
    }
    _gpioMap[pinNo]?.write(pinVoltage == PinVoltage.high);
  }
  // header pin numbers
  // const gpioPath = '/sys/class/gpio';

  // if (!exists(gpioPath)) {
  //   throw Exception('GPIO path not found: $gpioPath');
  // }

  // final availablePins = <int>[];
  // for (final entry in find('*', workingDirectory: gpioPath).toList()) {
  //   if (isDirectory(entry)) {
  //     final pinName = basename(entry);
  //     if (pinName.startsWith('gpio')) {
  //       final pinNumber = int.tryParse(pinName.replaceFirst('gpio', ''));
  //       if (pinNumber != null) {
  //         availablePins.add(pinNumber);
  //       }
  //     }
  //   }
  // }
  // return availablePins;
}
