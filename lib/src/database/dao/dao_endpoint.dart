import 'package:sqflite_common/sqlite_api.dart';

import '../../controllers/end_point_bus.dart';
import '../../pi/gpio_manager.dart';
import '../entity/endpoint.dart';
import '../types/endpoint_type.dart';
import '../types/pin_status.dart';
import 'dao.dart';

class DaoEndPoint extends Dao<EndPoint> {
  @override
  String get tableName => 'end_point';

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

  // /// Provision GPIO pins based on the database configuration.
  // Future<void> provisionPins() async {
  //   // Fetch all configured pins from the database.
  //   final configuredPins = await getAll();

  //   for (final endPoint in configuredPins) {
  //     final pinNo = endPoint.pinNo;

  //     // Open the GPIO pin using dart_periphery
  //     try {
  //       // Add the provisioned pin to the map
  //       GpioManager().setEndPointState(endPoint: endPoint, turnOn: false);
  //       print('Provisioned GPIO pin $pinNo with initial state: off');
  //     } catch (e) {
  //       print('Error provisioning GPIO pin $pinNo: $e');
  //       // Handle the error appropriately (e.g., log, retry, skip the pin)
  //     }
  //   }
  // }

  /// Get the current status of a GPIO pin.
  PinStatus getCurrentStatus(EndPoint endPoint) =>
      GpioManager().getCurrentStatus(endPoint);

  /// Activates a pin associated with an [EndPoint].
  Future<void> hardOn(EndPoint endPoint) async {
    final pinNo = endPoint.pinNo;

    GpioManager().setEndPointState(endPoint: endPoint, turnOn: true);

    print('Pin $pinNo for EndPoint: ${endPoint.name} set On.');
  }

  /// Deactivates a pin associated with an [EndPoint].
  Future<void> hardOff(EndPoint endPoint) async {
    final pinNo = endPoint.pinNo;

    GpioManager().setEndPointState(endPoint: endPoint, turnOn: false);

    EndPointBus.instance.notifyHardOff(endPoint);
    print('Pin $pinNo for EndPoint: ${endPoint.name} set Off.');
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
