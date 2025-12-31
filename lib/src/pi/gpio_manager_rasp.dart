import 'package:dart_periphery/dart_periphery.dart';
import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_logic_state.dart';
import '../logger.dart';
import 'gpio_manager.dart';

class GpioManagerRaspPi implements GpioManager {
  static GpioManagerRaspPi? _instance;

  /// Map to manage GPIO pin instances
  final Map<int, GPIO> _gpioMap = {};

  factory GpioManagerRaspPi() {
    _instance ??= GpioManagerRaspPi._();
    return _instance!;
  }

  GpioManagerRaspPi._() {
    qlog(red('Starting in rPI mode'));
  }

  /// Ensures that all pins are in an off
  /// state.
  @override
  Future<void> provisionPins() async {
    final daoEndPoint = DaoEndPoint();
    qlog(orange('Found ${availablePins.length} active GPIO pins'));

    for (final pinNo in availablePins) {
      final endPoint = await daoEndPoint.getByPin(pinNo.gpioPin);

      final GPIO pin;
      try {
        pin = _provisionPin(
          pinNo: pinNo.gpioPin,
          activationType: PinActivationType.highIsOn,
        );
      } catch (e) {
        qlog(red('Failed to provision pin ${pinNo.gpioPin}: $e'));
        continue;
      }

      _gpioMap[pinNo.gpioPin] = pin;

      if (endPoint != null) {
        setEndPointState(endPoint: endPoint, pinState: PinLogicState.off);
      }
    }
  }

  /// Initialises the pin, and sets it to off.
  /// throws [GPIOexception] on error.
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
      final gpio = GPIO(pinNo, direction)..write(false);
      return gpio;
    } on GPIOexception catch (e, st) {
      qlog(
          '''Error Setting GPIO pin state $pinNo to off : $e err: ${e.errorCode} msg: ${e.errorMsg}''');
      qlog('StackTrace: $st');
      rethrow;
    }
  }

  @override
  void shutdown() {
    for (final pinNo in _gpioMap.keys) {
      final gpio = _gpioMap[pinNo];
      try {
        _setPinVoltage(pinNo: pinNo, pinVoltage: PinVoltage.low);
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
    if (endPoint.gpioPinNo < 0) {
      return;
    }
    final pinVoltage = DaoEndPoint().voltageForState(endPoint, pinState);
    _setPinVoltage(pinNo: endPoint.gpioPinNo, pinVoltage: pinVoltage);
  }

  @override
  PinLogicState getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (pinNo < 0) {
      return PinLogicState.off;
    }
    if (!_gpioMap.containsKey(pinNo)) {
      qlog('Error: GPIO pin $pinNo has not been provisioned.');
      return PinLogicState.off;
    }
    try {
      final pinVoltage =
          _gpioMap[pinNo]!.read() ? PinVoltage.high : PinVoltage.low;
      return PinLogicState.getStatus(endPoint, pinVoltage: pinVoltage);
    } catch (e) {
      qlog('Error reading GPIO pin $pinNo: $e');
      return PinLogicState.off;
    }
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
    _setPinVoltage(pinNo: pinNo, pinVoltage: activationType.onState);
    await Future<void>.delayed(duration);
    _setPinVoltage(pinNo: pinNo, pinVoltage: activationType.offState);
  }

  @override
  void setPinState({
    required int pinNo,
    required PinActivationType activationType,
    required bool isOn,
  }) {
    if (pinNo < 0) {
      return;
    }
    final pinVoltage = isOn ? activationType.onState : activationType.offState;
    _setPinVoltage(pinNo: pinNo, pinVoltage: pinVoltage);
  }

  @override
  List<GPIOPinAssignment> get availablePins => GPIOPinAssignment.values
      .where((pin) => pin != GPIOPinAssignment.none)
      .toList();

  void _setPinVoltage({required int pinNo, required PinVoltage pinVoltage}) {
    if (pinNo < 0) {
      return;
    }
    if (_gpioMap[pinNo] == null) {
      qlog('Error: Pin $pinNo has not been provisioned');
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
