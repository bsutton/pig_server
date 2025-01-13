import 'package:dart_periphery/dart_periphery.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../controllers/end_point_bus.dart';
import '../../pi/gpio_manager.dart';
import '../entity/endpoint.dart';
import '../types/endpoint_type.dart';
import '../types/pin_activation_type.dart';
import '../types/pin_status.dart';
import 'dao.dart';

class DaoEndPoint extends Dao<EndPoint> {
  @override
  String get tableName => 'end_point';

  /// Map to manage GPIO pin instances
  final Map<int, GPIO> _gpioMap = {};

  @override
  EndPoint fromMap(Map<String, dynamic> map) => EndPoint.fromMap(map);

  /// Get all EndPoints, ordered by name
  @override
  Future<List<EndPoint>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'LOWER(end_point_name)',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get all valves
  Future<List<EndPoint>> getAllValves() async =>
      getAllByType(EndPointType.valve);

  /// Get all master valves
  Future<List<EndPoint>> getMasterValves() async =>
      getAllByType(EndPointType.masterValve);

  /// Get all EndPoints by type
  Future<List<EndPoint>> getAllByType(EndPointType type) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'end_point_type = ?',
      whereArgs: [type.name],
      orderBy: 'LOWER(end_point_name)',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get EndPoints by pin number
  Future<List<EndPoint>> getByPin(int pinNo) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'pin_no = ?',
      whereArgs: [pinNo],
      orderBy: 'LOWER(end_point_name)',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Delete a specific EndPoint
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Provision GPIO pins based on the database configuration.
  Future<void> provisionPins() async {
    // Fetch all configured pins from the database.
    final configuredPins = await getAll();

    for (final endPoint in configuredPins) {
      final pinNo = endPoint.pinNo;

      // Determine the initial state based on activation type
      final offState = endPoint.activationType == PinActivationType.highIsOn
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
        // Handle the error appropriately (e.g., log, retry, skip the pin)
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
      return PinStatus.off;
    }

    try {
      final gpio = _gpioMap[pinNo]!;

      // Read the current state of the pin
      final isHigh = gpio.read();
      return PinStatus.getStatus(endPoint, isHigh: isHigh);
    } catch (e) {
      print('Error reading GPIO pin $pinNo: $e');
      return PinStatus.off; // Or throw an exception
    }
  }

  /// Activates a pin associated with an [EndPoint].
  Future<void> hardOn(EndPoint endPoint) async {
    final pinNo = endPoint.pinNo;

    if (endPoint.activationType == PinActivationType.highIsOn) {
      _setPinHigh(pinNo);
    } else {
      _setPinLow(pinNo);
    }
    print('Pin $pinNo for EndPoint: ${endPoint.name} set On.');
  }

  /// Deactivates a pin associated with an [EndPoint].
  Future<void> hardOff(EndPoint endPoint) async {
    final pinNo = endPoint.pinNo;

    if (endPoint.activationType == PinActivationType.highIsOn) {
      _setPinLow(pinNo);
    } else {
      _setPinHigh(pinNo);
    }
    EndPointBus.instance.notifyHardOff(endPoint);
    print('Pin $pinNo for EndPoint: ${endPoint.name} set Off.');
  }

  // Sets a GPIO pin to high.
  void _setPinHigh(int pinNo) {
    if (!_gpioMap.containsKey(pinNo)) {
      print('Error: GPIO pin $pinNo has not been provisioned.');
      return;
    }

    try {
      _gpioMap[pinNo]!.write(true);
    } catch (e) {
      print('Error setting GPIO pin $pinNo to high: $e');
    }
  }

// Sets a GPIO pin to low.
  void _setPinLow(int pinNo) {
    if (!_gpioMap.containsKey(pinNo)) {
      print('Error: GPIO pin $pinNo has not been provisioned.');
      return;
    }

    try {
      _gpioMap[pinNo]!.write(false);
    } catch (e) {
      print('Error setting GPIO pin $pinNo to low: $e');
    }
  }

  Future<void> hardOffById(int valveId) async {
    final valve = await DaoEndPoint().getById(valveId);
    await DaoEndPoint().hardOff(valve!);
  }

  Future<bool> isOnById(int endPointId) async {
    final endPoint = await DaoEndPoint().getById(endPointId);

    return isOn(endPoint!);
  }

  bool isOn(EndPoint endPoint) =>
      GpioManager().getCurrentStatus(endPoint) == PinStatus.on;
}
