import 'package:dart_periphery/dart_periphery.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/entity/endpoint.dart';
import '../database/types/pin_activation_type.dart';
import '../database/types/pin_status.dart';

// Assuming you have these classes/enums defined elsewhere:
// class DaoEndPoint {
//   Future<List<EndPoint>> getAll() { ... }
// }
// class EndPoint {
//   int get pinNo { ... }
//   ActivationType get activationType { ... }
// }
// enum ActivationType {
//   ACTIVE_HIGH, ACTIVE_LOW;
//   PinState get offState { ... }
// }
// enum PinState { HIGH, LOW }

class GpioManager {
  /// Getter to access the single instance
  factory GpioManager() => _instance;

  /// Private constructor for the singleton pattern
  GpioManager._privateConstructor();

  /// The single instance of [GpioManager]
  static final GpioManager _instance = GpioManager._privateConstructor();

  /// Map to manage GPIO pin instances
  final Map<int, GPIO> _gpioMap = {};

  /// Provision GPIO pins based on the database configuration.
  Future<void> provisionPins() async {
    // Fetch all configured pins from the database.
    final daoEndPoint = DaoEndPoint();
    final configuredPins = await daoEndPoint.getAll();

    for (final endPoint in configuredPins) {
      final pinNo = endPoint.pinNo;

      // Determine the initial state based on activation type
      final offState = endPoint.activationType.offState == PinState.high
          ? GPIOdirection.gpioDirOutHigh
          : GPIOdirection.gpioDirOutLow;

      // Open the GPIO pin using dart_periphery
      try {
        final gpio = GPIO(pinNo, offState);

        // Add the provisioned pin to the map
        _gpioMap[pinNo] = gpio;
        print('Provisioned GPIO pin $pinNo with initial state: $offState');
      } catch (e) {
        print('Error provisioning GPIO pin $pinNo: $e');
        // Handle the error appropriately
      }
    }
  }

  /// Release GPIO resources and shut down gracefully.
  void shutdown() {
    print('Shutting down GPIO Manager.');

    // Close all GPIO pins.
    for (final pinNo in _gpioMap.keys) {
      final gpio = _gpioMap[pinNo];
      try {
        // Ensure the pin is set to low before closing.
        gpio?.setGPIOdirection(GPIOdirection.gpioDirOutLow);
        // ignore: avoid_catches_without_on_clauses
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

  /// Get the current status of a GPIO pin.
  PinStatus getCurrentStatus(EndPoint endPoint) {
    final pinNo = endPoint.pinNo;
    // Check if the pin has been provisioned
    if (!_gpioMap.containsKey(pinNo)) {
      print('Error: GPIO pin $pinNo has not been provisioned.');
      return PinStatus
          .off; // Or throw an exception, depending on your error handling strategy
    }

    try {
      final gpio = _gpioMap[pinNo]!;

      // Read the current state of the pin
      final isHigh = gpio.read();
      return PinStatus.getStatus(endPoint, isHigh: isHigh);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      print('Error reading GPIO pin $pinNo: $e');
      return PinStatus.off; // Or throw an exception
    }
  }
}
