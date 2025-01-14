import 'package:dart_periphery/dart_periphery.dart';
import 'package:dcli/dcli.dart';
import 'package:pig_common/pig_common.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/types/pin_status.dart';
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

  @override
  Future<void> provisionPins() async {
    final daoEndPoint = DaoEndPoint();
    print(orange('Found ${availablePins.length} active GPIO pins'));

    for (final pinNo in availablePins) {
      final endPoint = (await daoEndPoint.getByPin(pinNo.gpioPin)).firstOrNull;

      if (endPoint == null) {
        setPinState(
            pinNo: pinNo.gpioPin,
            activationType: PinActivationType.lowIsOn,
            turnOn: false);
      } else {
        setEndPointState(endPoint: endPoint, turnOn: false);
      }
    }
  }

  @override
  void shutdown() {
    for (final pinNo in _gpioMap.keys) {
      final gpio = _gpioMap[pinNo];
      try {
        gpio?.setGPIOdirection(GPIOdirection.gpioDirOutLow);
      } catch (e) {
        print('Error setting pin $pinNo to low during shutdown: $e');
      } finally {
        gpio?.dispose();
        print('Closed GPIO pin $pinNo.');
      }
    }
    _gpioMap.clear();
    print('GPIO Manager shutdown complete.');
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
    try {
      GPIOdirection direction;
      if (turnOn) {
        // Determine the initial state based on activation type
        direction = activationType == PinActivationType.highIsOn
            ? GPIOdirection.gpioDirOutHigh
            : GPIOdirection.gpioDirOutLow;
      } else {
        // Determine the initial state based on activation type
        direction = activationType == PinActivationType.highIsOn
            ? GPIOdirection.gpioDirOutLow
            : GPIOdirection.gpioDirOutHigh;
      }

      _setPinDirection(pinNo: pinNo, direction: direction);

      try {
        final gpio = GPIO(pinNo, direction);
        _gpioMap[pinNo] = gpio;
        print('''
Provisioned GPIO pin $pinNo with initial state(off): $direction''');
      } catch (e) {
        print('Error provisioning GPIO pin $pinNo: $e');
      }

      _printPinStates();
    } catch (e) {
      print('Error toggling GPIO pin $pinNo: $e');
    }
  }

  void _setPinDirection(
      {required int pinNo, required GPIOdirection direction}) {
    final gpio = _gpioMap[pinNo];
    if (gpio == null) {
      print('Error: GPIO pin $pinNo has not been provisioned.');
      return;
    }

    gpio.setGPIOdirection(direction);
    _printPinStates();
  }

  @override
  PinStatus getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.gpioPinNo;
    if (!_gpioMap.containsKey(pinNo)) {
      print('Error: GPIO pin $pinNo has not been provisioned.');
      return PinStatus.off;
    }
    try {
      final isHigh = _gpioMap[pinNo]!.read();
      return PinStatus.getStatus(endPoint, isHigh: isHigh);
    } catch (e) {
      print('Error reading GPIO pin $pinNo: $e');
      return PinStatus.off;
    }
  }

  void _printPinStates() {
    final buffer = StringBuffer();
    _gpioMap.forEach((pin, gpio) {
      final isHigh = gpio.read();
      buffer.write('p$pin:${isHigh ? 'on' : 'off'};');
    });
    print(buffer);
  }

  @override
  List<GPIOPinAssignment> get availablePins => GPIOPinAssignment.values;
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
